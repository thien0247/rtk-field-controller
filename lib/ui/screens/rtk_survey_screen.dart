import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/geodetic/coordinate_models.dart';
import '../../providers/rtk_state_provider.dart';
import '../widgets/skyplot_widget.dart';
import '../widgets/solution_badge.dart';

class RtkSurveyScreen extends StatefulWidget {
  const RtkSurveyScreen({Key? key}) : super(key: key);

  @override
  State<RtkSurveyScreen> createState() => _RtkSurveyScreenState();
}

class _RtkSurveyScreenState extends State<RtkSurveyScreen> {
  final TextEditingController _codeController = TextEditingController(text: "GT");
  final TextEditingController _nameController = TextEditingController(text: "Đo 0");
  int _pointCounter = 0;

  // Danh mục mã địa hình trắc địa nhanh (Quick feature codes)
  final List<String> _quickTags = ["Góc", "CC", "MĐ", "Nhà", "Cây", "Cột", "Hố", "Cống", "Tường"];

  @override
  Widget build(BuildContext context) {
    final rtk = context.watch<RtkStateProvider>();
    final pos = rtk.currentPosition;
    final vn = rtk.currentVn2000;

    return Scaffold(
      backgroundColor: const Color(0xFF10141C),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Thanh Trạng Thái Đỉnh
            _buildStatusBar(rtk, pos),

            // 2. Thẻ Thông Tin Tọa Độ & Chất Lượng Đo (HUD Panel)
            _buildCoordinatesCard(pos, vn, rtk),

            // 3. Khối Chính: Skyplot Radar + Form Thu Thập + Cột Mã Nhanh
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Cột Trái: Radar Skyplot Vệ Tinh 360°
                    Expanded(
                      flex: 5,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SkyplotWidget(satellites: pos.satellites, size: 210),
                          const SizedBox(height: 6),
                          _buildConstellationLegend(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Cột Giữa: Form Nhập Điểm Đo
                    Expanded(
                      flex: 4,
                      child: _buildPointForm(rtk),
                    ),
                    const SizedBox(width: 8),

                    // Cột Phải: Dãy Nút Mã Địa Hình Nhanh
                    _buildQuickTagColumn(),
                  ],
                ),
              ),
            ),

            // 4. Thanh Chân Trang (Footer)
            _buildFooter(rtk),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar(RtkStateProvider rtk, dynamic pos) {
    return Container(
      color: const Color(0xFF1B232F),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _buildIndicator("GNSS", rtk.isBluetoothConnected),
          const SizedBox(width: 14),
          _buildIndicator(rtk.mode == OperatingMode.base ? "BASE" : "CASTER", rtk.isCasterConnected),
          const Spacer(),
          SolutionBadge(
            solution: pos.solution,
            hAcc: pos.estimatedHorizontalAccuracy,
          ),
          const SizedBox(width: 12),
          Text(
            "VT: ${pos.satellitesUsed}/${pos.satellitesInView}",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(width: 10),
          Text(
            "HDOP: ${pos.hdop.toStringAsFixed(1)}",
            style: const TextStyle(color: Colors.pinkAccent, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(String label, bool active) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? Colors.greenAccent : Colors.redAccent,
            boxShadow: [
              BoxShadow(
                color: (active ? Colors.greenAccent : Colors.redAccent).withOpacity(0.5),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildCoordinatesCard(dynamic pos, VN2000Coord? vn, RtkStateProvider rtk) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF161E28),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2E3D4F)),
      ),
      child: Column(
        children: [
          // Tọa độ phẳng VN-2000
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "X (Bắc): ${vn != null ? vn.x.toStringAsFixed(3) : '---'} m",
                style: const TextStyle(color: Colors.greenAccent, fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
              ),
              Text(
                "Y (Đông): ${vn != null ? vn.y.toStringAsFixed(3) : '---'} m",
                style: const TextStyle(color: Colors.cyanAccent, fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Cao độ & Tọa độ Địa lý WGS84
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "H (Cao độ): ${vn != null ? vn.height.toStringAsFixed(3) : '---'} m",
                style: const TextStyle(color: Colors.amberAccent, fontSize: 13, fontFamily: 'monospace'),
              ),
              Text(
                "B84: ${WGS84Coord.toDms(pos.latitude, isLat: true)}",
                style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'monospace'),
              ),
              Text(
                "L84: ${WGS84Coord.toDms(pos.longitude, isLat: false)}",
                style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'monospace'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConstellationLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildDot(const Color(0xFFE53935), "GPS"),
        const SizedBox(width: 8),
        _buildDot(const Color(0xFF1E88E5), "GLO"),
        const SizedBox(width: 8),
        _buildDot(const Color(0xFF43A047), "GAL"),
        const SizedBox(width: 8),
        _buildDot(const Color(0xFFFB8C00), "BDS"),
      ],
    );
  }

  Widget _buildDot(Color c, String text) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 3),
        Text(text, style: const TextStyle(color: Colors.white60, fontSize: 10)),
      ],
    );
  }

  Widget _buildPointForm(RtkStateProvider rtk) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        TextField(
          controller: _codeController,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: const InputDecoration(labelText: "Mã Điểm", isDense: true),
        ),
        TextField(
          controller: _nameController,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: const InputDecoration(labelText: "Tên Điểm", isDense: true),
        ),
        Row(
          children: [
            const Text("Cao Sào: ", style: TextStyle(color: Colors.white70, fontSize: 12)),
            Text("${rtk.poleHeight.toStringAsFixed(2)} m", style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.add_location_alt, size: 22),
            label: const Text("LƯU ĐIỂM", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            onPressed: () {
              rtk.recordCurrentPoint(code: _codeController.text, name: _nameController.text);
              setState(() {
                _pointCounter++;
                _nameController.text = "Đo $_pointCounter";
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickTagColumn() {
    return SizedBox(
      width: 52,
      child: ListView.separated(
        itemCount: _quickTags.length,
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (context, i) {
          String tag = _quickTags[i];
          return InkWell(
            onTap: () => setState(() => _codeController.text = tag),
            child: Container(
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF233040),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF3F546E)),
              ),
              child: Text(
                tag,
                style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFooter(RtkStateProvider rtk) {
    return Container(
      color: const Color(0xFF1B232F),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "VN-2000: ${rtk.selectedProvince.name} (${rtk.selectedProvince.kttString}) - Múi ${rtk.selectedZone}°",
            style: const TextStyle(color: Colors.white70, fontSize: 11.5),
          ),
          Text(
            "Tổng điểm đã đo: ${rtk.surveyPoints.length}",
            style: const TextStyle(color: Colors.greenAccent, fontSize: 11.5, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
