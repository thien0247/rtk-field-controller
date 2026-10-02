import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../providers/rtk_state_provider.dart';

class MapSurveyScreen extends StatefulWidget {
  const MapSurveyScreen({Key? key}) : super(key: key);

  @override
  State<MapSurveyScreen> createState() => _MapSurveyScreenState();
}

class _MapSurveyScreenState extends State<MapSurveyScreen> {
  final MapController _mapController = MapController();
  bool _connectLines = false;

  @override
  Widget build(BuildContext context) {
    final rtk = context.watch<RtkStateProvider>();
    final pos = rtk.currentPosition;

    LatLng currentCenter = (pos.latitude != 0.0 && pos.longitude != 0.0)
        ? LatLng(pos.latitude, pos.longitude)
        : const LatLng(21.0285, 105.8542); // Mặc định Hà Nội

    // Tạo danh sách điểm đo đã thu thập
    List<Marker> markers = [];
    List<LatLng> polylinePoints = [];

    for (var p in rtk.surveyPoints) {
      LatLng pt = LatLng(p.wgsLat, p.wgsLon);
      polylinePoints.add(pt);
      markers.add(
        Marker(
          point: pt,
          width: 40,
          height: 40,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(3)),
                child: Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 9)),
              ),
              const Icon(Icons.location_on, color: Colors.amberAccent, size: 20),
            ],
          ),
        ),
      );
    }

    // Thêm Marker cho vị trí Rover hiện tại
    if (pos.latitude != 0.0) {
      markers.add(
        Marker(
          point: currentCenter,
          width: 50,
          height: 50,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.cyanAccent.withOpacity(0.3),
                  border: Border.all(color: Colors.cyanAccent, width: 2),
                ),
              ),
              const Icon(Icons.gps_fixed, color: Colors.cyanAccent, size: 20),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: currentCenter,
              initialZoom: 17.0,
              maxZoom: 22.0,
            ),
            children: [
              // Lớp nền bản đồ vệ tinh độ nét cao Esri / Google Hybrid
              TileLayer(
                urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                userAgentPackageName: 'com.rtk.field',
                maxNativeZoom: 19,
              ),
              if (_connectLines && polylinePoints.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: polylinePoints,
                      color: Colors.redAccent,
                      strokeWidth: 2.5,
                    ),
                  ],
                ),
              MarkerLayer(markers: markers),
            ],
          ),

          // La bàn số định hướng ở góc trên trái
          Positioned(
            top: 40,
            left: 15,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24),
              ),
              child: Transform.rotate(
                angle: -pos.headingDegrees * (3.14159 / 180.0),
                child: const Icon(Icons.navigation, color: Colors.redAccent, size: 30),
              ),
            ),
          ),

          // Thanh HUD thông số vệ tinh ở đỉnh bản đồ
          Positioned(
            top: 40,
            right: 15,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xDD1B232F),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                children: [
                  Text(
                    "VT: ${pos.satellitesUsed} | HDOP: ${pos.hdop.toStringAsFixed(1)}",
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: pos.solutionText.contains("FIX") ? Colors.greenAccent : Colors.orangeAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bảng điều khiển dưới đáy: Nối Điểm, Tâm Vị Trí
          Positioned(
            bottom: 20,
            left: 15,
            right: 15,
            child: Row(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _connectLines ? Colors.orangeAccent : const Color(0xFF233040),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.timeline, size: 18),
                  label: Text(_connectLines ? "Bỏ Nối" : "Nối Điểm"),
                  onPressed: () => setState(() => _connectLines = !_connectLines),
                ),
                const Spacer(),
                FloatingActionButton.small(
                  backgroundColor: const Color(0xFF2E7D32),
                  child: const Icon(Icons.my_location, color: Colors.white),
                  onPressed: () {
                    if (pos.latitude != 0.0) {
                      _mapController.move(LatLng(pos.latitude, pos.longitude), 18.0);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
