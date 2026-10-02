import 'package:flutter/material.dart';
import '../../core/gnss/nmea_parser.dart';

class SolutionBadge extends StatelessWidget {
  final RtkSolution solution;
  final double hAcc;

  const SolutionBadge({
    Key? key,
    required this.solution,
    required this.hAcc,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor = Colors.white;
    String label;

    switch (solution) {
      case RtkSolution.rtkFix:
        bgColor = const Color(0xFF00C853); // Xanh lá FIX sáng
        label = "RTK FIX";
        break;
      case RtkSolution.rtkFloat:
        bgColor = const Color(0xFFFFD600); // Vàng Float
        textColor = Colors.black;
        label = "RTK FLOAT";
        break;
      case RtkSolution.dgps:
        bgColor = const Color(0xFFFF6D00); // Cam D-GNSS
        label = "D-GNSS";
        break;
      case RtkSolution.single:
        bgColor = const Color(0xFFD50000); // Đỏ Single
        label = "SINGLE";
        break;
      default:
        bgColor = Colors.grey.shade800;
        label = "NO FIX";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(color: bgColor.withOpacity(0.4), blurRadius: 6, spreadRadius: 1),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "±${hAcc < 1.0 ? (hAcc * 100).toStringAsFixed(1) + 'cm' : hAcc.toStringAsFixed(2) + 'm'}",
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
