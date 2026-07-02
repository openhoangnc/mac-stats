# MacStats 📊

> Ứng dụng theo dõi trạng thái hệ thống gọn nhẹ trên thanh Menu macOS, được viết hoàn toàn bằng Swift. Giúp bạn xem nhanh mức sử dụng CPU, dung lượng RAM, tốc độ mạng và nhiệt độ CPU theo thời gian thực.

🌐 [English](README.md) | [Tiếng Việt](README.vi.md) | [简体中文](README.zh.md) | [日本語](README.ja.md)

![macOS 11.0+](https://img.shields.io/badge/macOS-11.0%2B-blue?logo=apple)
![Swift](https://img.shields.io/badge/Swift-5.0-orange?logo=swift)
![License](https://img.shields.io/badge/License-MIT-green)

---

## ⚡ Bắt đầu nhanh

### 📦 Cài đặt chỉ với 1 dòng lệnh
Copy và chạy dòng lệnh dưới đây trong Terminal để tải, giải nén và cài đặt **MacStats** thẳng vào thư mục `/Applications`:

```bash
curl -fsSL https://raw.githubusercontent.com/openhoangnc/mac-stats/main/install.sh | bash
```

---

### 🗑️ Gỡ cài đặt hoàn toàn
Để tắt MacStats, xoá cấu hình khởi động cùng hệ thống, xoá thiết lập của người dùng và xoá ứng dụng khỏi `/Applications`:

```bash
curl -fsSL https://raw.githubusercontent.com/openhoangnc/mac-stats/main/uninstall.sh | bash
```

---

## ✨ Các tính năng nổi bật

- 🚀 **Siêu nhẹ & Siêu nhanh**: Ứng dụng native Swift, ngốn cực kỳ ít CPU và RAM. Code gọn gàng, không cần project Xcode hay các thư viện ngoài cồng kềnh.
- 📊 **Hiển thị 3 cột thông tin trực quan**:
  - **Cột Trái (Mạng)**: Tốc độ Upload (dòng trên) và Download (dòng dưới). Đơn vị tự động thay đổi (`B`, `K`, `M`, `G`) và màu sắc cảnh báo theo băng thông.
  - **Cột Giữa (CPU & RAM)**: % CPU (dòng trên) và mức RAM đang dùng tính bằng GB (dòng dưới). Màu sắc tự động đổi (xanh/vàng/đỏ) khi hệ thống tải nặng.
  - **Cột Phải (Nhiệt độ)**: Nhiệt độ trung bình của CPU (dòng trên) và đơn vị (`°C` hoặc `°F`) (dòng dưới), cũng đổi màu linh hoạt theo độ nóng.
- ⚙️ **Menu Cài đặt nhanh**: Click chuột trái/phải vào icon trên thanh Menu để mở:
  - **Launch at Login**: Bật/tắt tự động khởi động cùng macOS (dùng `SMAppService` cực mượt trên macOS 13+, và tự lùi về LaunchAgents plist cho các máy cũ hơn).
  - **Update Interval**: Chọn tốc độ làm mới dữ liệu (1 giây, 2 giây hoặc 5 giây).
  - **Temperature Unit**: Chuyển đổi giữa độ C và độ F.
  - **GitHub Repository**: Link nhanh về trang GitHub của project.
  - **Quit MacStats**: Thoát app.
- 🧠 **Cảm biến nhiệt độ SMC thông minh**: Tự động dò tìm các cảm biến nhiệt SMC tương thích với cả chip Intel lẫn Apple Silicon (M1/M2/M3/M4/M5). App sẽ check nhiệt độ các nhân P-core, E-core... và tính ra nhiệt độ trung bình chuẩn xác nhất theo thời gian thực.
- ⚡ **Tối ưu cực hạn cho hiệu năng & bộ nhớ**:
  - Ẩn mình hoàn toàn như một app nền (`LSUIElement`) – không hiện dưới Dock, không cản trở lúc bạn Command-Tab.
  - Chủ động dọn dẹp bộ nhớ (gọi `malloc_zone_pressure_relief`) lúc mới bật và đều đặn mỗi 30 giây để tránh rác RAM.
  - Tích hợp độ trễ hẹn giờ (timer tolerance khoảng 25%), giúp macOS gom nhóm các tác vụ ngầm lại với nhau để tối ưu pin.
- 🤖 **Tích hợp sẵn luồng CI/CD**: Workflow GitHub Actions tự động build app, tăng version tự động và tạo GitHub Release mỗi lần cập nhật code.

---

## 🛠️ Build thủ công & Tham số dòng lệnh
File thực thi (binary) của app hỗ trợ sẵn các cờ sau:
- `--cleanup-login-item` / `--uninstall-login-item` / `--uninstall`: Dọn dẹp sạch sẽ các đăng ký khởi động ngầm (`SMAppService` và LaunchAgents plist), xoá cấu hình và tự thoát.

Nếu bạn thích tự tay clone và build code:

1. Clone repo về máy:
   ```bash
   git clone https://github.com/openhoangnc/mac-stats.git
   cd mac-stats
   ```

2. Chạy script build:
   ```bash
   ./build.sh
   ```

3. Mở app lên:
   ```bash
   open MacStats.app
   ```

---

## 🤖 Tự động hoá Release (CI/CD)

Codebase có sẵn workflow tại `.github/workflows/release.yml`.

- **Tự động tăng version**: Mỗi lần code được push lên nhánh chính (hoặc trigger bằng tay), version sẽ tự động nhảy số (`v1.0.0` → `v1.0.1`).
- **Build & Đóng gói tự động**: Compile ra app macOS, nén thành `MacStats.zip`, đẩy lên GitHub Release kèm theo changelog.

---

## 📄 Giấy phép

Project này được phân phối dưới giấy phép MIT.
