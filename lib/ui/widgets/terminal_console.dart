import 'package:flutter/material.dart';

class TerminalConsole extends StatelessWidget {
  final List<String> logs;
  final double height;

  const TerminalConsole({
    Key? key,
    required this.logs,
    this.height = 110.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F141C),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2B3A4A)),
      ),
      child: logs.isEmpty
          ? const Center(
              child: Text(
                "Sẵn sàng nhận dữ liệu...",
                style: TextStyle(color: Colors.white38, fontSize: 12, fontFamily: 'monospace'),
              ),
            )
          : ListView.builder(
              reverse: true, // Hiển thị log mới nhất ở đầu
              itemCount: logs.length,
              itemBuilder: (context, index) {
                String log = logs[index];
                Color logColor = const Color(0xFF00E5FF); // Xanh ngọc Cyan chuẩn terminal
                if (log.contains("Lỗi") || log.contains("từ chối")) {
                  logColor = const Color(0xFFFF5252);
                } else if (log.contains("thành công") || log.contains("Đã tạo xong")) {
                  logColor = const Color(0xFF69F0AE);
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1.5),
                  child: Text(
                    log,
                    style: TextStyle(
                      color: logColor,
                      fontSize: 11.5,
                      fontFamily: 'monospace',
                      height: 1.3,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
