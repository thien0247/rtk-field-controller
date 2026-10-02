import 'dart:typed_data';

enum GnssChipset { unicoreUM980, ubloxZEDF9P, genericNmea }

/// Bộ phát sinh lệnh cấu hình phần cứng GNSS (Chuyển nhanh Rover <-> Base <-> Đo Tĩnh)
class GnssCommands {
  /// 1. Chuyển sang chế độ ROVER (Máy đo động)
  static List<String> getRoverCommands(GnssChipset chipset) {
    switch (chipset) {
      case GnssChipset.unicoreUM980:
        return [
          "UNLOG\r\n",
          "MODE ROVER\r\n",
          "CONFIG HEADING\r\n",
          "GNGGA 1\r\n",
          "GNRMC 1\r\n",
          "GNGSA 1\r\n",
          "GPGSV 1\r\n",
          "GLGSV 1\r\n",
          "GAGSV 1\r\n",
          "GBGSV 1\r\n",
          "SAVECONFIG\r\n",
        ];
      case GnssChipset.ubloxZEDF9P:
        // Cấu hình NMEA và tắt TMODE3
        return [
          "\$PUBX,40,GGA,0,1,0,0,0,0*5B\r\n",
          "\$PUBX,40,RMC,0,1,0,0,0,0*47\r\n",
          "\$PUBX,40,GSV,0,1,0,0,0,0*59\r\n",
        ];
      default:
        return ["\$PMTK314,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0*28\r\n"];
    }
  }

  /// 2. Chuyển sang chế độ BASE Tự Do (Auto Survey-In theo thời gian và sai số)
  static List<String> getBaseSurveyInCommands({
    required GnssChipset chipset,
    int durationSec = 60,
    double accuracyLimitMeters = 2.5,
  }) {
    switch (chipset) {
      case GnssChipset.unicoreUM980:
        return [
          "UNLOG\r\n",
          "MODE BASE TIME $durationSec $accuracyLimitMeters 3.5\r\n",
          "RTCM1005 1\r\n", // Tọa độ Trạm Base tham chiếu
          "RTCM1074 1\r\n", // GPS MSM4
          "RTCM1084 1\r\n", // GLONASS MSM4
          "RTCM1094 1\r\n", // Galileo MSM4
          "RTCM1124 1\r\n", // BeiDou MSM4
          "SAVECONFIG\r\n",
        ];
      case GnssChipset.ubloxZEDF9P:
        return [
          // Bật thông điệp RTCM 1005, 1077, 1087, 1127
          "\$PUBX,40,1005,0,1,0,0,0,0*34\r\n",
        ];
      default:
        return [];
    }
  }

  /// 3. Chuyển sang chế độ BASE Cố Định Tọa Độ Mốc (Fixed Base Position)
  static List<String> getBaseFixedCommands({
    required GnssChipset chipset,
    required double lat,
    required double lon,
    required double alt,
  }) {
    switch (chipset) {
      case GnssChipset.unicoreUM980:
        return [
          "UNLOG\r\n",
          "FIX POSITION ${lat.toStringAsFixed(8)} ${lon.toStringAsFixed(8)} ${alt.toStringAsFixed(4)}\r\n",
          "RTCM1005 1\r\n",
          "RTCM1074 1\r\n",
          "RTCM1084 1\r\n",
          "RTCM1124 1\r\n",
          "SAVECONFIG\r\n",
        ];
      default:
        return [];
    }
  }

  /// 4. Chuyển sang chế độ Đo GNSS Tĩnh (Static Survey ghi Raw Data)
  static List<String> getStaticSurveyCommands({
    required GnssChipset chipset,
    int epochRateSec = 1,
  }) {
    switch (chipset) {
      case GnssChipset.unicoreUM980:
        return [
          "UNLOG\r\n",
          "RANGEB $epochRateSec\r\n", // Đo khoảng cách mã và pha sóng mang
          "RAWX $epochRateSec\r\n",
          "SAVECONFIG\r\n",
        ];
      default:
        return [];
    }
  }

  /// 5. Lệnh Reset mềm đầu thu
  static List<String> getResetCommands(GnssChipset chipset) {
    switch (chipset) {
      case GnssChipset.unicoreUM980:
        return ["RESET\r\n"];
      case GnssChipset.ubloxZEDF9P:
        return ["\$PUBX,41,1,0007,0003,115200,0*19\r\n"];
      default:
        return ["\$PMTK104*37\r\n"];
    }
  }

  /// Đóng gói gói tin nhị phân UBX cho u-blox ZED-F9P
  static Uint8List createUbxFrame(int msgClass, int msgId, List<int> payload) {
    int length = payload.length;
    List<int> frame = [0xB5, 0x62, msgClass, msgId, length & 0xFF, (length >> 8) & 0xFF, ...payload];
    
    // Tính 8-bit Fletcher Checksum (CK_A & CK_B)
    int ckA = 0;
    int ckB = 0;
    for (int i = 2; i < frame.length; i++) {
      ckA = (ckA + frame[i]) & 0xFF;
      ckB = (ckB + ckA) & 0xFF;
    }
    frame.add(ckA);
    frame.add(ckB);
    return Uint8List.fromList(frame);
  }
}
