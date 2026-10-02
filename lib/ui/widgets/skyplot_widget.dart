import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/gnss/nmea_parser.dart';

/// Widget vẽ biểu đồ bầu trời vệ tinh (Skyplot 360° Radar) bằng CustomPainter
class SkyplotWidget extends StatelessWidget {
  final Map<int, SatelliteInfo> satellites;
  final double size;

  const SkyplotWidget({
    Key? key,
    required this.satellites,
    this.size = 200.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SkyplotPainter(satellites: satellites),
      ),
    );
  }
}

class _SkyplotPainter extends CustomPainter {
  final Map<int, SatelliteInfo> satellites;

  _SkyplotPainter({required this.satellites});

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2.0;
    final Offset center = Offset(radius, radius);

    // 1. Vẽ nền radar
    final Paint bgPaint = Paint()
      ..color = const Color(0xFF1E242B)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // 2. Vẽ các vòng tròn đồng tâm (0°, 30°, 60°)
    final Paint gridPaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, radius * 0.33, gridPaint); // 60°
    canvas.drawCircle(center, radius * 0.66, gridPaint); // 30°
    canvas.drawCircle(center, radius - 2, gridPaint);    // 0° (Chân trời)

    // 3. Vẽ 2 trục chữ thập (Bắc - Nam, Đông - Tây)
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), gridPaint);
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), gridPaint);

    // 4. Vẽ nhãn 4 phương (B - N - Đ - T)
    _drawText(canvas, "B", Offset(center.dx, 8), Colors.redAccent);
    _drawText(canvas, "N", Offset(center.dx, size.height - 18), Colors.white70);
    _drawText(canvas, "Đ", Offset(size.width - 14, center.dy - 6), Colors.white70);
    _drawText(canvas, "T", Offset(14, center.dy - 6), Colors.white70);

    // 5. Vẽ từng vệ tinh
    for (var sat in satellites.values) {
      if (sat.elevation <= 0) continue;

      // Tính tọa độ cực sang tọa độ canvas
      double r = (90.0 - sat.elevation) / 90.0 * (radius - 12);
      double rad = (sat.azimuth - 90.0) * math.pi / 180.0;
      double x = center.dx + r * math.cos(rad);
      double y = center.dy + r * math.sin(rad);

      Color satColor = _getConstellationColor(sat.constellation);

      // Vẽ vòng tròn vệ tinh
      final Paint dotPaint = Paint()..color = satColor;
      canvas.drawCircle(Offset(x, y), 8.0, dotPaint);

      // Vẽ viền nếu là vệ tinh đang dùng để tính FIX
      if (sat.isUsedInFix) {
        final Paint strokePaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawCircle(Offset(x, y), 9.0, strokePaint);
      }

      // Vẽ số PRN bên trong chấm
      _drawText(canvas, "${sat.prn}", Offset(x, y - 5), Colors.black, fontSize: 8, isBold: true);
    }
  }

  Color _getConstellationColor(GnssConstellation c) {
    switch (c) {
      case GnssConstellation.gps:
        return const Color(0xFFE53935); // Đỏ
      case GnssConstellation.glonass:
        return const Color(0xFF1E88E5); // Xanh dương
      case GnssConstellation.galileo:
        return const Color(0xFF43A047); // Xanh lá
      case GnssConstellation.beidou:
        return const Color(0xFFFB8C00); // Cam
      default:
        return Colors.grey;
    }
  }

  void _drawText(Canvas canvas, String text, Offset center, Color color, {double fontSize = 11, bool isBold = false}) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(center.dx - textPainter.width / 2, center.dy));
  }

  @override
  bool shouldRepaint(covariant _SkyplotPainter oldDelegate) => true;
}
