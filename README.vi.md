# MacStats 📊

> Một trình theo dõi trạng thái Thanh Menu macOS gọn nhẹ và thuần bản địa được xây dựng bằng Swift. Xem nhanh mức sử dụng CPU thời gian thực, thông số RAM, tốc độ Mạng và nhiệt độ CPU.

🌐 [English](README.md) | [Tiếng Việt](README.vi.md) | [简体中文](README.zh.md) | [日本語](README.ja.md)

![macOS 11.0+](https://img.shields.io/badge/macOS-11.0%2B-blue?logo=apple)
![Swift](https://img.shields.io/badge/Swift-5.0-orange?logo=swift)
![License](https://img.shields.io/badge/License-MIT-green)

---

## ⚡ Bắt đầu nhanh

### 📦 Tải xuống & Cài đặt bằng 1 câu lệnh
Chạy câu lệnh duy nhất này trong Terminal của bạn để tải xuống, giải nén/biên dịch và cài đặt **MacStats** trực tiếp vào thư mục `/Applications`:

```bash
curl -fsSL https://raw.githubusercontent.com/openhoangnc/mac-stats/main/install.sh | bash
```

---

### 🗑️ Gỡ cài đặt hoàn toàn bằng 1 câu lệnh
Để dừng hoàn toàn MacStats, xóa bỏ các mục tự động khởi động cùng hệ thống, xóa cấu hình người dùng và xóa `/Applications/MacStats.app`:

```bash
curl -fsSL https://raw.githubusercontent.com/openhoangnc/mac-stats/main/uninstall.sh | bash
```

---

## ✨ Tính năng chính

- 🚀 **Siêu nhẹ & Nhanh**: Ứng dụng Swift thuần bản địa với mức tiêu thụ tài nguyên CPU và bộ nhớ cực kỳ thấp. Không yêu cầu dự án Xcode hay các thư viện phụ thuộc cồng kềnh.
- 📊 **Hiển thị 3 Cột trên Thanh Menu**:
  - **Cột bên trái (Mạng)**: Tốc độ Tải lên (dòng trên) và Tải xuống (dòng dưới) thời gian thực với đơn vị tự động điều chỉnh (`B`, `K`, `M`, `G`) và mã màu động theo tốc độ.
  - **Cột ở giữa (CPU/Bộ nhớ)**: Mức sử dụng CPU hiện tại (`%`) (dòng trên) và dung lượng RAM đã dùng tính bằng gigabytes (`G`) (dòng dưới) kèm mã màu cảnh báo theo mức độ sử dụng.
  - **Cột bên phải (Nhiệt độ)**: Nhiệt độ trung bình của CPU (dòng trên) và đơn vị (`°C` hoặc `°F`) (dòng dưới) với mã màu động dựa theo nhiệt độ.
- ⚙️ **Menu Cài đặt Tiện lợi**: Click chuột trái hoặc click chuột phải vào biểu tượng ứng dụng trên thanh menu để mở các tùy chọn:
  - **Khởi động cùng hệ thống (Launch at Login)**: Bật/tắt tự động khởi chạy khi đăng nhập macOS (sử dụng `SMAppService` trên macOS 13+ và tự động chuyển sang cấu hình LaunchAgents plist trên các phiên bản cũ hơn).
  - **Tần suất cập nhật (Update Interval)**: Tùy chỉnh khoảng thời gian cập nhật thông số (1 giây, 2 giây, hoặc 5 giây).
  - **Đơn vị nhiệt độ (Temperature Unit)**: Chọn giữa Celsius (`°C`) hoặc Fahrenheit (`°F`).
  - **Kho lưu trữ GitHub (GitHub Repository)**: Liên kết trực tiếp tới trang dự án trên GitHub.
  - **Thoát MacStats (Quit MacStats)**: Đóng hoàn toàn ứng dụng.
- 🧠 **Quét nhiệt độ SMC động**: Tự động quét các khóa cảm biến nhiệt độ SMC của dòng chip Intel và Apple Silicon (M1/M2/M3/M4/M5) khi khởi động (kiểm tra các lõi hiệu năng, lõi tiết kiệm điện, CPU tổng và các khóa Pro/Max/Ultra/General) để tính toán nhiệt độ trung bình thời gian thực.
- ⚡ **Tối ưu hóa Hiệu năng & Bộ nhớ**:
  - Chạy như một ứng dụng phụ trợ (`LSUIElement`), hoàn toàn ẩn trên Dock và trình chuyển đổi ứng dụng Command-Tab.
  - Áp dụng cơ chế giải phóng bộ nhớ chủ động (`malloc_zone_pressure_relief`) khi khởi động và định kỳ (mỗi 30 giây) để giảm thiểu hiện tượng phân mảnh bộ nhớ.
  - Thiết lập dung sai sai số thời gian (timer tolerance là 25% chu kỳ) để macOS có thể nhóm các sự kiện hẹn giờ lại với nhau nhằm tiết kiệm pin tối đa.
- 🤖 **Tự động đóng gói và cập nhật phiên bản trên GitHub**: Tích hợp quy trình công việc GitHub Actions tự động biên dịch, nén ứng dụng thành file `.zip`, tự động nâng mã phiên bản ngữ nghĩa (semantic versioning) và tạo GitHub Release mới khi có cập nhật.

---

## 🛠️ Đối số Dòng lệnh & Điều khiển Thủ công
Binary sau khi biên dịch hỗ trợ các đối số dòng lệnh sau:
- `--cleanup-login-item` / `--uninstall-login-item` / `--uninstall`: Huỷ đăng ký mục khởi động `SMAppService`, xoá tệp plist LaunchAgents của người dùng, làm sạch thuộc tính cấu hình mặc định và thoát ngay lập tức.

Nếu bạn muốn tự biên dịch từ mã nguồn:

1. Nhân bản kho lưu trữ:
   ```bash
   git clone https://github.com/openhoangnc/mac-stats.git
   cd mac-stats
   ```

2. Chạy tập lệnh build:
   ```bash
   ./build.sh
   ```

3. Khởi chạy ứng dụng:
   ```bash
   open MacStats.app
   ```

---

## 🤖 CI/CD & Tự động gắn phiên bản

MacStats tích hợp sẵn GitHub Actions workflow tại đường dẫn `.github/workflows/release.yml`.

- **Tự động tăng phiên bản**: Tự động nâng số phiên bản (`v1.0.0` → `v1.0.1`) mỗi khi đẩy mã nguồn lên nhánh chính (push) hoặc kích hoạt thủ công.
- **Tự động tạo Release**: Biên dịch gói ứng dụng macOS nguyên bản, đóng gói `MacStats.zip`, khởi tạo một GitHub Release mới và tải lên các bản dựng đã hoàn thiện.

---

## 📄 Bản quyền

Dự án này được cấp phép theo các điều khoản của Giấy phép MIT.
