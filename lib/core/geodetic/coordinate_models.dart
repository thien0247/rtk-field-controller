import 'dart:math' as math;

/// Mô hình tọa độ địa lý WGS-84 (B, L, H)
class WGS84Coord {
  final double lat; // Vĩ độ thập phân (Độ)
  final double lon; // Kinh độ thập phân (Độ)
  final double height; // Chiều cao trắc địa elipsoid (mét)

  WGS84Coord({required this.lat, required this.lon, this.height = 0.0});

  String get latDms => toDms(lat, isLat: true);
  String get lonDms => toDms(lon, isLat: false);

  static String toDms(double val, {required bool isLat}) {
    String dir = isLat ? (val >= 0 ? "B" : "N") : (val >= 0 ? "Đ" : "T");
    double absVal = val.abs();
    int d = absVal.floor();
    double remM = (absVal - d) * 60;
    int m = remM.floor();
    double s = (remM - m) * 60;
    return "$d°$m'${s.toStringAsFixed(5)}\"$dir";
  }

  static double fromDms(int d, int m, double s, [bool isNegative = false]) {
    double deg = d + (m / 60.0) + (s / 3600.0);
    return isNegative ? -deg : deg;
  }
}

/// Mô hình tọa độ phẳng trắc địa VN-2000 (X - Bắc, Y - Đông)
class VN2000Coord {
  final double x; // Tọa độ X (Bắc) tính bằng mét
  final double y; // Tọa độ Y (Đông) tính bằng mét (kèm dịch chuyển trục False Easting 500,000m)
  final double height; // Cao độ thủy chuẩn (m)
  final double ktt; // Kinh tuyến trục (Độ)
  final int zone; // Múi chiếu: 3 hoặc 6 độ

  VN2000Coord({
    required this.x,
    required this.y,
    this.height = 0.0,
    required this.ktt,
    required this.zone,
  });

  @override
  String toString() => "VN2000(X: ${x.toStringAsFixed(3)}, Y: ${y.toStringAsFixed(3)}, H: ${height.toStringAsFixed(3)}, KTT: $ktt°, Múi: $zone°)";
}

/// Tọa độ không gian trực giao ECEF (X, Y, Z)
class ECEFCoord {
  final double x;
  final double y;
  final double z;

  ECEFCoord({required this.x, required this.y, required this.z});
}
