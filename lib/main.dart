import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/rtk_state_provider.dart';
import 'ui/screens/connections_screen.dart';
import 'ui/screens/map_survey_screen.dart';
import 'ui/screens/rtk_survey_screen.dart';
import 'ui/screens/vn2000_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RtkStateProvider()),
      ],
      child: const RtkFieldApp(),
    ),
  );
}

class RtkFieldApp extends StatelessWidget {
  const RtkFieldApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RTK Field Controller',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF1E88E5),
        scaffoldBackgroundColor: const Color(0xFF10141C),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF1E88E5),
          secondary: Color(0xFF00E5FF),
          surface: Color(0xFF1A222F),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1F2937),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    RtkSurveyScreen(),
    ConnectionsScreen(),
    MapSurveyScreen(),
    Vn2000Screen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        backgroundColor: const Color(0xFF18202C),
        indicatorColor: const Color(0xFF1E88E5).withOpacity(0.3),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.satellite_alt_outlined),
            selectedIcon: Icon(Icons.satellite_alt, color: Color(0xFF00E5FF)),
            label: 'Đo RTK',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_input_antenna_outlined),
            selectedIcon: Icon(Icons.settings_input_antenna, color: Colors.orangeAccent),
            label: 'Kết Nối & Base',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map, color: Colors.greenAccent),
            label: 'Bản Đồ',
          ),
          NavigationDestination(
            icon: Icon(Icons.calculate_outlined),
            selectedIcon: Icon(Icons.calculate, color: Colors.amberAccent),
            label: 'Tọa Độ VN2K',
          ),
        ],
      ),
    );
  }
}
