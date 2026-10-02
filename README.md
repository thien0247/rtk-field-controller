# 🛰️ RTK Field Controller — Mobile Android App

> Ứng dụng di động Android chuyên dụng cho đo đạc trắc địa và điều khiển trạm Base/Rover RTK GNSS qua kết nối Bluetooth, tái hiện và nâng cấp toàn diện các tính năng của phần mềm thực địa **RTK Việt V3.7.8**.

---

## 🌟 Tính Năng Nổi Bật

1. **Chuyển Nhanh 1-Chạm Giữa Rover $\leftrightarrow$ Base $\leftrightarrow$ Đo Tĩnh:**
   - **Chế độ Rover**: Kết nối NTRIP Caster (qua 4G/WiFi) $\rightarrow$ kéo luồng RTCM nạp vào Bluetooth cho đầu thu giải mã RTK FIX.
   - **Chế độ Base (Trạm phát di động)**: Gửi lệnh `MODE BASE` xuống đầu thu $\rightarrow$ nhận RTCM từ Bluetooth $\rightarrow$ đóng vai NTRIP Server đẩy lên Caster với Mountpoint tùy chọn (vd: `tramdidong1`).
   - **Chế độ Đo GNSS Tĩnh**: Ghi luồng dữ liệu vệ tinh thô và đóng gói xuất tệp chuẩn **RINEX 2.11** phục vụ bình sai sau.
2. **Hỗ Trợ Đa Chipset GNSS:**
   - **Unicore Comm**: UM980, UM982, NebulasIV (lệnh ASCII: `MODE ROVER`, `MODE BASE TIME 60 2.5 3.5`, `SAVECONFIG`...).
   - **u-blox**: ZED-F9P, ZED-F9T (gói tin nhị phân UBX và PUBX).
3. **Biểu Đồ Vệ Tinh Trực Quan (Skyplot 360° Radar):**
   - Vẽ phân bố góc phương vị và độ cao vệ tinh trên nền Radar CustomPainter.
   - Phân biệt 4 chùm vệ tinh theo màu: GPS (Đỏ), GLONASS (Xanh dương), Galileo (Xanh lá), BeiDou (Cam).
4. **Bộ Tính Chuyển Tọa Độ Quốc Gia VN-2000 Đạt Chuẩn mm:**
   - Tích hợp sẵn cơ sở dữ liệu Kinh tuyến trục (KTT) của **63 tỉnh thành Việt Nam**.
   - Hỗ trợ múi chiếu $3^\circ$ (tỷ lệ $k_0 = 0.9999$) và $6^\circ$ ($k_0 = 0.9996$).
   - Thuật toán 7 tham số Bursa-Wolf và phép chiếu Gauss-Krüger chuẩn xác đến từng milimét.
5. **Bản Đồ Thực Địa GIS:**
   - Lớp bản đồ nền vệ tinh độ nét cao (Esri World Imagery / Google Hybrid).
   - Hiển thị vị trí thời gian thực của Rover, Base, các mốc đã đo.
   - La bàn số định hướng tìm điểm (Stakeout).
   - Nối điểm và đo khoảng cách/chu vi.
6. **Chạy Ngầm Liên Tục (Foreground Service):**
   - Đảm bảo trạm Base phát sóng cả ngày không bị hệ điều hành Android ngắt tiến trình khi tắt màn hình đút túi quần.

---

## 🏗️ Cấu Trúc Mã Nguồn

```
android-rtk-app/
├── pubspec.yaml               # Thư viện Flutter, GIS và Bluetooth
├── android/
│   └── app/src/main/
│       └── AndroidManifest.xml# Cấp quyền Bluetooth SPP, Network, Wakelock
└── lib/
    ├── main.dart              # Điều hướng 4 Tab chính
    ├── core/
    │   ├── constants/
    │   │   └── vn2000_provinces.dart  # Danh mục KTT 63 tỉnh thành
    │   ├── geodetic/
    │   │   ├── coordinate_models.dart # Model WGS84, VN2000, ECEF
    │   │   └── vn2000_engine.dart     # Thuật toán 7 tham số & Gauss-Krüger
    │   ├── gnss/
    │   │   ├── nmea_parser.dart       # Phân giải NMEA GGA, RMC, GSV cho Skyplot
    │   │   ├── gnss_commands.dart     # Kịch bản lệnh chuyển Base/Rover UM980/F9P
    │   │   └── rinex_logger.dart      # Đo tĩnh và xuất file RINEX 2.11
    │   ├── network/
    │   │   ├── ntrip_client.dart      # Client kéo RTCM từ Caster về nạp Bluetooth
    │   │   └── ntrip_server.dart      # Server đẩy RTCM từ Bluetooth lên Caster
    │   └── bluetooth/
    │       └── bluetooth_manager.dart # Quản lý kết nối Bluetooth SPP RFCOMM
    ├── providers/
    │   └── rtk_state_provider.dart    # State Management trung tâm
    └── ui/
        ├── widgets/
        │   ├── skyplot_widget.dart    # Canvas vẽ biểu đồ radar vệ tinh 360°
        │   ├── solution_badge.dart    # Badge FIX, FLOAT, D-GNSS, SINGLE
        │   └── terminal_console.dart  # Hộp log console thực địa
        └── screens/
            ├── rtk_survey_screen.dart # Tab 1: Đo RTK, Skyplot, HUD tọa độ
            ├── connections_screen.dart# Tab 2: Quản lý Bluetooth, Base, Đo tĩnh
            ├── map_survey_screen.dart # Tab 3: Bản đồ số vệ tinh, tìm điểm
            └── vn2000_screen.dart     # Tab 4: Tính chuyển tọa độ WGS84 <-> VN2000
```

---

## 🚀 Hướng Dẫn Biên Dịch & Chạy Ứng Dụng

### Yêu cầu môi trường:
- Flutter SDK $\ge 3.0.0$
- Android Studio / Android SDK (API 26 - 34)

### Các bước cài đặt:
1. Mở terminal tại thư mục `android-rtk-app`:
   ```bash
   cd e:\GoogleDrive\obsidian\zz\20-projects\ntrip-rtk-gnss\android-rtk-app
   flutter pub get
   ```
2. Kết nối điện thoại Android bật chế độ **USB Debugging** (hoặc mở máy ảo):
   ```bash
   flutter run -d <device_id>
   ```
3. Hoặc build file APK cài đặt trực tiếp vào điện thoại:
   ```bash
   flutter build apk --release
   ```
   File APK sẽ được tạo tại: `build/app/outputs/flutter-apk/app-release.apk`.
