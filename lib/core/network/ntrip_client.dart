import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

enum NtripClientState { disconnected, connecting, connected, error }

/// Bộ xử lý NTRIP Client: Kéo dữ liệu hiệu chỉnh RTCM từ Caster về nạp cho đầu thu Rover
class NtripClient {
  final String host;
  final int port;
  final String mountpoint;
  final String username;
  final String password;

  Socket? _socket;
  StreamSubscription? _socketSubscription;
  Timer? _ggaTimer;
  NtripClientState _state = NtripClientState.disconnected;

  // Stream phát dữ liệu RTCM nhận được về cho Bluetooth
  final StreamController<Uint8List> _rtcmController = StreamController<Uint8List>.broadcast();
  Stream<Uint8List> get rtcmStream => _rtcmController.stream;

  // Callback báo trạng thái
  Function(NtripClientState state, String message)? onStatusChanged;

  NtripClient({
    required this.host,
    required this.port,
    required this.mountpoint,
    this.username = "",
    this.password = "",
  });

  NtripClientState get state => _state;

  /// Kết nối tới NTRIP Caster
  Future<bool> connect({String? initialGga}) async {
    _setState(NtripClientState.connecting, "Đang kết nối tới Caster $host:$port/$mountpoint...");
    try {
      _socket = await Socket.connect(host, port, timeout: const Duration(seconds: 10));

      // Tạo chuỗi chứng thực Basic Auth
      String authHeader = "";
      if (username.isNotEmpty) {
        String creds = base64Encode(utf8.encode("$username:$password"));
        authHeader = "Authorization: Basic $creds\r\n";
      }

      // Gửi yêu cầu HTTP GET NTRIP
      String request = "GET /$mountpoint HTTP/1.0\r\n"
          "User-Agent: NTRIP RTKFieldApp/1.0\r\n"
          "Accept: */*\r\n"
          "Connection: close\r\n"
          "$authHeader"
          "\r\n";

      _socket!.write(request);
      await _socket!.flush();

      // Nếu có sẵn tọa độ GGA ban đầu thì gửi ngay
      if (initialGga != null && initialGga.isNotEmpty) {
        _socket!.write("$initialGga\r\n");
        await _socket!.flush();
      }

      bool isHeaderParsed = false;
      List<int> headerBuffer = [];

      _socketSubscription = _socket!.listen(
        (data) {
          if (!isHeaderParsed) {
            headerBuffer.addAll(data);
            String headerStr = String.fromCharCodes(headerBuffer);

            // Kiểm tra phân tách header \r\n\r\n
            int splitIndex = headerStr.indexOf("\r\n\r\n");
            if (splitIndex != -1) {
              isHeaderParsed = true;
              String statusLine = headerStr.split("\r\n").first;

              if (statusLine.contains("200") || statusLine.contains("ICY 200 OK")) {
                _setState(NtripClientState.connected, "Đã kết nối thành công Mountpoint: $mountpoint");
                // Đẩy phần data RTCM còn lại sau header (nếu có)
                List<int> remainingData = headerBuffer.sublist(splitIndex + 4);
                if (remainingData.isNotEmpty) {
                  _rtcmController.add(Uint8List.fromList(remainingData));
                }
              } else {
                _setState(NtripClientState.error, "Lỗi từ chối kết nối Caster: $statusLine");
                disconnect();
              }
            }
          } else {
            // Đã vượt qua bước Handshake, toàn bộ byte đến là RTCM 3.x
            _rtcmController.add(Uint8List.fromList(data));
          }
        },
        onError: (e) {
          _setState(NtripClientState.error, "Lỗi luồng mạng: $e");
          disconnect();
        },
        onDone: () {
          _setState(NtripClientState.disconnected, "Máy chủ Caster đã ngắt kết nối");
          disconnect();
        },
      );

      return true;
    } catch (e) {
      _setState(NtripClientState.error, "Không thể kết nối Caster: $e");
      disconnect();
      return false;
    }
  }

  /// Bắt đầu gửi câu GGA định kỳ (cho mạng VRS - Virtual Reference Station)
  void startGgaPeriodicReporting(String Function() getLatestGga, {int intervalSec = 10}) {
    _ggaTimer?.cancel();
    _ggaTimer = Timer.periodic(Duration(seconds: intervalSec), (timer) {
      if (_socket != null && _state == NtripClientState.connected) {
        String gga = getLatestGga();
        if (gga.isNotEmpty) {
          try {
            _socket!.write("$gga\r\n");
            _socket!.flush();
          } catch (_) {}
        }
      }
    });
  }

  /// Ngắt kết nối
  void disconnect() {
    _ggaTimer?.cancel();
    _ggaTimer = null;
    _socketSubscription?.cancel();
    _socketSubscription = null;
    _socket?.destroy();
    _socket = null;
    _setState(NtripClientState.disconnected, "Đã ngắt kết nối NTRIP");
  }

  void _setState(NtripClientState st, String msg) {
    _state = st;
    onStatusChanged?.call(st, msg);
  }
}
