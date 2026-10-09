class SampleQrItem {
  final String id;
  final String title;
  final String description;
  final String payload;
  final int defaultAmount;

  const SampleQrItem({
    required this.id,
    required this.title,
    required this.description,
    required this.payload,
    required this.defaultAmount,
  });
}

class SampleQrs {
  /// Synthetic VietQR & EMVCo sample payloads (No real personal bank details embedded)
  static const List<SampleQrItem> samples = [
    SampleQrItem(
      id: 'vku_canteen',
      title: 'Căn tin VKU - Cơm Trưa Sinh Viên',
      description: 'Mã VietQR thanh toán 35.000 VNĐ tại Căn tin Trường VKU',
      payload: '00020101021238580010A000000727012800069704070114970407000000010208QRIBFTTA53037045405350005802VN62270823Thanh toan com trua VKU6304ACDB',
      defaultAmount: 35000,
    ),
    SampleQrItem(
      id: 'vku_club_fee',
      title: 'Quỹ Câu lạc bộ IT VKU',
      description: 'Mã VietQR đóng quỹ CLB IT tháng 10 - 50.000 VNĐ',
      payload: '00020101021238580010A000000727012800069704230114970423000099990208QRIBFTTA53037045405500005802VN62230819Dong quy CLB IT VKU6304101F',
      defaultAmount: 50000,
    ),
    SampleQrItem(
      id: 'vku_printing',
      title: 'Tiệm In Ấn Giáo Trình VKU',
      description: 'Mã VietQR thanh toán in tài liệu - 120.000 VNĐ',
      payload: '00020101021238580010A000000727012800069704150114970415000012340208QRIBFTTA530370454061200005802VN62270823In tai lieu hoap trinh VKU63043429',
      defaultAmount: 120000,
    ),
    SampleQrItem(
      id: 'emvco_generic',
      title: 'Cửa Hàng Tiện Lợi (EMVCo QR)',
      description: 'Mã QR thanh toán 85.000 VNĐ tại Minimart',
      payload: '00020101021138400010A0000007270118VIETQR_MERCHANT_0153037045405850005802VN6304DF0D',
      defaultAmount: 85000,
    ),
  ];
}
