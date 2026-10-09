# Receipt OCR & Expense Tracker (VKU) 🧾📱

Ứng dụng Flutter Android quản lý chi tiêu sinh viên & câu lạc bộ VKU bằng công nghệ nhận dạng hình ảnh **Google ML Kit OCR (On-Device)**, quét **Mã VietQR / EMVCo**, đọc ảnh chụp màn hình chuyển khoản ngân hàng và lưu trữ **SQLite Offline**.

---

## 🌟 Tính Năng Nổi Bật

### 1. 🧾 Nhận Dạng Hóa Đơn (Receipt OCR)
- **Chụp ảnh trực tiếp từ Camera** hoặc **chọn ảnh từ Thư viện**.
- Phân tích văn bản hóa đơn trực tiếp trên thiết bị với **Google ML Kit Text Recognition** (offline, tốc độ cao, bảo mật thông tin).
- Thuật toán `ReceiptParser` tự động bóc tách **Tên cửa hàng**, **Ngày thanh toán**, **Tổng tiền thanh toán**, **Thuế VAT** và **Giảm giá**.

### 2. 💳 Quét & Đọc Mã Thanh Toán (VietQR & EMVCo)
- **Quét trực tiếp qua Camera (Live QR Scanner)** hoặc **Tải ảnh mã QR từ thư viện**.
- Giải mã định dạng chuẩn **VietQR (Tag 38)** và **EMVCo (TLV format)** với kiểm tra mã checksum **CRC16-CCITT**.
- Phân tách ngân hàng thụ hưởng (Vietcombank, Techcombank, MBBank, TPBank, ...), số tài khoản, số tiền và nội dung chuyển khoản.

### 3. 📸 Nhận Dạng Ảnh Chụp Chuyển Khoản Ngân Hàng
- Phân tích văn bản ảnh chụp màn hình xác nhận chuyển khoản ngân hàng (Vietcombank, MB, Techcombank, MoMo, ...).
- Trích xuất mã giao dịch, số tài khoản nhận và số tiền thanh toán.

### 4. ✏️ Màn Hình Duyệt & Xác Minh Thông Tin (Review & Verification)
- Cho phép xem lại và chỉnh sửa số tiền, danh mục chi tiêu, ngày tháng, tên cửa hàng/đơn vị thụ hưởng trước khi lưu.
- Cảnh báo tính hợp lệ của mã QR hoặc tiền tố nghi ngờ.

### 5. 🗄️ Lưu Trữ SQLite Offline & Migration
- Cơ sở dữ liệu **SQLite** cục bộ trên thiết bị, hỗ trợ tự động nâng cấp schema (Database Migration v1 -> v2).
- Không yêu cầu kết nối internet hay tài khoản đăng nhập để sử dụng tính năng chính.

### 6. 📊 Thống Kê Chi Tiêu & Biểu Đồ Trực Quan (Analytics)
- Dashboard tổng quan chi tiêu theo tháng và tuần.
- 3 biểu đồ vẽ bằng `CustomPainter`:
  - **Biểu đồ xu hướng tháng (Monthly Trend Chart)**: Line / Area Chart mịn mạn.
  - **Biểu đồ phân loại danh mục (Category Pie/Donut Chart)**.
  - **Biểu đồ so sánh chi tiêu theo tuần (Weekly Bar Chart)**.

### 7. 📜 Lịch Sử & Tìm Kiếm Chi Tiêu
- Bội lọc chi tiêu đa dạng theo: Danh mục, Nguồn nhập (Hóa đơn OCR, Mã VietQR, Ảnh chuyển khoản, Nhập tay), Khoảng thời gian.
- Tìm kiếm tức thì theo tên cửa hàng, mô tả hoặc mã tham chiếu.

---

## 🛠 Yêu Cầu Môi Trường (Prerequisites)

- **Flutter SDK**: `>=3.19.0` (Dart SDK `>=3.3.0`)
- **Android SDK**: `minSdkVersion 21` (Android 5.0+), `targetSdkVersion 34+` (Đã hỗ trợ Android 16 / API 36)
- **Java**: Java 17+
- **Thiết bị thử nghiệm**: Đã kết nối điện thoại Android thật (bật USB Debugging) hoặc Android Emulator.

---

## 🚀 Hướng Dẫn Cài Đặt & Chạy Ứng Dụng

### Bước 1: Clone Repository & Di Chuyển Vào Thư Mục Dự Án
```bash
cd d:\Code\ocr_hoadon_flutter
```

### Bước 2: Cài Đặt Các Thư Viện Phụ Thuộc (Dependencies)
```bash
flutter pub get
```

### Bước 3: Kiểm Tra Môi Trường & Thiết Bị Kết Nối
```bash
flutter doctor -v
flutter devices
```

### Bước 4: Kiểm Tra Mã Nguồn (Static Analysis) & Chạy Test Suite
```bash
flutter analyze
flutter test
```

### Bước 5: Chạy Ứng Dụng Trực Tiếp Trên Điện Thoại / Emulator
```bash
flutter run
```

---

## 📦 Hướng Dẫn Build Android APK

### 1. Build Debug APK
```bash
flutter build apk --debug
```
📌 **Đường dẫn APK đầu ra:**
`build/app/outputs/flutter-apk/app-debug.apk`

### 2. Cài Đặt Trực Tiếp Vào Điện Thoại Android Qua ADB
```bash
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

---

## 📁 Cấu Trúc Dự Án (Project Architecture)

```
lib/
├── core/                  # Constants, theme, và utilities (Currency/Date formatters)
├── data/                  # Models (Expense, OcrResult, QrResult) & SQLite Database / Repositories
├── services/              # ML Kit OCR Service, ReceiptParser, VietQR Parser, PaymentScreenshot OCR
├── features/
│   ├── dashboard/         # Màn hình chính Dashboard
│   ├── capture_receipt/   # Camera & Chọn ảnh Hóa đơn
│   ├── receipt_review/    # Duyệt & chỉnh sửa thông tin OCR/QR
│   ├── qr_payment/        # Quét QR trực tiếp & Danh sách QR mẫu
│   ├── expense_history/   # Màn hình danh sách & bộ lọc chi tiêu
│   ├── expense_detail/    # Xem chi tiết & Chỉnh sửa / Xóa chi tiêu
│   ├── analytics/         # Thống kê & Biểu đồ CustomPainter
│   └── settings/          # Cài đặt, Tạo dữ liệu giả lập & Xóa dữ liệu
└── widgets/               # Components dùng chung (ExpenseCard, SourceBadge, CustomButtons)
```

---

## 📜 Giấy Phép & Thông Tin Dự Án
- **Application ID:** `com.vku.receipttracker`
- **Đơn vị phát triển:** VKU Student Project
