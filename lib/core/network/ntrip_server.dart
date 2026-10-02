import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

enum NtripServerState { disconnected, connecting, broadcasting, error }

/// Bộ xử lý NTRIP Server / Source: Đẩy luồng RTCM từ đầu thu Base lên Caster để phát sóng
class NtripServer {
  final String host;
  final int port;
  final String mountpoint;
  final String password;
  final String username;

  Socket? _socket;
  StreamSubscription? _socketSubscription;
  NtripServerState _state = NtripServerState.disconnected;

  int _bytesUploaded = 0;
  DateTime? _broadcastStartTime;

  int get bytesUploaded => _bytesUploaded;
  Duration get broadcastDuration => _broadcastStartTime != null ? DateTime.now().difference(_broadcastStartTime!) : Duration.zero;
  NtripServerState get state => _state;

  Function(NtripServerState state, String message)? onStatusChanged;
  Function(int totalBytes)? onBytesStreamed;

  NtripServer({
    required this.host,
    required this.port,
    required this.mountpoint,
    required this.password,
    this.username = "",
  });

  /// Bắt đầu phát Base lên Caster
  Future<bool> startBroadcasting({
    String country = "VNM",
    String carrier = "2", // Multi-frequency L1/L2/L5
    String navSystem = "GPS+GLO+GAL+BDS",
  }) async {
    _setState(NtripServerState.connecting, "Đang kết nối để khởi tạo Trạm Base trên Caster...");
    _bytesUploaded = 0;

    try {
      _socket = await Socket.connect(host, port, timeout: const Duration(seconds: 10));

      // Sử dụng giao thức NTRIP 1.0 SOURCE chuẩn (được 100% Caster hỗ trợ: BKG, SNIP, 2RTK, Emlid)
      String sourceHeader = "SOURCE $password /$mountpoint\r\n"
          "Source-Agent: NTRIP RTKMobileBase/1.0\r\n"
          "STR: STR;$mountpoint;$mountpoint;RTCM 3.2;$navSystem;$carrier;2;VN;0.00;0.00;0;0;Mobile;none;N;N;0;none\r\n"
          "\r\n";

      _socket!.write(sourceHeader);
      await _socket!.flush();

      Completer<bool> handshakeCompleter = Completer();
      List<int> responseBuffer = [];

      _socketSubscription = _socket!.listen(
        (data) {
          if (!handshakeCompleter.isCompleted) {
            responseBuffer.addAll(data);
            String responseStr = String.fromCharCodes(responseBuffer);
            if (responseStr.contains("ICY 200 OK") || responseStr.contains("200 OK")) {
              _broadcastStartTime = DateTime.now();
              _setState(NtripServerState.broadcasting, "Đã tạo xong Mount Point: $mountpoint trên máy chủ");
              handshakeCompleter.complete(true);
            } else if (responseStr.contains("401") || responseStr.contains("ERROR")) {
              _setState(NtripServerState.error, "Caster từ chối: Sai mật khẩu hoặc trùng Mountpoint");
              handshakeCompleter.complete(false);
              stopBroadcasting();
            }
          }
        },
        onError: (e) {
          _setState(NtripServerState.error, "Lỗi kết nối trạm phát: $e");
          stopBroadcasting();
        },
        onDone: () {
          _setState(NtripServerState.disconnected, "Caster đã đóng kết nối trạm phát");
          stopBroadcasting();
        },
      );

      // Chờ phản hồi trong 5 giây
      bool ok = await handshakeCompleter.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          // Nhiều Caster cũ không trả ICY 200 OK mà nhận stream trực tiếp
          _broadcastStartTime = DateTime.now();
          _setState(NtripServerState.broadcasting, "Đã gửi yêu cầu tạo Mountpoint: $mountpoint (Streaming)");
          return true;
        },
      );

      return ok;
    } catch (e) {
      _setState(NtripServerState.error, "Không thể kết nối Caster phát Base: $e");
      stopBroadcasting();
      return false;
    }
  }

  /// Nạp các byte RTCM nhận từ Bluetooth vào luồng mạng gửi lên Caster
  void pushRtcmChunk(Uint8List chunk) {
    if (_socket != null && _state == NtripServerState.broadcasting) {
      try {
        _socket!.add(chunk);
        _bytesUploaded += chunk.length;
        onBytesStreamed?.call(_bytesUploaded);
      } catch (e) {
        _setState(NtripServerState.error, "Lỗi gửi RTCM lên Caster: $e");
      }
    }
  }

  /// Dừng phát Base
  void stopBroadcasting() {
    _socketSubscription?.cancel();
    _socketSubscription = null;
    _socket?.destroy();
    _socket = null;
    _broadcastStartTime = null;
    _setState(NtripServerState.disconnected, "Đã dừng trạm phát Base");
  }

  void _setState(NtripServerState st, String msg) {
    _state = st;
    onStatusChanged?.call(st, msg);
  }
}
