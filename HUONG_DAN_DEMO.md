# HƯỚNG DẪN & KỊCH BẢN DEMO TRỰC TIẾP ĐỒ ÁN QUẢN LÝ PHÒNG TRỌ (TỐI NAY)

Tài liệu này là kịch bản trình bày từng bước từ lúc mở ứng dụng đến khi hoàn tất toàn bộ quy trình nghiệp vụ. Bạn có thể mở song song file này trên máy tính để nhìn theo và thao tác trực tiếp trước giảng viên.

---

## PHẦN 0: CHUẨN BỊ TRƯỚC KHI BẮT ĐẦU (2 PHÚT TRƯỚC GIỜ DEMO)

1. **Chạy ứng dụng**:
   ```powershell
   E:\flutter\flutter\bin\flutter.bat run
   ```
   *(Lưu ý: Toàn bộ cache đường dẫn build cũ trên ổ C đã được dọn sạch hoàn toàn bằng `flutter clean` và cấu hình lại về SDK hiện tại).*
2. **Đăng nhập tài khoản Chủ trọ (Host)**:
   - Nếu đang ở màn hình Đăng nhập, đăng nhập bằng tài khoản Quản lý / Chủ trọ.
   - Nếu cần tạo nhanh dữ liệu mẫu ban đầu, có thể vào tab **Tài khoản (Cài đặt)** -> chọn **Khởi tạo dữ liệu mẫu (Seed Data)** (nếu database đang trống).

---

## PHẦN 1: GIỚI THIỆU GIAO DIỆN CHUNG & MENU DẤU 3 CHẤM (`⋮`)

**Lời dẫn trình bày với giảng viên:**
> *"Thưa thầy/cô, toàn bộ giao diện danh sách và chi tiết trong hệ thống (Phòng, Người thuê, Hợp đồng, Hóa đơn, Dịch vụ, Bảo trì) đã được chuẩn hóa gọn gàng: các nút thao tác **Sửa** và **Xóa** rời rạc đã được gom toàn bộ vào nút menu dấu 3 chấm dọc (`⋮`)."*

**Thao tác trên màn hình:**
1. Tại màn hình **Phòng trọ**, chỉ vào góc phải của bất kỳ thẻ phòng nào -> Nhấn vào biểu tượng **dấu 3 chấm dọc (`⋮`)**.
2. Hiển thị menu gồm:
   - **Sửa** (biểu tượng cây bút màu xanh).
   - **Xóa** (biểu tượng thùng rác và chữ màu đỏ trực quan).
3. Nhấn vào 1 phòng bất kỳ để mở **Chi tiết phòng** -> Chỉ lên góc trên bên phải thanh tiêu đề (AppBar) cũng có nút **dấu 3 chấm (`⋮`)** để Sửa hoặc Xóa phòng.

---

## PHẦN 2: TẠO PHÒNG MỚI & QUẢN LÝ NGƯỜI THUÊ (CỐ ĐỊNH NÚT "THÊM NGƯỜI" + ẢNH CCCD)

### Bước 2.1: Tạo một phòng trống mới để demo
1. Tại tab **Phòng**, nhấn nút **+ (Thêm phòng)** ở góc dưới phải.
2. Nhập thông tin:
   - **Tên phòng**: `P.305` (hoặc `P.Demo`)
   - **Giá thuê cơ bản**: `3500000` (3.500.000 đ/tháng)
   - **Tiền đặt cọc**: `3500000`
   - **Số người tối đa**: `3`
   - Tích chọn các dịch vụ áp dụng: **Điện**, **Nước**, **Wifi**, **Rác**.
3. Nhấn **Lưu lại** -> Phòng `P.305` xuất hiện ở trạng thái **Trống**.

### Bước 2.2: Quản lý Người thuê – Nút "Thêm người" cố định & Chụp/Tải ảnh CCCD
**Lời dẫn trình bày với giảng viên:**
> *"Tiếp theo ở phần Quản lý Người thuê, nút **Thêm người** luôn được ghim cố định ở dưới đáy màn hình, khi cuộn danh sách dài nút này không bao giờ bị trôi theo. Ngoài ra, hồ sơ người thuê hỗ trợ chụp ảnh từ Camera hoặc chọn ảnh từ Thư viện cho CCCD mặt trước và mặt sau, đồng thời phân quyền duy nhất 1 Trưởng phòng đại diện hợp đồng."*

**Thao tác trên màn hình:**
1. Vào màn hình **Khách thuê** (từ Trang chủ chọn **Khách thuê** hoặc vào **Chi tiết phòng -> Tab Khách thuê**).
2. **Cuộn lên/xuống danh sách người thuê** để giảng viên thấy nút **"Thêm người"** màu xanh luôn nằm cố định ở dưới cùng màn hình.
3. Nhấn nút **"Thêm người"**:
   - **Họ và tên**: `Nguyễn Văn An`
   - **Số điện thoại**: `0912345678`
   - **Số CCCD / CMND**: `079203001234`
   - **Vai trò trong phòng**: Chọn **`Trưởng phòng (Đại diện HĐ)`** *(Chú thích hiển thị rõ: Mỗi phòng chỉ có duy nhất 1 Trưởng phòng)*.
   - **Phòng đang ở**: Có thể để `Chưa gán phòng (sẽ chọn khi lập Hợp đồng)` hoặc chọn phòng `P.305`.
   - **Tại mục Ảnh Căn cước công dân (CCCD)**:
     - Nhấn vào khung **CCCD Mặt trước** -> Hiển thị menu chọn:
       1. *Chụp ảnh từ Camera*
       2. *Chọn ảnh từ Thư viện*
       3. *Dùng ảnh CCCD mẫu (nhanh cho máy ảo)* -> Nếu đang chạy máy ảo Android không có sẵn ảnh trong Gallery, nhấn chọn **"Dùng ảnh CCCD mẫu"** hoặc **"Thư viện"** để nạp ngay ảnh CCCD mặt trước.
     - Tương tự nhấn vào khung **CCCD Mặt sau** -> Chọn ảnh hoặc tạo ảnh CCCD mặt sau.
4. Nhấn **Lưu thông tin người thuê**.
5. Nhấn vào thẻ của `Nguyễn Văn An` để mở **Hồ sơ người thuê**:
   - Chỉ cho giảng viên xem **Ảnh CCCD Mặt trước & Mặt sau** hiển thị trực tiếp trên hồ sơ (nhấn vào ảnh để phóng to xem toàn màn hình).
   - Ở dưới đáy màn hình Chi tiết người thuê, nút **"Thêm người"** cũng được cố định sẵn để thêm nhanh thành viên tiếp theo.
6. *(Tùy chọn)* Nhấn **"Thêm người"** để tạo thêm 1 người ở ghép:
   - **Họ và tên**: `Trần Văn Bình`, SĐT `0988777666`, Vai trò: **`Thành viên ở ghép`**, kèm ảnh CCCD.

---

## PHẦN 3: QUẢN LÝ HỢP ĐỒNG (6 ĐIỂM CẬP NHẬT QUAN TRỌNG)

**Lời dẫn trình bày với giảng viên:**
> *"Ở phân hệ Hợp đồng, em đã cập nhật đầy đủ 6 ràng buộc nghiệp vụ:
> 1. Chỉ phòng đang ở trạng thái **Trống** mới được phép tạo hợp đồng mới; phòng đã có hợp đồng hiệu lực (dù 2 hay nhiều người ở chung) sẽ bị khóa không cho tạo hợp đồng thứ 2 chồng lên.
> 2. Mỗi phòng/hợp đồng chỉ có duy nhất 1 **Trưởng phòng**, nếu chọn người mới làm Trưởng phòng thì người cũ tự động chuyển thành Thành viên thường.
> 3. Nhãn ngày tháng ghi rõ **Ngày bắt đầu hợp đồng** và **Ngày kết thúc hợp đồng**.
> 4. Ô **Tiền phòng** và **Tiền đặt cọc** là ô nhập liệu linh hoạt (`TextFormField`), gợi ý theo giá phòng nhưng cho phép sửa trực tiếp khi thỏa thuận.
> 5. Bắt buộc chốt **Chỉ số điện ban đầu** và **Chỉ số nước ban đầu** lúc làm hợp đồng để làm chỉ số cũ cho hóa đơn tháng đầu tiên.
> 6. Danh sách hợp đồng có thanh công cụ **Sắp xếp theo Ngày** (mới nhất/cũ nhất) và **Sắp xếp theo Phòng** (A→Z / Z→A)."*

**Thao tác từng bước trên màn hình:**

### Bước 3.1: Kiểm tra chặn tạo hợp đồng trên phòng đang thuê & Tạo hợp đồng mới
1. Vào tab **Hợp đồng** (hoặc từ Trang chủ chọn **Hợp đồng**) -> Nhấn nút **+ (Thêm hợp đồng)**.
2. **Demo chặn phòng đã có người ở**:
   - Nhấn vào ô **Chọn phòng trọ**: Chỉ ra cho giảng viên thấy các phòng đang có hợp đồng được gắn nhãn `(Đang có HĐ - Đã khóa)` màu cam/xám và không thể chọn để tạo hợp đồng chồng lên.
3. **Chọn phòng trống `P.305`**:
   - Hệ thống tự động điền giá gợi ý vào ô **Tiền phòng (đ/tháng)** và **Tiền đặt cọc (đ)**.
4. **Chọn Người đại diện ký hợp đồng (Trưởng phòng)**:
   - Chọn `Nguyễn Văn An` -> Có nhãn xác nhận: *"Người này sẽ giữ vai trò Trưởng phòng duy nhất của phòng"*.
5. **Kiểm tra nhãn Ngày bắt đầu & Ngày kết thúc**:
   - Chỉ vào 2 trường có nhãn rõ ràng: **"Ngày bắt đầu hợp đồng"** (mặc định hôm nay) và **"Ngày kết thúc hợp đồng"** (mặc định +1 năm, có thể nhấn chọn lại ngày).
6. **Chỉnh sửa linh hoạt Tiền phòng & Tiền cọc**:
   - Nhấp vào ô **Tiền phòng (đ/tháng)**: Sửa thử từ `3500000` thành `3600000`.
   - Nhấp vào ô **Tiền đặt cọc (đ)**: Sửa thử thành `3600000`.
7. **Nhập Chỉ số Điện & Nước ban đầu (bắt buộc)**:
   - Ô **Chỉ số điện ban đầu (kWh)**: Nhập `120`.
   - Ô **Chỉ số nước ban đầu (m³)**: Nhập `35`.
   - *(Giải thích: Nếu bỏ trống 1 trong 2 ô này và bấm Lưu, hệ thống sẽ báo lỗi yêu cầu nhập đủ chỉ số bàn giao phòng).*
8. Nhấn **Lưu hợp đồng**.

### Bước 3.2: Kiểm tra Chi tiết Hợp đồng & Liên kết Người thuê
1. Nhấn vào hợp đồng vừa tạo của phòng `P.305` để mở **Chi tiết hợp đồng**:
   - Chỉ vào mục **Thời hạn hợp đồng**: Hiển thị rõ **Ngày bắt đầu hợp đồng** và **Ngày kết thúc hợp đồng**.
   - Chỉ vào mục **Chỉ số bàn giao ban đầu (lúc lập HĐ)**: Hiển thị **Chỉ số điện ban đầu: 120 kWh** và **Chỉ số nước ban đầu: 35 m³**.
   - Chỉ vào mục **Thông tin người thuê & Thành viên phòng**: Hiển thị đầy đủ Trưởng phòng `Nguyễn Văn An` (kèm SĐT, CCCD, ảnh CCCD mặt trước/sau) và danh sách các thành viên trong phòng. Nhấn vào tên người thuê sẽ mở ngay sang Hồ sơ chi tiết của người thuê đó.
   - Trên góc phải AppBar và ngoài thẻ danh sách đều dùng **menu dấu 3 chấm (`⋮`)** gồm Sửa / Xóa.

### Bước 3.3: Demo Thanh công cụ Sắp xếp (Sort) Hợp đồng
1. Quay lại màn hình **Danh sách Hợp đồng**.
2. Ngay dưới thanh tìm kiếm là thanh công cụ **Sắp xếp**:
   - Nhấn **`Ngày mới nhất`** / **`Ngày cũ nhất`**: Danh sách hợp đồng lập tức đảo thứ tự theo ngày bắt đầu hợp đồng.
   - Nhấn **`Phòng A → Z`** / **`Phòng Z → A`**: Danh sách hợp đồng sắp xếp tăng dần hoặc giảm dần theo số phòng tự nhiên (ví dụ P.101 -> P.102 -> P.305).

---

## PHẦN 4: HÓA ĐƠN & THANH TOÁN (BỎ QR, HỦY & TẠO LẠI, NGÀY GIỜ THANH TOÁN, TIỀN CỌC, GHI CHÚ, CHIA SẺ)

### Bước 4.1: Ghi chỉ số Điện Nước tháng đầu tiên (Tự động lấy chỉ số ban đầu lúc làm Hợp đồng)
1. Vào **Dịch vụ & Chỉ số** (hoặc từ Chi tiết phòng `P.305` -> Nhấn **Ghi điện nước**).
2. Chọn phòng `P.305`:
   - Chỉ cho giảng viên thấy ô **Chỉ số cũ** của Điện đã tự động lấy mốc **`120`** và Nước tự động lấy mốc **`35`** từ lúc làm hợp đồng!
   - Nhập **Chỉ số mới**: Điện = `170` (tiêu thụ 50 kWh), Nước = `42` (tiêu thụ 7 m³).
3. Nhấn **Lưu chỉ số**.

### Bước 4.2: Tạo hóa đơn -> Hủy hóa đơn -> Tạo lại hóa đơn cùng kỳ
**Lời dẫn trình bày với giảng viên:**
> *"Khi một hóa đơn bị hủy (Cancelled) hoặc bị xóa, hệ thống cho phép tạo lại hóa đơn mới cho phòng đó trong cùng kỳ/tháng mà không bị chặn trùng như trước."*

**Thao tác trên màn hình:**
1. Vào tab **Hóa đơn** -> Nhấn nút **+ (Tạo hóa đơn)**.
2. Chọn phòng `P.305` và kỳ hiện tại -> Kiểm tra bảng tính tự động (Tiền phòng 3.600.000đ + Điện + Nước + Dịch vụ) -> Nhấn **Phát hành hóa đơn**.
3. Mở hóa đơn vừa tạo của `P.305`:
   - **Điểm 1**: Chỉ cho giảng viên thấy **Mã QR đã được gỡ bỏ hoàn toàn** khỏi màn hình chi tiết hóa đơn.
   - **Điểm 2**: Cuộn xuống dưới nhấn nút **Hủy hóa đơn** -> Trạng thái hóa đơn chuyển sang **Đã hủy**.
4. Quay lại danh sách Hóa đơn -> Nhấn **+ (Tạo hóa đơn)** lại cho đúng phòng `P.305` trong cùng kỳ vừa rồi:
   - Hệ thống **cho phép tạo lại bình thường** (không báo lỗi trùng kỳ). Nhấn **Phát hành hóa đơn** để có hóa đơn mới ở trạng thái **Chưa thanh toán**.

### Bước 4.3: Xác nhận thanh toán kèm "Thu tiền cọc", "Thêm ghi chú" & "Ngày giờ thanh toán"
**Lời dẫn trình bày với giảng viên:**
> *"Khi xác nhận thanh toán hóa đơn, chủ trọ có thể tích chọn **Thu tiền cọc**, nhập số tiền cọc đã thu và **Thêm ghi chú** cho hóa đơn. Sau khi thanh toán, hệ thống tự động lưu và hiển thị chính xác **Ngày giờ thanh toán (dd/MM/yyyy HH:mm)**, đồng thời vẫn cho phép cập nhật bổ sung tiền cọc hoặc ghi chú sau khi đã thanh toán."*

**Thao tác trên màn hình:**
1. Mở hóa đơn **Chưa thanh toán** của phòng `P.305`.
2. Nhấn nút **Xác nhận đã thanh toán** ở dưới cùng -> Một hộp thoại xác nhận hiện ra:
   - Chọn hình thức: `Chuyển khoản` hoặc `Tiền mặt`.
   - Tích chọn ô **"Thu tiền cọc"** -> Số tiền cọc tự động gợi ý theo hợp đồng (`3600000`), có thể chỉnh sửa tùy ý.
   - Nhập vào ô **"Thêm ghi chú"**: `Đã thu đủ tiền phòng tháng đầu + tiền cọc hợp đồng`.
   - Nhấn **Xác nhận thu tiền**.
3. Quan sát màn hình **Chi tiết hóa đơn** sau khi thanh toán:
   - Hiển thị rõ dòng: **`Ngày giờ thanh toán: dd/MM/yyyy HH:mm`** (ví dụ: `09/11/2026 19:30` màu xanh lá).
   - Hiển thị dòng: **`Thu tiền cọc: Đã thu (3.600.000 đ)`**.
   - Hiển thị dòng: **`Ghi chú hóa đơn: Đã thu đủ tiền phòng tháng đầu + tiền cọc hợp đồng`**.
   - Nếu muốn sửa lại tiền cọc hoặc ghi chú sau khi đã thanh toán, nhấn nút **"Cập nhật tiền cọc / ghi chú sau thanh toán"** ngay bên dưới để chỉnh sửa bất kỳ lúc nào.

### Bước 4.4: Nút "Chia sẻ" (Share) cạnh nút "In" & Liên kết đồng bộ dữ liệu
1. Tại khu vực nút thao tác phía dưới màn hình Chi tiết hóa đơn, chỉ vào 2 nút nằm cạnh nhau:
   - Nút **In hóa đơn** (xuất/in PDF hóa đơn).
   - Nút **Chia sẻ** (màu xanh dương nằm ngay cạnh nút In):
     - Nhấn vào nút **Chia sẻ** -> Hiển thị 2 tùy chọn tiện lợi:
       1. **Chia sẻ file PDF hóa đơn**: Mở hộp thoại chia sẻ hệ thống để gửi file PDF hóa đơn qua Zalo, Messenger, Email...
       2. **Sao chép nội dung hóa đơn (Văn bản)**: Copy toàn bộ chi tiết hóa đơn (phòng, người thuê, chỉ số điện nước, tổng tiền, tiền cọc, ghi chú, ngày giờ thanh toán) vào bộ nhớ tạm để dán gửi tin nhắn nhanh.
2. **Kiểm tra tính liên kết đồng bộ Người thuê - Hợp đồng - Hóa đơn**:
   - Ngay trên màn hình **Chi tiết hóa đơn**, tại mục **Liên kết Phòng · Người thuê · Hợp đồng**, hiển thị đầy đủ tên người đại diện, SĐT, CCCD và các nút bấm chuyển nhanh sang **Hồ sơ Người thuê**, **Chi tiết Phòng**, và **Hợp đồng**.

---

## PHẦN 5: TỔNG KẾT CÁC ĐIỂM ĐÃ HOÀN THIỆN (DÀNH CHO PHẦN HỎI ĐÁP)

| STT | Hạng mục yêu cầu | Trạng thái | Vị trí kiểm tra nhanh trên App |
| :-: | :--- | :---: | :--- |
| 1 | Gom nút Sửa / Xóa vào menu dấu 3 chấm dọc (`⋮`) | Hoàn tất 100% | Danh sách & Chi tiết: Phòng, Người thuê, Hợp đồng, Hóa đơn, Dịch vụ, Bảo trì |
| 2 | Bỏ mã QR trong chi tiết hóa đơn | Hoàn tất 100% | Màn hình Chi tiết hóa đơn & Tạo hóa đơn |
| 3 | Hiển thị `Ngày giờ thanh toán: dd/MM/yyyy HH:mm` | Hoàn tất 100% | Chi tiết hóa đơn (sau khi thanh toán) & Danh sách hóa đơn |
| 4 | Nút **Chia sẻ** cạnh nút **In** hóa đơn | Hoàn tất 100% | Chi tiết hóa đơn (Chia sẻ PDF hoặc Sao chép nội dung văn bản) |
| 5 | Tùy chọn **Thu tiền cọc** & **Thêm ghi chú** khi/sau thanh toán | Hoàn tất 100% | Hộp thoại Xác nhận thanh toán & nút Cập nhật sau thanh toán |
| 6 | Tạo lại hóa đơn sau khi Hủy hoặc Xóa | Hoàn tất 100% | Hủy hóa đơn xong bấm Tạo hóa đơn lại cùng phòng/kỳ |
| 7 | Chỉ phòng **Trống** mới được tạo hợp đồng (chặn tạo 2 HĐ 1 phòng) | Hoàn tất 100% | Form Tạo hợp đồng (phòng đang thuê bị khóa chọn) |
| 8 | Duy nhất 1 **Trưởng phòng** đại diện hợp đồng | Hoàn tất 100% | Form Người thuê & Hợp đồng (tự động hạ vai trò người cũ nếu đổi Trưởng phòng) |
| 9 | Nhãn rõ ràng **Ngày bắt đầu hợp đồng** & **Ngày kết thúc hợp đồng** | Hoàn tất 100% | Form Tạo/Sửa hợp đồng & Chi tiết hợp đồng |
| 10 | Cho phép sửa linh hoạt **Tiền phòng** & **Tiền đặt cọc** | Hoàn tất 100% | Form Tạo/Sửa hợp đồng (`TextFormField` cho phép nhập tự do) |
| 11 | Bắt buộc nhập **Chỉ số điện/nước ban đầu** lúc làm hợp đồng | Hoàn tất 100% | Form Tạo hợp đồng -> Tự động làm chỉ số cũ khi ghi điện nước tháng đầu |
| 12 | Sắp xếp hợp đồng theo **Ngày** và theo **Phòng** | Hoàn tất 100% | Thanh Sort trên đầu màn hình Danh sách hợp đồng |
| 13 | Cố định nút **"Thêm người"** ở dưới cùng màn hình | Hoàn tất 100% | Danh sách người thuê, Chi tiết người thuê, Tab Khách thuê trong Chi tiết phòng |
| 14 | Chụp/Tải ảnh **CCCD Mặt trước & Mặt sau** + Xem trước | Hoàn tất 100% | Form Thêm/Sửa người thuê, Hồ sơ người thuê, Chi tiết hợp đồng |
| 15 | Liên kết đồng bộ **Người thuê - Hợp đồng - Hóa đơn** | Hoàn tất 100% | Tự động đồng bộ thông tin và điều hướng qua lại giữa 3 màn hình |
