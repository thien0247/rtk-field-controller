import 'dart:math' as math;
import 'coordinate_models.dart';

/// Bộ máy Tính chuyển Tọa độ Trắc địa Quốc gia VN-2000
/// Tuân thủ quy chuẩn Bộ Tài nguyên và Môi trường Việt Nam (Bursa-Wolf 7 Parameters & Gauss-Krüger)
class VN2000Engine {
  // Bán trục lớn và độ dẹt Elipsoid WGS-84 / VN-2000
  static const double a = 6378137.0; // Bán trục lớn (m)
  static const double f = 1.0 / 298.257223563; // Độ dẹt
  static const double b = a * (1.0 - f); // Bán trục nhỏ
  static const double e2 = (a * a - b * b) / (a * a); // Tâm sai thứ nhất bình phương
  static const double ePrime2 = (a * a - b * b) / (b * b); // Tâm sai thứ hai bình phương

  // 7 Tham số tính chuyển chuẩn quốc gia WGS-84 -> VN-2000
  static const double dx = -191.90441429;
  static const double dy = -39.30318279;
  static const double dz = -111.45032835;
  static const double wx = -0.00928836 * (math.pi / (180 * 3600)); // Radian
  static const double wy = 0.00975471 * (math.pi / (180 * 3600));  // Radian
  static const double wz = -0.00420601 * (math.pi / (180 * 3600)); // Radian
  static const double dm = -1.09279e-6; // Hệ số tỷ lệ

  /// 1. Chuyển Tọa độ Địa lý (Lat, Lon, H) -> Tọa độ Không gian ECEF (X, Y, Z)
  static ECEFCoord geodeticToEcef(double latDeg, double lonDeg, double h) {
    double phi = latDeg * math.pi / 180.0;
    double lambda = lonDeg * math.pi / 180.0;
    double sinPhi = math.sin(phi);
    double cosPhi = math.cos(phi);

    double N = a / math.sqrt(1.0 - e2 * sinPhi * sinPhi);

    double x = (N + h) * cosPhi * math.cos(lambda);
    double y = (N + h) * cosPhi * math.sin(lambda);
    double z = (N * (1.0 - e2) + h) * sinPhi;

    return ECEFCoord(x: x, y: y, z: z);
  }

  /// 2. Chuyển Tọa độ Không gian ECEF (X, Y, Z) -> Tọa độ Địa lý (Lat, Lon, H) (Bowring Algorithm)
  static WGS84Coord ecefToGeodetic(ECEFCoord ecef) {
    double p = math.sqrt(ecef.x * ecef.x + ecef.y * ecef.y);
    double theta = math.atan2(ecef.z * a, p * b);

    double sinTheta = math.sin(theta);
    double cosTheta = math.cos(theta);

    double phi = math.atan2(
      ecef.z + ePrime2 * b * sinTheta * sinTheta * sinTheta,
      p - e2 * a * cosTheta * cosTheta * cosTheta,
    );

    double lambda = math.atan2(ecef.y, ecef.x);
    double sinPhi = math.sin(phi);
    double N = a / math.sqrt(1.0 - e2 * sinPhi * sinPhi);
    double h = p / math.cos(phi) - N;

    return WGS84Coord(
      lat: phi * 180.0 / math.pi,
      lon: lambda * 180.0 / math.pi,
      height: h,
    );
  }

  /// 3. Biến đổi 7 Tham số Helmert (WGS-84 ECEF -> VN-2000 ECEF)
  static ECEFCoord transformWgs84ToVn2000Ecef(ECEFCoord wgs) {
    double scale = 1.0 + dm;
    double x = dx + scale * (wgs.x - wz * wgs.y + wy * wgs.z);
    double y = dy + scale * (wz * wgs.x + wgs.y - wx * wgs.z);
    double z = dz + scale * (-wy * wgs.x + wx * wgs.y + wgs.z);
    return ECEFCoord(x: x, y: y, z: z);
  }

  /// 4. Biến đổi Ngược 7 Tham số Helmert (VN-2000 ECEF -> WGS-84 ECEF)
  static ECEFCoord transformVn2000ToWgs84Ecef(ECEFCoord vn) {
    double scale = 1.0 - dm;
    double vx = vn.x - dx;
    double vy = vn.y - dy;
    double vz = vn.z - dz;

    double x = scale * (vx + wz * vy - wy * vz);
    double y = scale * (-wz * vx + vy + wx * vz);
    double z = scale * (wy * vx - wx * vy + vz);
    return ECEFCoord(x: x, y: y, z: z);
  }

  /// 5. Phép chiếu Gauss-Krüger / UTM (Địa lý VN-2000 -> Phẳng X, Y)
  static VN2000Coord projectToGauss(double latDeg, double lonDeg, double h, double kttDeg, int zone) {
    double k0 = (zone == 3) ? 0.9999 : 0.9996; // Múi 3° k0 = 0.9999, Múi 6° k0 = 0.9996
    double phi = latDeg * math.pi / 180.0;
    double lambda = lonDeg * math.pi / 180.0;
    double lambda0 = kttDeg * math.pi / 180.0;

    double dLambda = lambda - lambda0;

    double sinPhi = math.sin(phi);
    double cosPhi = math.cos(phi);
    double tanPhi = math.tan(phi);

    double N = a / math.sqrt(1.0 - e2 * sinPhi * sinPhi);
    double T = tanPhi * tanPhi;
    double C = ePrime2 * cosPhi * cosPhi;
    double A = cosPhi * dLambda;

    // Chiều dài cung kinh tuyến M
    double M = a * (
      (1.0 - e2 / 4.0 - 3.0 * e2 * e2 / 64.0 - 5.0 * e2 * e2 * e2 / 256.0) * phi -
      (3.0 * e2 / 8.0 + 3.0 * e2 * e2 / 32.0 + 45.0 * e2 * e2 * e2 / 1024.0) * math.sin(2.0 * phi) +
      (15.0 * e2 * e2 / 256.0 + 45.0 * e2 * e2 * e2 / 1024.0) * math.sin(4.0 * phi) -
      (35.0 * e2 * e2 * e2 / 3072.0) * math.sin(6.0 * phi)
    );

    // Tính tọa độ X (Bắc)
    double x = k0 * (M + N * tanPhi * (
      (A * A) / 2.0 +
      (5.0 - T + 9.0 * C + 4.0 * C * C) * (A * A * A * A) / 24.0 +
      (61.0 - 58.0 * T + T * T + 600.0 * C - 330.0 * ePrime2) * (A * A * A * A * A * A) / 720.0
    ));

    // Tính tọa độ Y (Đông) với False Easting 500.000m
    double y = 500000.0 + k0 * N * (
      A +
      (1.0 - T + C) * (A * A * A) / 6.0 +
      (5.0 - 18.0 * T + T * T + 72.0 * C - 58.0 * ePrime2) * (A * A * A * A * A) / 120.0
    );

    return VN2000Coord(x: x, y: y, height: h, ktt: kttDeg, zone: zone);
  }

  /// 6. Hàm Tổng Hợp: WGS-84 (Lat, Lon, H) -> VN-2000 (X, Y, H)
  static VN2000Coord wgs84ToVn2000(double lat, double lon, double h, double ktt, int zone) {
    // Bước 1: WGS84 Geodetic -> WGS84 ECEF
    ECEFCoord wgsEcef = geodeticToEcef(lat, lon, h);
    // Bước 2: 7-param Helmert -> VN2000 ECEF
    ECEFCoord vnEcef = transformWgs84ToVn2000Ecef(wgsEcef);
    // Bước 3: VN2000 ECEF -> VN2000 Geodetic (B, L, H)
    WGS84Coord vnGeo = ecefToGeodetic(vnEcef);
    // Bước 4: VN2000 Geodetic -> Gauss-Krüger Phẳng (X, Y)
    return projectToGauss(vnGeo.lat, vnGeo.lon, vnGeo.height, ktt, zone);
  }
}
