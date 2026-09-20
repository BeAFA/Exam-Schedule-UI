# Exam-Schedule-UI

Giao diện người dùng cho hệ thống quản lý lớp học phần và lịch thi, được xây dựng bằng Flutter. Ứng dụng hỗ trợ nhiều vai trò người dùng như quản trị viên, giảng viên và sinh viên.

## Giới thiệu

`Exam-Schedule-UI` là phần giao diện frontend của hệ thống quản lý lịch thi. Ứng dụng cung cấp các màn hình và chức năng phục vụ việc quản lý kỳ thi, lớp học phần, lịch thi, giảng viên coi thi và thông tin cá nhân.

Dự án nằm trong thư mục `ui/` và được phát triển chủ yếu bằng Dart/Flutter.

## Tính năng chính

### Xác thực người dùng

- Đăng nhập vào hệ thống.
- Phân quyền theo vai trò người dùng.
- Gửi yêu cầu xác thực thông qua API.
- Lưu trữ token đăng nhập an toàn bằng `flutter_secure_storage`.
- Hiển thị màn hình khởi động và điều hướng đến màn hình phù hợp.

### Quản trị viên

- Xem trang tổng quan quản trị.
- Tạo và quản lý kỳ thi.
- Tạo và quản lý lớp học phần.
- Phân công giảng viên cho lớp học phần.
- Phân công giảng viên coi thi.
- Xem lịch thi theo ngày.
- Xem lịch thi theo tuần.
- Quản lý các thông tin liên quan đến môn học, phòng thi và lịch thi.

### Giảng viên

- Truy cập trang tổng quan dành cho giảng viên.
- Xem các thông tin lớp học phần và lịch được phân công.
- Theo dõi lịch giảng dạy hoặc lịch coi thi.

### Sinh viên

- Truy cập trang tổng quan dành cho sinh viên.
- Xem lịch thi và các thông tin liên quan đến môn học.
- Theo dõi lịch học/lịch thi cá nhân.

### Thông tin cá nhân

- Xem thông tin hồ sơ người dùng.
- Quản lý các thông tin cá nhân trong phạm vi được hệ thống hỗ trợ.

## Công nghệ sử dụng

- **Flutter**: Framework phát triển ứng dụng đa nền tảng.
- **Dart**: Ngôn ngữ lập trình chính.
- **Material Design**: Hệ thống giao diện và thành phần UI.
- **HTTP**: Giao tiếp với backend API.
- **flutter_secure_storage**: Lưu trữ token và dữ liệu nhạy cảm trên thiết bị.
- **flutter_lints**: Kiểm tra và duy trì chất lượng mã nguồn.

## Yêu cầu môi trường

Trước khi chạy dự án, cần cài đặt:

- Flutter SDK.
- Dart SDK tương thích với Flutter.
- Android Studio hoặc Visual Studio Code cùng Flutter Extension.
- Thiết bị Android/iOS, trình giả lập hoặc nền tảng desktop/web được Flutter hỗ trợ.

Phiên bản Dart SDK được khai báo trong dự án:

```text
^3.11.3
```

## Cài đặt và chạy dự án

Clone repository:

```bash
git clone https://github.com/BeAFA/Exam-Schedule-UI.git
cd Exam-Schedule-UI/ui
```

Cài đặt các thư viện phụ thuộc:

```bash
flutter pub get
```

Kiểm tra môi trường Flutter:

```bash
flutter doctor
```

Chạy ứng dụng:

```bash
flutter run
```

Để chạy trên một thiết bị hoặc nền tảng cụ thể, có thể sử dụng:

```bash
flutter devices
flutter run -d <device-id>
```

## Build ứng dụng

Build ứng dụng Android:

```bash
flutter build apk
```

Build ứng dụng iOS:

```bash
flutter build ios
```

Build phiên bản web:

```bash
flutter build web
```

Build ứng dụng Windows:

```bash
flutter build windows
```

Các nền tảng build thực tế có thể yêu cầu cài đặt thêm công cụ và cấu hình riêng theo tài liệu Flutter.

## Cấu trúc thư mục

```text
Exam-Schedule-UI/
├── LICENSE
├── README.md
├── ui/
│   ├── android/                 # Cấu hình và mã nguồn nền tảng Android
│   ├── ios/                     # Cấu hình và mã nguồn nền tảng iOS
│   ├── linux/                   # Cấu hình nền tảng Linux
│   ├── macos/                   # Cấu hình nền tảng macOS
│   ├── web/                     # Cấu hình nền tảng Web
│   ├── windows/                 # Cấu hình nền tảng Windows
│   ├── lib/
│   │   ├── main.dart            # Điểm khởi chạy ứng dụng
│   │   ├── app/
│   │   │   ├── router.dart      # Điều hướng và màn hình khởi đầu
│   │   │   └── screen/
│   │   │       ├── admin_screen/
│   │   │       ├── student_screen/
│   │   │       ├── teacher_screen/
│   │   │       ├── login_screen.dart
│   │   │       ├── profile_screen.dart
│   │   │       └── splash_screen.dart
│   │   ├── core/
│   │   │   ├── models/           # Các model dữ liệu dùng chung
│   │   │   └── token_storage.dart
│   │   └── features/
│   │       └── auth/             # API và logic xác thực
│   ├── test/                     # Mã kiểm thử
│   ├── pubspec.yaml              # Khai báo package và dependency
│   ├── analysis_options.yaml     # Cấu hình phân tích mã nguồn
│   └── README.md
└── .gitignore
```

## Kiến trúc mã nguồn

Mã nguồn được chia thành các nhóm chính:

- `lib/app`: Chứa cấu hình ứng dụng, router và các màn hình giao diện.
- `lib/core`: Chứa những thành phần dùng chung như model dữ liệu và tiện ích lưu trữ token.
- `lib/core/models`: Chứa các model như kỳ thi, lịch thi, phòng thi, môn học, lớp học phần, hồ sơ và phân công coi thi.
- `lib/features/auth`: Chứa API và logic liên quan đến đăng nhập/xác thực.
- `lib/main.dart`: Khởi tạo ứng dụng Flutter và cấu hình giao diện Material.

Ứng dụng khởi động từ `SplashScreen`, sau đó điều hướng người dùng dựa trên trạng thái đăng nhập và vai trò tài khoản.

## Kết nối backend

Đây là dự án giao diện nên cần có backend API tương ứng để cung cấp dữ liệu thực tế. Ứng dụng sử dụng package `http` để gửi request và `flutter_secure_storage` để lưu token xác thực.

Trước khi chạy đầy đủ các chức năng, cần kiểm tra:

- Địa chỉ API backend được cấu hình chính xác.
- Backend đang hoạt động và có thể truy cập từ thiết bị chạy ứng dụng.
- Token và cơ chế xác thực giữa frontend và backend tương thích.
- Các endpoint quản lý kỳ thi, lịch thi, lớp học phần và người dùng đã được triển khai.

## Kiểm thử và phân tích mã nguồn

Chạy bộ kiểm thử Flutter:

```bash
flutter test
```

Phân tích mã nguồn:

```bash
flutter analyze
```

## Đóng góp

Nếu muốn đóng góp cho dự án:

1. Fork repository.
2. Tạo một branch mới cho thay đổi của bạn.
3. Cài đặt dependency và kiểm tra mã nguồn bằng `flutter analyze`.
4. Bổ sung hoặc cập nhật test nếu cần.
5. Tạo Pull Request với mô tả rõ ràng về thay đổi.

## License

Dự án được phát hành theo giấy phép MIT. Vui lòng xem file [LICENSE](LICENSE) để biết thêm chi tiết.
