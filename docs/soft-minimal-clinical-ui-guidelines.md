# Soft Minimal Card-based Clinical Scoring UI

Tài liệu này là guideline giao diện cho các màn hình lâm sàng NEWS2-L/SOFA.
Khi phát triển màn hình mới hoặc refactor màn hình hiện có, ưu tiên phong cách:

```text
Mobile-first card-based clinical scoring UI with soft minimal surfaces,
large radio-tile selectors, and Material Design 3 inspired spacing.
```

## Nguyên Tắc Chính

- Mobile-first, tối ưu cho màn hình điện thoại dọc trước.
- Giao diện phải giống một quy trình đánh điểm lâm sàng có hướng dẫn, không giống form admin chung chung.
- Mỗi nhóm quyết định lâm sàng nằm trong một section card riêng.
- Dùng radio tiles/choice cards cho các khoảng điểm cố định khi phù hợp.
- Kết quả điểm và kết luận cập nhật theo thời gian thực sau khi người dùng nhập/chọn.
- Giữ visual noise thấp: ít màu, nền dịu, khoảng cách rõ, typography gọn.
- Không để phần tổng hợp chiếm quá nhiều chiều cao trên mobile; phần nhập liệu phải là vùng chính.

## Surface Và Layout

- Nền màn hình dùng neutral/tonal background rất nhạt.
- Card dùng nền trắng hoặc surface sáng, bo góc lớn, border nhẹ, shadow rất mềm.
- Card không nên lồng card trong card nếu không có lý do rõ ràng.
- Spacing rộng vừa đủ để dễ chạm trên mobile, nhưng không làm form bị kéo dài quá mức.
- Trên mobile, ưu tiên một cột; trên tablet/desktop có thể dùng hai cột nếu vẫn giữ thứ tự đọc lâm sàng.
- Sticky diagnostic summary được phép dùng, nhưng phải compact và không che khuất vùng nhập liệu.

## Clinical Scoring Cards

Mỗi chỉ số NEWS2/SOFA/qSOFA nên được trình bày như một card riêng:

- Tiêu đề ngắn: `Nhịp thở`, `SpO2`, `Huyết áp tâm thu`, `Tri giác`.
- Hiển thị trạng thái: thiếu dữ liệu, bình thường, theo dõi, nguy cơ cao.
- Nếu có khoảng điểm cố định, dùng selectable score range tiles.
- Nếu vẫn cần nhập số chính xác, có thể kết hợp input số với gợi ý score/range ngay trong card.
- Luôn hiển thị điểm tương ứng hoặc trạng thái thiếu dữ liệu đủ rõ.

Ví dụ cấu trúc ưu tiên:

```text
Patient Context Card
Respiratory Failure Toggle Card
NEWS2 Scoring Cards
Lactate / Vasopressor Cards
SOFA Organ System Cards
Sticky Diagnostic Summary
```

## Radio Tiles / Choice Cards

Dùng cho các nhóm có lựa chọn cố định như khoảng nhịp thở, SpO2 scale, oxy hỗ trợ,
AVPU/GCS mapping, nhóm nguy cơ hoặc điểm cơ quan.

Mỗi tile nên có:

- Value/range dễ đọc, ví dụ `9-11`, `12-20`, `>= 25`.
- Điểm tương ứng, ví dụ `+1`, `+2`, `+3`.
- Selected state rõ bằng màu nền/border/icon.
- Disabled/error state nếu lựa chọn không hợp lệ theo context.
- Target chạm đủ lớn trên mobile.

Không dùng tile khi người dùng bắt buộc phải nhập giá trị chính xác để lưu hồ sơ
hoặc phục vụ export; trong trường hợp đó, giữ input chính xác và thêm tile/guidance hỗ trợ.

## Màu Và Tương Phản

- Màu chủ đạo phải dịu, hợp ngữ cảnh y tế: xanh lục/xanh teal/neutral sáng.
- Severity colors chỉ dùng cho trạng thái, không dùng trang trí lan rộng.
- Badge/chip phải đủ tương phản; tránh nền xám với chữ trắng.
- Text chính dùng màu đậm trên nền sáng; text phụ dùng neutral vừa phải.
- Warning/danger phải rõ nhưng không gây nhiễu toàn màn hình.

## Typography Và Microcopy

- Label ngắn, trực tiếp, đúng ngôn ngữ lâm sàng.
- Tránh microcopy mơ hồ như `...`, `now`, `dữ kiện`, `Chưa có`.
- Ưu tiên: `-`, `Vừa cập nhật`, `dữ liệu`, `Chưa nhập ...`.
- Trong card nhỏ, không dùng heading quá lớn.
- Text trong chip/tile/button phải vừa container trên mobile.

## Trạng Thái Và Validation

- Inline validation nằm gần field/tile gây lỗi.
- Missing data checklist phải chỉ rõ thiếu trường nào và nhảy được đến field đó nếu có thể.
- Score badge mã hóa theo severity: missing, normal, watch, warning, danger.
- Khi dữ liệu chưa đủ, hiển thị trạng thái `Chưa đủ dữ liệu` thay vì để trống.
- Khi đang lưu/check/update, dùng trạng thái ngắn gọn và không chặn luồng nhập liệu nếu không cần thiết.

## Pattern Nên Dùng Cho NEWS2/SOFA

- Card-based layout.
- Section cards.
- Radio tile selectors.
- Selectable score range tiles.
- Guided data entry.
- Clinical scoring questionnaire.
- Real-time scoring.
- Sticky diagnostic summary.
- Missing data checklist.
- Severity-coded score badges.
- Material Design 3 inspired surface hierarchy.

## Prompt Mẫu Cho FE Agent

```text
Redesign the medical scoring form using a Soft Minimal Clinical Scoring UI style.

Use a mobile-first card-based layout. Each clinical parameter should be placed
inside a rounded white section card on a light neutral background.

For predefined scoring ranges, use large selectable radio tiles instead of plain
text inputs. Each tile should show value range, score point, selected state, and
disabled/error state if needed.

Use Material Design 3 inspired surfaces: soft elevation, rounded corners, subtle
borders, generous spacing, calm clinical colors, and low visual noise.

The UI should feel like a guided clinical scoring questionnaire, not a generic
admin form. Preserve clinical accuracy, real-time scoring, inline validation,
missing data checklist, and severity-coded score badges.
```

