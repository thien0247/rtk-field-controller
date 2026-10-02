import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

enum BluetoothConnState { disconnected, scanning, connecting, connected, error }

/// Bộ quản lý kết nối Bluetooth SPP (RFCOMM) với đầu thu GNSS RTK
class BluetoothManager {
  BluetoothConnection? _connection;
  BluetoothDevice? _connectedDevice;
  BluetoothConnState _state = BluetoothConnState.disconnected;

  // Stream dòng byte nhận từ Bluetooth
  final StreamController<Uint8List> _rawStreamController = StreamController<Uint8List>.broadcast();
  Stream<Uint8List> get rawStream => _rawStreamController.stream;

  // Stream các dòng văn bản ASCII NMEA
  final StreamController<String> _nmeaLineController = StreamController<String>.broadcast();
  Stream<String> get nmeaLineStream => _nmeaLineController.stream;

  // Callback thông báo trạng thái
  Function(BluetoothConnState state, String message)? onStatusChanged;
  Function(int totalBytesReceived)? onBytesReceived;

  int _bytesCount = 0;
  final List<int> _lineBuffer = [];

  BluetoothConnState get state => _state;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  int get bytesCount => _bytesCount;

  /// Lấy danh sách các thiết bị Bluetooth đã ghép nối (Paired Devices)
  Future<List<BluetoothDevice>> getBondedDevices() async {
    try {
      return await FlutterBluetoothSerial.instance.getBondedDevices();
    } catch (e) {
      return [];
    }
  }

  /// Bắt đầu kết nối tới thiết bị qua địa chỉ MAC
  Future<bool> connect(BluetoothDevice device) async {
    _setState(BluetoothConnState.connecting, "Đang kết nối tới ${device.name} (${device.address})...");
    try {
      _connection = await BluetoothConnection.toAddress(device.address);
      _connectedDevice = device;
      _bytesCount = 0;
      _lineBuffer.clear();

      _setState(BluetoothConnState.connected, "Đã kết nối Bluetooth thành công: ${device.name ?? device.address}");

      // Lắng nghe dữ liệu đến từ đầu thu
      _connection!.input!.listen(
        (Uint8List data) {
          _bytesCount += data.length;
          onBytesReceived?.call(_bytesCount);

          // Phát toàn bộ mảng byte thô (phục vụ Base Server và Đo Tĩnh)
          _rawStreamController.add(data);

          // Tách dòng NMEA
          for (int b in data) {
            if (b == 0x0A) { // Ký tự \n
              if (_lineBuffer.isNotEmpty) {
                try {
                  String line = utf8.decode(_lineBuffer, allowMalformed: true).trim();
                  if (line.startsWith('\$')) {
                    _nmeaLineController.add(line);
                  }
                } catch (_) {}
                _lineBuffer.clear();
              }
            } else if (b != 0x0D) { // Bỏ qua \r
              _lineBuffer.add(b);
              // Tránh tràn bộ đệm nếu nhận luồng nhị phân RTCM thuần
              if (_lineBuffer.length > 2048) {
                _lineBuffer.clear();
              }
            }
          }
        },
        onError: (e) {
          _setState(BluetoothConnState.error, "Lỗi mất kết nối Bluetooth: $e");
          disconnect();
        },
        onDone: () {
          _setState(BluetoothConnState.disconnected, "Đầu thu đã đóng kết nối Bluetooth");
          disconnect();
        },
      );

      return true;
    } catch (e) {
      _setState(BluetoothConnState.error, "Không thể kết nối tới đầu thu: $e");
      disconnect();
      return false;
    }
  }

  /// Gửi lệnh ASCII hoặc Hex cấu hình xuống đầu thu
  Future<bool> sendCommand(String cmd) async {
    if (_connection != null && _connection!.isConnected) {
      try {
        _connection!.output.add(utf8.encode(cmd));
        await _connection!.output.allSent;
        return true;
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  /// Gửi danh sách nhiều lệnh tuần tự
  Future<void> sendCommandList(List<String> commands, {int delayMs = 100}) async {
    for (String cmd in commands) {
      await sendCommand(cmd);
      if (delayMs > 0) {
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }
  }

  /// Gửi byte nhị phân (RTCM từ NTRIP Client) xuống đầu thu
  void sendRawBytes(Uint8List bytes) {
    if (_connection != null && _connection!.isConnected) {
      try {
        _connection!.output.add(bytes);
      } catch (_) {}
    }
  }

  /// Ngắt kết nối
  void disconnect() {
    _connection?.dispose();
    _connection = null;
    _connectedDevice = null;
    _setState(BluetoothConnState.disconnected, "Đã ngắt kết nối Bluetooth");
  }

  void _setState(BluetoothConnState st, String msg) {
    _state = st;
    onStatusChanged?.call(st, msg);
  }
}
