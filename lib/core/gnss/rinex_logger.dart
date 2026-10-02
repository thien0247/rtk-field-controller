import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';

/// Trình quản lý phiên đo GNSS Tĩnh và xuất file dữ liệu RINEX 2.11
class RinexStaticSession {
  final String pointName;       // Tên điểm mốc (vd: Base389)
  final String observerName;    // Tên người đo (vd: B102)
  final double antennaHeight;   // Chiều cao sào / chênh cao tới đáy máy (vd: 1.500m)
  final int epochIntervalSec;   // Khoảng thời gian giữa 2 Epoch (vd: 1s)
  final DateTime startTime;

  int epochCount = 0;
  int bytesRecorded = 0;
  bool isRecording = false;
  IOSink? _fileSink;
  File? _outputFile;

  RinexStaticSession({
    required this.pointName,
    required this.observerName,
    required this.antennaHeight,
    this.epochIntervalSec = 1,
    required this.startTime,
  });

  /// Bắt đầu phiên đo tĩnh và tạo tệp trên bộ nhớ
  Future<String> start(String targetDirectoryPath) async {
    isRecording = true;
    epochCount = 0;
    bytesRecorded = 0;

    // Đặt tên file theo chuẩn trắc địa RINEX (vd: BASE3890.26o)
    String cleanPoint = pointName.padRight(4, '0').substring(0, 4).toUpperCase();
    String dayOfYear = DateFormat('D').format(startTime).padLeft(3, '0');
    String yearTwoDigits = DateFormat('yy').format(startTime);
    String fileName = "${cleanPoint}${dayOfYear}0.${yearTwoDigits}o";

    Directory dir = Directory(targetDirectoryPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    _outputFile = File("${dir.path}/$fileName");
    _fileSink = _outputFile!.openWrite();

    // Ghi tiêu chuẩn RINEX 2.11 Header
    _writeRinexHeader();

    return _outputFile!.path;
  }

  void _writeRinexHeader() {
    if (_fileSink == null) return;

    void writeLine(String content, String label) {
      String paddedContent = content.padRight(60).substring(0, 60);
      String paddedLabel = label.padRight(20).substring(0, 20);
      _fileSink!.writeln("$paddedContent$paddedLabel");
    }

    String utcDate = DateFormat("yyyyMMdd HHmmss").format(startTime.toUtc()) + " UTC";
    String firstObs = "${startTime.year.toString().padLeft(6)}"
        "${startTime.month.toString().padLeft(6)}"
        "${startTime.day.toString().padLeft(6)}"
        "${startTime.hour.toString().padLeft(6)}"
        "${startTime.minute.toString().padLeft(6)}"
        "${startTime.second.toString().padLeft(11)}.0000000     GPS";

    writeLine("     2.11           OBSERVATION DATA    M (MIXED)", "RINEX VERSION / TYPE");
    writeLine("RTK Field Controller${observerName.padLeft(20)}  $utcDate", "PGM / RUN BY / DATE");
    writeLine(pointName, "MARKER NAME");
    writeLine(observerName.padRight(20) + "VIETNAM SURVEY TEAM", "OBSERVER / AGENCY");
    writeLine("ANT-INTERNAL        INTERNAL", "ANT # / TYPE");
    writeLine("        0.0000        0.0000        0.0000", "APPROX POSITION XYZ");
    writeLine("${antennaHeight.toStringAsFixed(4).padLeft(14)}        0.0000        0.0000", "ANTENNA: DELTA H/E/N");
    writeLine("     1     0", "WAVELENGTH FACT L1/2");
    writeLine("     4    L1    L2    C1    P2", "# / TYPES OF OBSERV");
    writeLine("${epochIntervalSec.toStringAsFixed(3).padLeft(10)}", "INTERVAL");
    writeLine(firstObs, "TIME OF FIRST OBS");
    writeLine("", "END OF HEADER");
  }

  /// Nạp các byte raw dữ liệu vệ tinh từ Bluetooth vào file
  void recordRawChunk(Uint8List chunk) {
    if (!isRecording || _fileSink == null) return;
    _fileSink!.add(chunk);
    bytesRecorded += chunk.length;
    epochCount = (bytesRecorded / 256).floor(); // Ước lượng số epoch
  }

  /// Kết thúc đo và đóng tệp
  Future<String?> stop() async {
    isRecording = false;
    if (_fileSink != null) {
      await _fileSink!.flush();
      await _fileSink!.close();
      _fileSink = null;
      return _outputFile?.path;
    }
    return null;
  }
}
