# HoàngHa - Ứng dụng YouTube cho iOS

Ứng dụng YouTube dành cho iOS với giao diện YouTube Clone chân thực kết hợp cùng bộ nhân phát video và tìm kiếm từ FreeTube (YouTubeKit & AVPlayer).

---

## Tính năng nổi bật

- **Giao diện YouTube Clone nguyên bản**:
  - Giao diện Dark theme đặc trưng với màu sắc và icon chuẩn của YouTube.
  - Thanh điều hướng trên cùng (Topbar) với nhận diện thương hiệu **HoàngHa**, nút Cast, Thông báo, Tìm kiếm và Avatar.
  - Thanh Bottom Tab Bar 5 tab: **Trang chủ**, **Shorts**, **Tạo (+)**, **Kênh đăng ký**, **Bạn (Thư viện)**.
  - Thẻ video (Video Card) tỉ lệ 16:9 với huy hiệu thời lượng, avatar kênh, tiêu đề 2 dòng và số lượt xem / thời gian đăng tải.
  - Thanh cuộn video ngắn (Shorts shelf).
  
- **Tìm kiếm thật (Real Search)**:
  - Tự động gợi ý từ khóa khi gõ (Autocomplete suggestions).
  - Lưu và quản lý lịch sử tìm kiếm gần đây trên thiết bị.
  - Danh sách kết quả video thật, tải thêm khi cuộn trang (Infinite scroll).
  - Chạm vào video bất kỳ để phát ngay lập tức.

- **Xem video thật mượt mà (Real Playback)**:
  - Trình phát video mạnh mẽ tích hợp AVPlayer.
  - Sử dụng client TVHTML5 để lấy stream trực tiếp, tự động vượt qua hệ thống Proof-of-Origin-Token của YouTube (không bị lỗi 403 Forbidden).
  - Mini-player nổi phía trên thanh Tab Bar với thanh tiến trình mỏng và các nút điều khiển.
  - Kéo lên để mở trình phát toàn màn hình (Full-Screen Player) với đầy đủ điều khiển tua, chất lượng, âm thanh nền.

- **Hoàn toàn không cần đăng nhập**:
  - 100% ẩn danh, bảo vệ quyền riêng tư.
  - Không có popup bắt buộc đăng nhập, không có WebView Google login phiền toái.
  - Lịch sử xem và video yêu thích được lưu trữ cục bộ trên thiết bị qua SwiftData.

- **Tự động build IPA qua GitHub Actions**:
  - Tự động biên dịch và xuất file `HoangHa.ipa` mỗi khi push code hoặc kích hoạt thủ công.
  - Sẵn sàng cài đặt sideload qua TrollStore, SideStore, AltStore, Sideloadly, Scarlet, Esign.

---

## Hướng dẫn tải và cài đặt file IPA

### 1. Tải file IPA từ GitHub Actions
1. Truy cập tab **Actions** trên repository GitHub.
2. Chọn lượt chạy workflow mới nhất (**Build HoangHa IPA**).
3. Cuộn xuống phần **Artifacts** và tải về file **HoangHa-iOS-IPA** (chứa file `HoangHa.ipa`).

### 2. Cài đặt vào iPhone / iPad
- **TrollStore** (Khuyên dùng cho máy có hỗ trợ): Mở file `.ipa` trong TrollStore để cài đặt vĩnh viễn không cần ký lại.
- **SideStore / AltStore**: Cài đặt thông qua kết nối máy tính hoặc Wi-Fi.
- **Scarlet / Esign / Sideloadly**: Ký chứng chỉ cá nhân hoặc chứng chỉ doanh nghiệp để cài đặt trực tiếp trên thiết bị.
