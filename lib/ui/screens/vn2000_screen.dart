import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/vn2000_provinces.dart';
import '../../core/geodetic/coordinate_models.dart';
import '../../core/geodetic/vn2000_engine.dart';
import '../../providers/rtk_state_provider.dart';

class Vn2000Screen extends StatefulWidget {
  const Vn2000Screen({Key? key}) : super(key: key);

  @override
  State<Vn2000Screen> createState() => _Vn2000ScreenState();
}

class _Vn2000ScreenState extends State<Vn2000Screen> {
  final TextEditingController _wgsLatCtrl = TextEditingController(text: "20.582872");
  final TextEditingController _wgsLonCtrl = TextEditingController(text: "105.387742");
  final TextEditingController _wgsHaltCtrl = TextEditingController(text: "15.000");

  final TextEditingController _vnXCtrl = TextEditingController();
  final TextEditingController _vnYCtrl = TextEditingController();
  final TextEditingController _vnHCtrl = TextEditingController();

  final TextEditingController _ecefXCtrl = TextEditingController();
  final TextEditingController _ecefYCtrl = TextEditingController();
  final TextEditingController _ecefZCtrl = TextEditingController();

  late ProvinceKTT _province;
  int _zone = 3;

  @override
  void initState() {
    super.initState();
    final rtk = context.read<RtkStateProvider>();
    _province = rtk.selectedProvince;
    _zone = rtk.selectedZone;
    _calculateConversion();
  }

  void _calculateConversion() {
    double? lat = double.tryParse(_wgsLatCtrl.text);
    double? lon = double.tryParse(_wgsLonCtrl.text);
    double? h = double.tryParse(_wgsHaltCtrl.text) ?? 0.0;

    if (lat != null && lon != null) {
      // 1. Tính chuyển sang VN-2000 Gauss-Krüger
      VN2000Coord vn = VN2000Engine.wgs84ToVn2000(lat, lon, h, _province.kttDegree, _zone);
      _vnXCtrl.text = vn.x.toStringAsFixed(3);
      _vnYCtrl.text = vn.y.toStringAsFixed(3);
      _vnHCtrl.text = vn.height.toStringAsFixed(3);

      // 2. Tính tọa độ ECEF
      ECEFCoord ecef = VN2000Engine.geodeticToEcef(lat, lon, h);
      _ecefXCtrl.text = ecef.x.toStringAsFixed(3);
      _ecefYCtrl.text = ecef.y.toStringAsFixed(3);
      _ecefZCtrl.text = ecef.z.toStringAsFixed(3);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final rtk = context.watch<RtkStateProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF10141C),
      appBar: AppBar(
        title: const Text("Tính Chuyển Tọa Độ WGS-84 & VN-2000", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: const Color(0xFF1E2836),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: const Color(0xFF232D3B),
            onSelected: (val) {
              if (val == "gps") {
                if (rtk.currentPosition.latitude != 0.0) {
                  _wgsLatCtrl.text = rtk.currentPosition.latitude.toStringAsFixed(7);
                  _wgsLonCtrl.text = rtk.currentPosition.longitude.toStringAsFixed(7);
                  _wgsHaltCtrl.text = rtk.currentPosition.altitude.toStringAsFixed(3);
                  _calculateConversion();
                }
              } else if (val == "copy") {
                Clipboard.setData(ClipboardData(text: "X: ${_vnXCtrl.text}, Y: ${_vnYCtrl.text}, H: ${_vnHCtrl.text}"));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã sao chép tọa độ VN-2000 vào bộ nhớ tạm!")));
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: "gps", child: Text("Nhận tọa độ từ Định vị GNSS", style: TextStyle(color: Colors.white))),
              const PopupMenuItem(value: "copy", child: Text("Copy kết quả vào bộ nhớ", style: TextStyle(color: Colors.white))),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Cấu hình Kinh Tuyến Trục & Múi Chiếu
            _buildProvinceSelector(rtk),
            const SizedBox(height: 10),

            // Khối 1: Tọa Độ WGS-84
            _buildWgs84Card(),
            const SizedBox(height: 10),

            // Nút Chuyển Đổi Trung Tâm
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                icon: const Icon(Icons.transform),
                label: const Text("THỰC HIỆN TÍNH CHUYỂN TỌA ĐỘ", style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: _calculateConversion,
              ),
            ),
            const SizedBox(height: 10),

            // Khối 2: Tọa Độ Phẳng VN-2000
            _buildVn2000Card(),
            const SizedBox(height: 10),

            // Khối 3: Tọa Độ ECEF
            _buildEcefCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildProvinceSelector(RtkStateProvider rtk) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1B222D),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<ProvinceKTT>(
              isExpanded: true,
              dropdownColor: const Color(0xFF232D3B),
              value: _province,
              decoration: const InputDecoration(labelText: "Kinh Tuyến Trục Tỉnh Thành", isDense: true),
              items: VN2000Provinces.provinces.map((p) {
                return DropdownMenuItem(
                  value: p,
                  child: Text("${p.name} (${p.kttString})", style: const TextStyle(color: Colors.white, fontSize: 13)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _province = val);
                  rtk.setVn2000Province(val, _zone);
                  _calculateConversion();
                }
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                _buildZoneRadio(3),
                _buildZoneRadio(6),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneRadio(int z) {
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => _zone = z);
          context.read<RtkStateProvider>().setVn2000Province(_province, z);
          _calculateConversion();
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Radio<int>(
              value: z,
              groupValue: _zone,
              onChanged: (v) {
                setState(() => _zone = v!);
                _calculateConversion();
              },
            ),
            Text("$z°", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildWgs84Card() {
    return Card(
      color: const Color(0xFF1A2332),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("HỆ TỌA ĐỘ ĐỊA LÝ WGS-84 (B, L, H)", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 13)),
            const Divider(color: Colors.white12, height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _wgsLatCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(labelText: "Vĩ Độ WGS-84 (Độ)", isDense: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _wgsLonCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(labelText: "Kinh Độ WGS-84 (Độ)", isDense: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _wgsHaltCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(labelText: "Cao Độ H (m)", isDense: true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVn2000Card() {
    return Card(
      color: const Color(0xFF162923),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("HỆ TỌA ĐỘ PHẲNG VN-2000 (GAUSS-KRÜGER)", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13)),
            const Divider(color: Colors.white12, height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _vnXCtrl,
                    readOnly: true,
                    style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                    decoration: const InputDecoration(labelText: "Bắc X 2K (m)", isDense: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _vnYCtrl,
                    readOnly: true,
                    style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                    decoration: const InputDecoration(labelText: "Đông Y 2K (m)", isDense: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _vnHCtrl,
                    readOnly: true,
                    style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                    decoration: const InputDecoration(labelText: "Cao Độ H (m)", isDense: true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEcefCard() {
    return Card(
      color: const Color(0xFF1F1E2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("TỌA ĐỘ KHÔNG GIAN TRỰC GIAO ECEF (X, Y, Z)", style: TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 13)),
            const Divider(color: Colors.white12, height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ecefXCtrl,
                    readOnly: true,
                    style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'monospace'),
                    decoration: const InputDecoration(labelText: "X (m)", isDense: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _ecefYCtrl,
                    readOnly: true,
                    style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'monospace'),
                    decoration: const InputDecoration(labelText: "Y (m)", isDense: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _ecefZCtrl,
                    readOnly: true,
                    style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'monospace'),
                    decoration: const InputDecoration(labelText: "Z (m)", isDense: true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
