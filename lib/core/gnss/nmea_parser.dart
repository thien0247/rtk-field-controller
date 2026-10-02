import 'dart:math' as math;

/// Hệ thống vệ tinh GNSS
enum GnssConstellation { gps, glonass, galileo, beidou, unknown }

/// Trạng thái giải pháp RTK
enum RtkSolution { invalid, single, dgps, pps, rtkFix, rtkFloat, deadReckoning }

/// Thông tin 1 vệ tinh hiển thị trên Skyplot
class SatelliteInfo {
  final int prn;
  final GnssConstellation constellation;
  final double elevation; // Độ cao: 0° (chân trời) đến 90° (thiên đỉnh)
  final double azimuth;   // Góc phương vị: 0° đến 359°
  final double snr;       // Tỷ số tín hiệu/nhiễu SNR (dB-Hz)
  final bool isUsedInFix;

  SatelliteInfo({
    required this.prn,
    required this.constellation,
    required this.elevation,
    required this.azimuth,
    required this.snr,
    this.isUsedInFix = false,
  });

  /// Tọa độ chuẩn hóa trên mặt phẳng Skyplot (x, y từ -1.0 đến +1.0)
  math.Point<double> toPolarCoords() {
    double r = (90.0 - elevation) / 90.0; // r = 0 tại thiên đỉnh, r = 1 tại chân trời
    double thetaRad = (azimuth - 90.0) * math.pi / 180.0;
    return math.Point<double>(r * math.cos(thetaRad), r * math.sin(thetaRad));
  }
}

/// Dữ liệu định vị tổng hợp từ các bản tin NMEA
class GnssPositionData {
  final double latitude;
  final double longitude;
  final double altitude;
  final double geoidSeparation;
  final RtkSolution solution;
  final int satellitesUsed;
  final int satellitesInView;
  final double hdop;
  final double vdop;
  final double pdop;
  final double ageOfCorrection;
  final double speedKnots;
  final double headingDegrees;
  final String timestamp;
  final Map<int, SatelliteInfo> satellites;

  GnssPositionData({
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.altitude = 0.0,
    this.geoidSeparation = 0.0,
    this.solution = RtkSolution.invalid,
    this.satellitesUsed = 0,
    this.satellitesInView = 0,
    this.hdop = 99.9,
    this.vdop = 99.9,
    this.pdop = 99.9,
    this.ageOfCorrection = 0.0,
    this.speedKnots = 0.0,
    this.headingDegrees = 0.0,
    this.timestamp = "",
    this.satellites = const {},
  });

  String get solutionText {
    switch (solution) {
      case RtkSolution.rtkFix:
        return "RTK FIX";
      case RtkSolution.rtkFloat:
        return "RTK FLOAT";
      case RtkSolution.dgps:
        return "D-GNSS";
      case RtkSolution.single:
        return "SINGLE";
      default:
        return "NO FIX";
    }
  }

  /// Ước lượng sai số vị trí theo HDOP và loại giải pháp
  double get estimatedHorizontalAccuracy {
    switch (solution) {
      case RtkSolution.rtkFix:
        return math.max(0.008, hdop * 0.010); // ~ 0.8cm - 1.5cm
      case RtkSolution.rtkFloat:
        return math.max(0.15, hdop * 0.25);  // ~ 15cm - 50cm
      case RtkSolution.dgps:
        return math.max(0.6, hdop * 0.8);    // ~ 0.6m - 1.5m
      case RtkSolution.single:
        return math.max(1.5, hdop * 2.0);    // ~ 1.5m - 3.5m
      default:
        return 99.0;
    }
  }
}

/// Bộ phân giải câu NMEA 0183 thời gian thực
class NmeaParser {
  final Map<int, SatelliteInfo> _satMap = {};
  GnssPositionData _currentData = GnssPositionData();

  GnssPositionData get currentData => _currentData;

  GnssPositionData? parseSentence(String line) {
    line = line.trim();
    if (!line.startsWith('\$')) return null;

    // Tách kiểm tra Checksum
    int starIndex = line.indexOf('*');
    String payload = (starIndex != -1) ? line.substring(1, starIndex) : line.substring(1);
    List<String> parts = payload.split(',');
    if (parts.isEmpty) return null;

    String type = parts[0].toUpperCase();

    if (type.endsWith("GGA")) {
      _parseGga(parts);
    } else if (type.endsWith("RMC")) {
      _parseRmc(parts);
    } else if (type.endsWith("GSA")) {
      _parseGsa(parts);
    } else if (type.endsWith("GSV")) {
      _parseGsv(parts, type);
    }

    return _currentData;
  }

  void _parseGga(List<String> p) {
    if (p.length < 15) return;
    String time = p[1];
    double lat = _parseCoordinate(p[2], p[3]);
    double lon = _parseCoordinate(p[4], p[5]);
    int quality = int.tryParse(p[6]) ?? 0;
    int sats = int.tryParse(p[7]) ?? 0;
    double hdop = double.tryParse(p[8]) ?? 99.9;
    double alt = double.tryParse(p[9]) ?? 0.0;
    double geoid = double.tryParse(p[11]) ?? 0.0;
    double age = double.tryParse(p[13]) ?? 0.0;

    RtkSolution sol = RtkSolution.invalid;
    if (quality == 1) sol = RtkSolution.single;
    else if (quality == 2) sol = RtkSolution.dgps;
    else if (quality == 4) sol = RtkSolution.rtkFix;
    else if (quality == 5) sol = RtkSolution.rtkFloat;

    _currentData = GnssPositionData(
      latitude: lat,
      longitude: lon,
      altitude: alt,
      geoidSeparation: geoid,
      solution: sol,
      satellitesUsed: sats,
      satellitesInView: _satMap.length,
      hdop: hdop,
      vdop: _currentData.vdop,
      pdop: _currentData.pdop,
      ageOfCorrection: age,
      speedKnots: _currentData.speedKnots,
      headingDegrees: _currentData.headingDegrees,
      timestamp: time,
      satellites: Map.from(_satMap),
    );
  }

  void _parseRmc(List<String> p) {
    if (p.length < 9) return;
    double speed = double.tryParse(p[7]) ?? 0.0;
    double heading = double.tryParse(p[8]) ?? 0.0;
    _currentData = GnssPositionData(
      latitude: _currentData.latitude,
      longitude: _currentData.longitude,
      altitude: _currentData.altitude,
      geoidSeparation: _currentData.geoidSeparation,
      solution: _currentData.solution,
      satellitesUsed: _currentData.satellitesUsed,
      satellitesInView: _satMap.length,
      hdop: _currentData.hdop,
      vdop: _currentData.vdop,
      pdop: _currentData.pdop,
      ageOfCorrection: _currentData.ageOfCorrection,
      speedKnots: speed,
      headingDegrees: heading,
      timestamp: _currentData.timestamp,
      satellites: Map.from(_satMap),
    );
  }

  void _parseGsa(List<String> p) {
    if (p.length < 18) return;
    double pdop = double.tryParse(p[15]) ?? 99.9;
    double hdop = double.tryParse(p[16]) ?? 99.9;
    double vdop = double.tryParse(p[17]) ?? 99.9;

    _currentData = GnssPositionData(
      latitude: _currentData.latitude,
      longitude: _currentData.longitude,
      altitude: _currentData.altitude,
      geoidSeparation: _currentData.geoidSeparation,
      solution: _currentData.solution,
      satellitesUsed: _currentData.satellitesUsed,
      satellitesInView: _satMap.length,
      hdop: hdop,
      vdop: vdop,
      pdop: pdop,
      ageOfCorrection: _currentData.ageOfCorrection,
      speedKnots: _currentData.speedKnots,
      headingDegrees: _currentData.headingDegrees,
      timestamp: _currentData.timestamp,
      satellites: Map.from(_satMap),
    );
  }

  void _parseGsv(List<String> p, String talker) {
    if (p.length < 8) return;
    GnssConstellation constellation = GnssConstellation.unknown;
    if (talker.startsWith("GP")) constellation = GnssConstellation.gps;
    else if (talker.startsWith("GL")) constellation = GnssConstellation.glonass;
    else if (talker.startsWith("GA")) constellation = GnssConstellation.galileo;
    else if (talker.startsWith("GB") || talker.startsWith("BD")) constellation = GnssConstellation.beidou;

    // Mỗi câu GSV chứa tối đa 4 vệ tinh, mỗi cụm 4 trường (PRN, Elev, Azim, SNR)
    for (int i = 4; i + 3 < p.length; i += 4) {
      int? prn = int.tryParse(p[i]);
      if (prn == null) continue;
      double elev = double.tryParse(p[i + 1]) ?? 0.0;
      double azim = double.tryParse(p[i + 2]) ?? 0.0;
      double snr = double.tryParse(p[i + 3]) ?? 0.0;

      // Đánh số mã nhận diện duy nhất
      int key = (constellation.index * 1000) + prn;
      _satMap[key] = SatelliteInfo(
        prn: prn,
        constellation: constellation,
        elevation: elev,
        azimuth: azim,
        snr: snr,
      );
    }
  }

  double _parseCoordinate(String val, String dir) {
    if (val.isEmpty) return 0.0;
    double raw = double.tryParse(val) ?? 0.0;
    int deg = (raw / 100).floor();
    double min = raw - (deg * 100);
    double result = deg + (min / 60.0);
    if (dir == 'S' || dir == 'W') result = -result;
    return result;
  }
}
