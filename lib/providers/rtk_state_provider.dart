import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:path_provider/path_provider.dart';

import '../core/constants/vn2000_provinces.dart';
import '../core/geodetic/coordinate_models.dart';
import '../core/geodetic/vn2000_engine.dart';
import '../core/gnss/gnss_commands.dart';
import '../core/gnss/nmea_parser.dart';
import '../core/gnss/rinex_logger.dart';
import '../core/bluetooth/bluetooth_manager.dart';
import '../core/network/ntrip_client.dart';
import '../core/network/ntrip_server.dart';

enum OperatingMode { rover, base, staticSurvey }

/// Điểm đo trắc địa đã lưu
class SurveyPoint {
  final int id;
  final String code;        // Mã điểm (vd: GT)
  final String name;        // Tên điểm (vd: Đo 0)
  final double poleHeight;  // Cao sào (m)
  final double wgsLat;
  final double wgsLon;
  final double wgsHeight;
  final double vnX;
  final double vnY;
  final double vnH;
  final String solution;
  final double hAcc;
  final DateTime timestamp;

  SurveyPoint({
    required this.id,
    required this.code,
    required this.name,
    required this.poleHeight,
    required this.wgsLat,
    required this.wgsLon,
    required this.wgsHeight,
    required this.vnX,
    required this.vnY,
    required this.vnH,
    required this.solution,
    required this.hAcc,
    required this.timestamp,
  });
}

/// Provider Trung Tâm: Quản lý toàn bộ Trạng Thái Hệ Thống RTK
class RtkStateProvider extends ChangeNotifier {
  final BluetoothManager bluetoothManager = BluetoothManager();
  final NmeaParser nmeaParser = NmeaParser();

  NtripClient? _ntripClient;
  NtripServer? _ntripServer;
  RinexStaticSession? _staticSession;

  StreamSubscription? _nmeaSub;
  StreamSubscription? _rawSub;
  StreamSubscription? _rtcmPullSub;

  // Cấu hình hoạt động
  OperatingMode _mode = OperatingMode.rover;
  GnssChipset _chipset = GnssChipset.unicoreUM980;
  double _apcOffset = 0.0485; // Bù trừ tâm pha ăng-ten 4.85cm
  double _poleHeight = 2.000;  // Chiều cao sào đo 2m

  // Cấu hình hệ tọa độ mặc định (Hà Nội, KTT 105°00', múi 3°)
  ProvinceKTT _selectedProvince = VN2000Provinces.provinces[23];
  int _selectedZone = 3;

  // Trạng thái định vị hiện tại
  GnssPositionData _currentPosition = GnssPositionData();
  VN2000Coord? _currentVn2000;

  // Danh sách điểm đo & Log console
  final List<SurveyPoint> _surveyPoints = [];
  final List<String> _consoleLogs = [];

  OperatingMode get mode => _mode;
  GnssChipset get chipset => _chipset;
  double get apcOffset => _apcOffset;
  double get poleHeight => _poleHeight;
  ProvinceKTT get selectedProvince => _selectedProvince;
  int get selectedZone => _selectedZone;
  GnssPositionData get currentPosition => _currentPosition;
  VN2000Coord? get currentVn2000 => _currentVn2000;
  List<SurveyPoint> get surveyPoints => List.unmodifiable(_surveyPoints);
  List<String> get consoleLogs => List.unmodifiable(_consoleLogs);
  RinexStaticSession? get staticSession => _staticSession;

  bool get isBluetoothConnected => bluetoothManager.state == BluetoothConnState.connected;
  bool get isCasterConnected => (_mode == OperatingMode.rover)
      ? (_ntripClient?.state == NtripClientState.connected)
      : (_ntripServer?.state == NtripServerState.broadcasting);

  RtkStateProvider() {
    _initListeners();
  }

  void _initListeners() {
    // Lắng nghe dòng NMEA phân tích thời gian thực
    _nmeaSub = bluetoothManager.nmeaLineStream.listen((line) {
      GnssPositionData? data = nmeaParser.parseSentence(line);
      if (data != null) {
        _currentPosition = data;

        // Tự động tính chuyển sang VN-2000 ngay khi có tọa độ hợp lệ
        if (data.latitude != 0.0 && data.longitude != 0.0) {
          _currentVn2000 = VN2000Engine.wgs84ToVn2000(
            data.latitude,
            data.longitude,
            data.altitude - _poleHeight - _apcOffset, // Bù trừ cao sào và tâm pha
            _selectedProvince.kttDegree,
            _selectedZone,
          );
        }
        notifyListeners();
      }
    });

    // Lắng nghe dòng byte thô
    _rawSub = bluetoothManager.rawStream.listen((chunk) {
      if (_mode == OperatingMode.base && _ntripServer != null) {
        _ntripServer!.pushRtcmChunk(chunk);
      } else if (_mode == OperatingMode.staticSurvey && _staticSession != null) {
        _staticSession!.recordRawChunk(chunk);
        notifyListeners();
      }
    });

    // Lắng nghe trạng thái Bluetooth
    bluetoothManager.onStatusChanged = (state, msg) {
      addLog(msg);
      notifyListeners();
    };
  }

  void addLog(String message) {
    String now = DateTime.now().toIso8601String().substring(11, 19);
    _consoleLogs.insert(0, "$now - $message");
    if (_consoleLogs.length > 100) _consoleLogs.removeLast();
    notifyListeners();
  }

  void setChipset(GnssChipset chip) {
    _chipset = chip;
    notifyListeners();
  }

  void setApcOffset(double offset) {
    _apcOffset = offset;
    notifyListeners();
  }

  void setPoleHeight(double h) {
    _poleHeight = h;
    notifyListeners();
  }

  void setVn2000Province(ProvinceKTT prov, int zone) {
    _selectedProvince = prov;
    _selectedZone = zone;
    notifyListeners();
  }

  /// 1. CHỨC NĂNG CHUYỂN NHANH: Sang Chế Độ ROVER (NTRIP Client)
  Future<void> switchToRoverMode({
    required String host,
    required int port,
    required String mountpoint,
    String user = "",
    String pass = "",
  }) async {
    addLog("Bắt đầu chuyển sang chế độ Đo Động (Rover)...");
    _mode = OperatingMode.rover;

    // Dừng trạm Base hoặc Đo tĩnh nếu đang chạy
    _ntripServer?.stopBroadcasting();
    _ntripServer = null;
    _staticSession?.stop();
    _staticSession = null;

    // Gửi lệnh cấu hình Rover xuống đầu thu GNSS
    List<String> cmds = GnssCommands.getRoverCommands(_chipset);
    await bluetoothManager.sendCommandList(cmds);
    addLog("Đã thiết lập chế độ Rover cho đầu thu GNSS");

    // Khởi tạo NTRIP Client kéo RTCM
    _ntripClient?.disconnect();
    _ntripClient = NtripClient(
      host: host,
      port: port,
      mountpoint: mountpoint,
      username: user,
      password: pass,
    );

    _ntripClient!.onStatusChanged = (st, msg) {
      addLog(msg);
      notifyListeners();
    };

    bool ok = await _ntripClient!.connect();
    if (ok) {
      // Đẩy luồng RTCM từ Caster vào cổng Bluetooth của đầu thu
      _rtcmPullSub?.cancel();
      _rtcmPullSub = _ntripClient!.rtcmStream.listen((rtcmBytes) {
        bluetoothManager.sendRawBytes(rtcmBytes);
      });

      // Bật tự động gửi GGA cập nhật vị trí lên Caster
      _ntripClient!.startGgaPeriodicReporting(() {
        if (_currentPosition.latitude != 0.0) {
          return "\$GNGGA,${_currentPosition.timestamp},...,*00";
        }
        return "";
      });
    }

    notifyListeners();
  }

  /// 2. CHỨC NĂNG CHUYỂN NHANH: Sang Chế Độ BASE (NTRIP Server Broadcaster)
  Future<void> switchToBaseMode({
    required String host,
    required int port,
    required String mountpoint,
    required String password,
    bool isSurveyIn = true,
    double? fixedLat,
    double? fixedLon,
    double? fixedAlt,
  }) async {
    addLog("Bắt đầu chuyển sang chế độ Trạm Phát (Base)...");
    _mode = OperatingMode.base;

    // Ngắt NTRIP Client và Đo tĩnh
    _rtcmPullSub?.cancel();
    _ntripClient?.disconnect();
    _ntripClient = null;
    _staticSession?.stop();
    _staticSession = null;

    // Gửi lệnh cấu hình Base xuống đầu thu GNSS
    List<String> cmds = isSurveyIn
        ? GnssCommands.getBaseSurveyInCommands(chipset: _chipset, durationSec: 60)
        : GnssCommands.getBaseFixedCommands(chipset: _chipset, lat: fixedLat ?? 0.0, lon: fixedLon ?? 0.0, alt: fixedAlt ?? 0.0);

    await bluetoothManager.sendCommandList(cmds);
    addLog("Đã cấu hình đầu thu GNSS sang chế độ phát Base RTCM 3.x");

    // Khởi tạo NTRIP Server để đẩy Mountpoint lên Caster
    _ntripServer?.stopBroadcasting();
    _ntripServer = NtripServer(
      host: host,
      port: port,
      mountpoint: mountpoint,
      password: password,
    );

    _ntripServer!.onStatusChanged = (st, msg) {
      addLog(msg);
      notifyListeners();
    };

    await _ntripServer!.startBroadcasting();
    notifyListeners();
  }

  /// 3. CHỨC NĂNG CHUYỂN NHANH: Sang Chế Độ Đo GNSS Tĩnh (RINEX 2.11)
  Future<void> startStaticSurvey({
    required String pointName,
    required String observer,
    required double antennaHeight,
    int epochIntervalSec = 1,
  }) async {
    addLog("Bắt đầu thiết lập chế độ Đo Tĩnh và lưu file RINEX 2.11...");
    _mode = OperatingMode.staticSurvey;

    _ntripClient?.disconnect();
    _ntripServer?.stopBroadcasting();

    // Gửi lệnh bật ghi dữ liệu thô
    List<String> cmds = GnssCommands.getStaticSurveyCommands(chipset: _chipset, epochRateSec: epochIntervalSec);
    await bluetoothManager.sendCommandList(cmds);
    addLog("Đã thiết lập xong Cấu hình Đo tĩnh cho đầu thu GNSS và đang bắt đầu đo Tĩnh");

    var dir = await getExternalStorageDirectory();
    String targetDir = "${dir?.path ?? '/sdcard/Download'}/RTKFieldRINEX";

    _staticSession = RinexStaticSession(
      pointName: pointName,
      observerName: observer,
      antennaHeight: antennaHeight,
      epochIntervalSec: epochIntervalSec,
      startTime: DateTime.now(),
    );

    String path = await _staticSession!.start(targetDir);
    addLog("Đang ghi dữ liệu vào tệp: $path");
    notifyListeners();
  }

  /// Dừng đo tĩnh và quay lại Rover
  Future<void> stopStaticSurvey({required String defaultHost, required int defaultPort, required String defaultMount}) async {
    if (_staticSession != null) {
      String? savedPath = await _staticSession!.stop();
      addLog("Đã đo xong, Đợi ghi dữ liệu RINEX vào thư mục: $savedPath");
      _staticSession = null;
    }
    // Trở lại Rover
    await switchToRoverMode(host: defaultHost, port: defaultPort, mountpoint: defaultMount);
  }

  /// Lưu điểm đo thực địa hiện tại
  void recordCurrentPoint({required String code, required String name}) {
    if (_currentPosition.latitude == 0.0 || _currentVn2000 == null) return;

    SurveyPoint p = SurveyPoint(
      id: _surveyPoints.length + 1,
      code: code,
      name: name,
      poleHeight: _poleHeight,
      wgsLat: _currentPosition.latitude,
      wgsLon: _currentPosition.longitude,
      wgsHeight: _currentPosition.altitude,
      vnX: _currentVn2000!.x,
      vnY: _currentVn2000!.y,
      vnH: _currentVn2000!.height,
      solution: _currentPosition.solutionText,
      hAcc: _currentPosition.estimatedHorizontalAccuracy,
      timestamp: DateTime.now(),
    );

    _surveyPoints.add(p);
    addLog("Đã lưu điểm đo #${p.id} [$name - $code]: X=${p.vnX.toStringAsFixed(3)}, Y=${p.vnY.toStringAsFixed(3)}");
    notifyListeners();
  }

  @override
  void dispose() {
    _nmeaSub?.cancel();
    _rawSub?.cancel();
    _rtcmPullSub?.cancel();
    _ntripClient?.disconnect();
    _ntripServer?.stopBroadcasting();
    _staticSession?.stop();
    bluetoothManager.disconnect();
    super.dispose();
  }
}
