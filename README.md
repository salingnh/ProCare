# NEWS2-L
Tác giả: Sang Nguyễn
Email: sangnvnkl@gmail.com

Ứng dụng NEWS2-L: Đánh giá tình trạng sức khỏe cho bệnh nhân.

## Kiến trúc hiện tại

Ứng dụng đang được rewrite sang Flutter/Dart để dùng chung codebase cho Android trước và mở rộng iOS sau. Đường build chính là Flutter ở root repo:

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

Thư mục Android Java cũ vẫn còn trong repo để đối chiếu trong giai đoạn chuyển đổi, nhưng workflow release mới build APK từ Flutter project.

## Ký APK release trên GitHub Actions

Workflow release cần 4 GitHub Actions secrets khớp chính xác với keystore dùng để ký APK:

- `SIGNING_KEY_BASE64`: nội dung file keystore `.jks` đã encode base64.
- `KEY_STORE_PASSWORD`: mật khẩu mở keystore.
- `KEY_ALIAS`: alias của key bên trong keystore.
- `KEY_PASSWORD`: mật khẩu của key tương ứng với alias.

Nếu GitHub Actions báo lỗi dạng `No key with alias ... found in keystore`, nguyên nhân là secret `KEY_ALIAS` không trùng với alias thật trong file keystore được lưu ở `SIGNING_KEY_BASE64`. Kiểm tra alias trên máy local bằng lệnh:

```bash
keytool -list -v -keystore release.jks
```

Sau đó cập nhật lại secret `KEY_ALIAS` đúng với giá trị alias được liệt kê. Khi tạo/cập nhật `SIGNING_KEY_BASE64`, dùng lệnh sau để tránh thêm ký tự xuống dòng thừa:

```bash
base64 -w 0 release.jks
```
