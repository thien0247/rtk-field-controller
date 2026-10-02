import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:provider/provider.dart';

import '../../core/bluetooth/bluetooth_manager.dart';
import '../../core/gnss/gnss_commands.dart';
import '../../providers/rtk_state_provider.dart';
import '../widgets/terminal_console.dart';

class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({Key? key}) : super(key: key);

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen> {
  // Form Caster
  final TextEditingController _ipController = TextEditingController(text: "157.20.83.130");
  final TextEditingController _portController = TextEditingController(text: "2101");
  final TextEditingController _mountController = TextEditingController(text: "tramdidong1");
  final TextEditingController _userController = TextEditingController(text: "source");
  final TextEditingController _passController = TextEditingController(text: "2rtk_pass");

  // Form Đo Tĩnh
  final TextEditingController _staticPointController = TextEditingController(text: "Base389");
  final TextEditingController _staticObserverController = TextEditingController(text: "B102");
  final TextEditingController _staticHeightController = TextEditingController(text: "1.500");
  int _staticIntervalSec = 1;

  // Form Tâm pha
  late TextEditingController _apcController;

  List<BluetoothDevice> _pairedDevices = [];
  BluetoothDevice? _selectedDevice;

  @override
  void initState() {
    super.initState();
    final rtk = context.read<RtkStateProvider>();
    _apcController = TextEditingController(text: rtk.apcOffset.toStringAsFixed(4));
    _loadPairedBluetooth();
  }

  Future<void> _loadPairedBluetooth() async {
    final rtk = context.read<RtkStateProvider>();
    List<BluetoothDevice> devs = await rtk.bluetoothManager.getBondedDevices();
    setState(() {
      _pairedDevices = devs;
      if (devs.isNotEmpty) _selectedDevice = devs.first;
    });
  }

  @override
  Widget build(BuildContext context) {
    final rtk = context.watch<RtkStateProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF121820),
      appBar: AppBar(
        title: const Text("Thiết Lập Kết Nối & Trạm Base", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFF1E2836),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Quét lại Bluetooth",
            onPressed: _loadPairedBluetooth,
          ),
          IconButton(
            icon: const Icon(Icons.restart_alt, color: Colors.amberAccent),
            tooltip: "Reset mềm đầu thu",
            onPressed: () async {
              List<String> cmds = GnssCommands.getResetCommands(rtk.chipset);
              await rtk.bluetoothManager.sendCommandList(cmds);
              rtk.addLog("Đã gửi lệnh Reset mềm xuống đầu thu GNSS");
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Khối Kết Nối Bluetooth
            _buildBluetoothSection(rtk),
            const SizedBox(height: 12),

            // 2. Khối Chế độ Phát Base (NTRIP Server)
            _buildBaseBroadcasterSection(rtk),
            const SizedBox(height: 12),

            // 3. Khối Đo GNSS Tĩnh (RINEX 2.11)
            _buildStaticSurveySection(rtk),
            const SizedBox(height: 12),

            // 4. Khối Log Terminal Đen
            const Text("Nhật Ký Lệnh & Dữ Liệu Thời Gian Thực:", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TerminalConsole(logs: rtk.consoleLogs, height: 130),
          ],
        ),
      ),
    );
  }

  Widget _buildBluetoothSection(RtkStateProvider rtk) {
    return Card(
      color: const Color(0xFF1B222D),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bluetooth_connected,
                  color: rtk.isBluetoothConnected ? Colors.greenAccent : Colors.grey,
                  size: 22,
                ),
                const SizedBox(width: 8),
                const Text("Đầu Thu GNSS (Bluetooth SPP)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                const Spacer(),
                Text(
                  "${(rtk.bluetoothManager.bytesCount / 1024).toStringAsFixed(1)} KB",
                  style: const TextStyle(color: Colors.cyanAccent, fontFamily: 'monospace', fontSize: 12),
                ),
              ],
            ),
            const Divider(color: Colors.white12, height: 16),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<BluetoothDevice>(
                    isExpanded: true,
                    dropdownColor: const Color(0xFF232D3B),
                    value: _selectedDevice,
                    decoration: const InputDecoration(
                      labelText: "Chọn thiết bị",
                      labelStyle: TextStyle(color: Colors.white70, fontSize: 12),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    items: _pairedDevices.map((d) {
                      return DropdownMenuItem(
                        value: d,
                        child: Text(
                          "${d.name ?? 'GNSS'} (${d.address})",
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedDevice = val),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: _btnStyle(
                    rtk.isBluetoothConnected ? Colors.redAccent : Colors.blueAccent,
                  ),
                  onPressed: () {
                    if (rtk.isBluetoothConnected) {
                      rtk.bluetoothManager.disconnect();
                    } else if (_selectedDevice != null) {
                      rtk.bluetoothManager.connect(_selectedDevice!);
                    }
                  },
                  child: Text(rtk.isBluetoothConnected ? "Ngắt" : "Kết Nối"),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _apcController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: "Tâm Pha Offset (m)",
                      labelStyle: TextStyle(color: Colors.white70, fontSize: 11),
                      isDense: true,
                    ),
                    onSubmitted: (v) {
                      double? val = double.tryParse(v);
                      if (val != null) rtk.setApcOffset(val);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<GnssChipset>(
                    dropdownColor: const Color(0xFF232D3B),
                    value: rtk.chipset,
                    decoration: const InputDecoration(
                      labelText: "Dòng Chipset",
                      labelStyle: TextStyle(color: Colors.white70, fontSize: 11),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: GnssChipset.unicoreUM980, child: Text("Unicore UM980", style: TextStyle(color: Colors.white, fontSize: 13))),
                      DropdownMenuItem(value: GnssChipset.ubloxZEDF9P, child: Text("u-blox ZED-F9P", style: TextStyle(color: Colors.white, fontSize: 13))),
                    ],
                    onChanged: (v) {
                      if (v != null) rtk.setChipset(v);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBaseBroadcasterSection(RtkStateProvider rtk) {
    bool isBase = rtk.mode == OperatingMode.base && rtk.isCasterConnected;

    return Card(
      color: const Color(0xFF1B222D),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cell_tower, color: Colors.orangeAccent, size: 22),
                const SizedBox(width: 8),
                const Text("Chế Độ Phát Base (NTRIP Server)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isBase ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: isBase ? Colors.greenAccent : Colors.grey),
                  ),
                  child: Text(
                    isBase ? "ĐANG PHÁT BASE" : "CHỜ PHÁT",
                    style: TextStyle(color: isBase ? Colors.greenAccent : Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white12, height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _ipController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(labelText: "IP Caster", isDense: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _portController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(labelText: "Cổng", isDense: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _mountController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(labelText: "Mount Point", isDense: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _passController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(labelText: "Mật khẩu Caster (Source Pass)", isDense: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  style: _btnStyle(
                    isBase ? Colors.red.shade700 : const Color(0xFFE65100),
                  ),
                  icon: Icon(isBase ? Icons.stop_circle : Icons.wifi_tethering),
                  label: Text(
                    isBase ? "DỪNG TRẠM PHÁT BASE" : "BẮT ĐẦU PHÁT BASE DI ĐỘNG (1-CHẠM)",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  onPressed: () {
                    if (isBase) {
                      // Dừng phát và quay về Rover
                      rtk.switchToRoverMode(
                        host: _ipController.text,
                        port: int.tryParse(_portController.text) ?? 2101,
                        mountpoint: _mountController.text,
                      );
                    } else {
                      // Kích hoạt phát Base
                      rtk.switchToBaseMode(
                        host: _ipController.text,
                        port: int.tryParse(_portController.text) ?? 2101,
                        mountpoint: _mountController.text,
                        password: _passController.text,
                        isSurveyIn: true,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget _buildStaticSurveySection(RtkStateProvider rtk) {
      bool isStatic = rtk.mode == OperatingMode.staticSurvey;

      return Card(
        color: const Color(0xFF1B222D),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.save_alt, color: Colors.cyanAccent, size: 22),
                  const SizedBox(width: 8),
                  const Text("Đo GNSS Tĩnh (Xuất File RINEX 2.11)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  const Spacer(),
                  if (isStatic)
                    Text(
                      "${rtk.staticSession?.epochCount ?? 0} Epochs",
                      style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                ],
              ),
              const Divider(color: Colors.white12, height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _staticPointController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(labelText: "Tên Điểm (Base389)", isDense: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _staticObserverController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(labelText: "Người Đo (B102)", isDense: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _staticHeightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(labelText: "Chiều Cao Mốc (m)", isDense: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton.icon(
                  style: _btnStyle(
                    isStatic ? Colors.red.shade700 : const Color(0xFF00838F),
                  ),
                  icon: Icon(isStatic ? Icons.stop : Icons.fiber_manual_record),
                  label: Text(
                    isStatic ? "DỪNG ĐO TĨNH & XUẤT FILE RINEX" : "BẮT ĐẦU ĐO GNSS TĨNH",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    if (isStatic) {
                      rtk.stopStaticSurvey(
                        defaultHost: _ipController.text,
                        defaultPort: int.tryParse(_portController.text) ?? 2101,
                        defaultMount: _mountController.text,
                      );
                    } else {
                      double h = double.tryParse(_staticHeightController.text) ?? 1.5;
                      rtk.startStaticSurvey(
                        pointName: _staticPointController.text,
                        observer: _staticObserverController.text,
                        antennaHeight: h,
                        epochIntervalSec: _staticIntervalSec,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  ButtonStyle _btnStyle(Color color) {
    return ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    );
  }
