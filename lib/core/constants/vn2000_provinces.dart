/// Bảng danh mục Kinh Tuyến Trục (KTT) của 63 Tỉnh/Thành phố Việt Nam
/// Chuẩn Quy định của Bộ Tài nguyên và Môi trường (Thông tư 25/2014/TT-BTNMT & Quyết định 05/2007/QĐ-BTNMT)

class ProvinceKTT {
  final String name;
  final double kttDegree;
  final String kttString;

  const ProvinceKTT({
    required this.name,
    required this.kttDegree,
    required this.kttString,
  });
}

class VN2000Provinces {
  static const List<ProvinceKTT> provinces = [
    ProvinceKTT(name: "An Giang", kttDegree: 104.5, kttString: "104°30'"),
    ProvinceKTT(name: "Bà Rịa - Vũng Tàu", kttDegree: 107.0, kttString: "107°00'"),
    ProvinceKTT(name: "Bắc Giang", kttDegree: 107.0, kttString: "107°00'"),
    ProvinceKTT(name: "Bắc Kạn", kttDegree: 106.5, kttString: "106°30'"),
    ProvinceKTT(name: "Bạc Liêu", kttDegree: 105.0, kttString: "105°00'"),
    ProvinceKTT(name: "Bắc Ninh", kttDegree: 105.5, kttString: "105°30'"),
    ProvinceKTT(name: "Bến Tre", kttDegree: 106.0, kttString: "106°00'"),
    ProvinceKTT(name: "Bình Định", kttDegree: 108.25, kttString: "108°15'"),
    ProvinceKTT(name: "Bình Dương", kttDegree: 106.25, kttString: "106°15'"),
    ProvinceKTT(name: "Bình Phước", kttDegree: 106.25, kttString: "106°15'"),
    ProvinceKTT(name: "Bình Thuận", kttDegree: 107.5, kttString: "107°30'"),
    ProvinceKTT(name: "Cà Mau", kttDegree: 104.5, kttString: "104°30'"),
    ProvinceKTT(name: "Cần Thơ", kttDegree: 105.0, kttString: "105°00'"),
    ProvinceKTT(name: "Cao Bằng", kttDegree: 105.75, kttString: "105°45'"),
    ProvinceKTT(name: "Đà Nẵng", kttDegree: 107.75, kttString: "107°45'"),
    ProvinceKTT(name: "Đắk Lắk", kttDegree: 108.5, kttString: "108°30'"),
    ProvinceKTT(name: "Đắk Nông", kttDegree: 108.5, kttString: "108°30'"),
    ProvinceKTT(name: "Điện Biên", kttDegree: 103.0, kttString: "103°00'"),
    ProvinceKTT(name: "Đồng Nai", kttDegree: 107.75, kttString: "107°45'"),
    ProvinceKTT(name: "Đồng Tháp", kttDegree: 105.0, kttString: "105°00'"),
    ProvinceKTT(name: "Gia Lai", kttDegree: 108.5, kttString: "108°30'"),
    ProvinceKTT(name: "Hà Giang", kttDegree: 105.5, kttString: "105°30'"),
    ProvinceKTT(name: "Hà Nam", kttDegree: 105.5, kttString: "105°30'"),
    ProvinceKTT(name: "Hà Nội", kttDegree: 105.0, kttString: "105°00'"),
    ProvinceKTT(name: "Hà Tĩnh", kttDegree: 105.5, kttString: "105°30'"),
    ProvinceKTT(name: "Hải Dương", kttDegree: 105.5, kttString: "105°30'"),
    ProvinceKTT(name: "Hải Phòng", kttDegree: 106.0, kttString: "106°00'"),
    ProvinceKTT(name: "Hậu Giang", kttDegree: 105.0, kttString: "105°00'"),
    ProvinceKTT(name: "Hòa Bình", kttDegree: 106.0, kttString: "106°00'"),
    ProvinceKTT(name: "Hưng Yên", kttDegree: 105.5, kttString: "105°30'"),
    ProvinceKTT(name: "Khánh Hòa", kttDegree: 108.25, kttString: "108°15'"),
    ProvinceKTT(name: "Kiên Giang", kttDegree: 104.5, kttString: "104°30'"),
    ProvinceKTT(name: "Kon Tum", kttDegree: 107.5, kttString: "107°30'"),
    ProvinceKTT(name: "Lai Châu", kttDegree: 103.0, kttString: "103°00'"),
    ProvinceKTT(name: "Lâm Đồng", kttDegree: 107.75, kttString: "107°45'"),
    ProvinceKTT(name: "Lạng Sơn", kttDegree: 106.5, kttString: "106°30'"),
    ProvinceKTT(name: "Lào Cai", kttDegree: 104.75, kttString: "104°45'"),
    ProvinceKTT(name: "Long An", kttDegree: 105.75, kttString: "105°45'"),
    ProvinceKTT(name: "Nam Định", kttDegree: 105.5, kttString: "105°30'"),
    ProvinceKTT(name: "Nghệ An", kttDegree: 104.75, kttString: "104°45'"),
    ProvinceKTT(name: "Ninh Bình", kttDegree: 105.0, kttString: "105°00'"),
    ProvinceKTT(name: "Ninh Thuận", kttDegree: 108.25, kttString: "108°15'"),
    ProvinceKTT(name: "Phú Thọ", kttDegree: 104.5, kttString: "104°30'"),
    ProvinceKTT(name: "Phú Yên", kttDegree: 108.5, kttString: "108°30'"),
    ProvinceKTT(name: "Quảng Bình", kttDegree: 106.0, kttString: "106°00'"),
    ProvinceKTT(name: "Quảng Nam", kttDegree: 107.75, kttString: "107°45'"),
    ProvinceKTT(name: "Quảng Ngãi", kttDegree: 108.0, kttString: "108°00'"),
    ProvinceKTT(name: "Quảng Ninh", kttDegree: 107.75, kttString: "107°45'"),
    ProvinceKTT(name: "Quảng Trị", kttDegree: 106.25, kttString: "106°15'"),
    ProvinceKTT(name: "Sóc Trăng", kttDegree: 105.5, kttString: "105°30'"),
    ProvinceKTT(name: "Sơn La", kttDegree: 104.0, kttString: "104°00'"),
    ProvinceKTT(name: "Tây Ninh", kttDegree: 105.5, kttString: "105°30'"),
    ProvinceKTT(name: "Thái Bình", kttDegree: 105.5, kttString: "105°30'"),
    ProvinceKTT(name: "Thái Nguyên", kttDegree: 105.75, kttString: "105°45'"),
    ProvinceKTT(name: "Thanh Hóa", kttDegree: 105.0, kttString: "105°00'"),
    ProvinceKTT(name: "Thừa Thiên Huế", kttDegree: 107.0, kttString: "107°00'"),
    ProvinceKTT(name: "Tiền Giang", kttDegree: 105.75, kttString: "105°45'"),
    ProvinceKTT(name: "TP. Hồ Chí Minh", kttDegree: 105.75, kttString: "105°45'"),
    ProvinceKTT(name: "Trà Vinh", kttDegree: 105.75, kttString: "105°45'"),
    ProvinceKTT(name: "Tuyên Quang", kttDegree: 106.0, kttString: "106°00'"),
    ProvinceKTT(name: "Vĩnh Long", kttDegree: 105.5, kttString: "105°30'"),
    ProvinceKTT(name: "Vĩnh Phúc", kttDegree: 105.0, kttString: "105°00'"),
    ProvinceKTT(name: "Yên Bái", kttDegree: 104.75, kttString: "104°45'"),
  ];

  static ProvinceKTT findByName(String name) {
    return provinces.firstWhere(
      (p) => p.name.toLowerCase().contains(name.toLowerCase()),
      orElse: () => provinces[23], // Mặc định Hà Nội 105°00'
    );
  }
}
