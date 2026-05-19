# NEWS2-L Clinical Documentation

Tài liệu này mô tả phạm vi lâm sàng, dữ liệu đầu vào, quan hệ giữa các thang điểm
và yêu cầu hoàn thành dữ kiện trước khi kết luận trong ứng dụng NEWS2-L.

## Nguồn tham chiếu

- NEWS2: https://emed.bvbnd.vn/page/news2-score/#menu4
- qSOFA: https://emed.bvbnd.vn/page/qsofa/
- SOFA: https://emed.bvbnd.vn/page/sofa-score-calculator/

## Mục tiêu dự án

NEWS2-L hỗ trợ nhập dữ liệu bệnh nhân, tính điểm cảnh báo sớm và hỗ trợ đánh giá
nguy cơ nhiễm khuẩn huyết theo một luồng thực hành thống nhất:

1. Thu thập thông tin hành chính và lý do nhập viện.
2. Nhập NEWS2 để sàng lọc sinh hiệu ban đầu.
3. Tự suy ra qSOFA từ các dữ kiện NEWS2 liên quan.
4. Nhập lactate và SOFA để xác nhận rối loạn cơ quan.
5. Hiển thị chẩn đoán gợi ý và mức nguy cơ.
6. Lưu bệnh nhân và xuất phiếu PDF/DOCX.

Ứng dụng là công cụ hỗ trợ tính điểm và ghi nhận phiếu, không thay thế đánh giá
lâm sàng của bác sĩ.

## Dữ liệu hành chính

| Nhóm | Trường dữ liệu | Vai trò |
| --- | --- | --- |
| Định danh | Mã bệnh nhân, họ tên, tuổi | Nhận diện bệnh nhân và tên file xuất |
| Thời điểm | Ngày nhập viện, giờ nhập viện | Ghi nhận thời điểm phân loại |
| Lý do | Lý do nhập viện | Bối cảnh lâm sàng, nhập nhiều dòng |
| Nhiễm trùng | Cơ quan nhiễm trùng | Bối cảnh nghi ngờ/xác định nhiễm trùng |

## NEWS2

NEWS2 dùng 7 tiêu chí nhập liệu:

| Tiêu chí | Dữ liệu cần nhập | Điểm |
| --- | --- | --- |
| Nhịp thở | Lần/phút | 0-3 |
| SpO2 | Phần trăm SpO2, kèm lựa chọn thang SpO2 thường hay thang tăng CO2 | 0-3 |
| Oxy | Đang thở oxy hay khí phòng | 0 hoặc 2 |
| Nhiệt độ | Độ C | 0-3 |
| Huyết áp tâm thu | mmHg | 0-3 |
| Nhịp tim | Lần/phút | 0-3 |
| Tri giác | AVPU: A hoặc C/V/P/U | 0 hoặc 3 |

Diễn giải điểm:

| Điều kiện | Mức nguy cơ trong app | Ý nghĩa vận hành |
| --- | --- | --- |
| Tổng 0-4, không có tiêu chí nào 3 điểm | Nguy cơ thấp | Tiếp tục theo dõi theo quy trình |
| Có bất kỳ tiêu chí đơn lẻ 3 điểm | Cần chú ý | Cần đánh giá lại, không chỉ nhìn tổng điểm |
| Tổng 5-6 | Nguy cơ trung bình | Cần phản ứng khẩn hơn |
| Tổng >= 7 | Nguy cơ cao | Cần phản ứng cấp cứu/hồi sức |

Yêu cầu hoàn thành:

- Không nên xem tổng NEWS2 là hoàn tất nếu thiếu một trong 7 tiêu chí.
- Nếu thiếu dữ kiện, UI/export cần thể hiện "chưa đủ dữ kiện NEWS2" thay vì để
  người dùng hiểu nhầm điểm 0 là bình thường.
- SpO2 phải đi cùng lựa chọn "nguy cơ hô hấp tăng CO2" vì cùng một giá trị SpO2
  có thể được chấm theo thang khác nhau.

## qSOFA

qSOFA gồm 3 tiêu chí, mỗi tiêu chí 1 điểm:

| Tiêu chí qSOFA | Nguồn dữ liệu trong app | Điều kiện đạt |
| --- | --- | --- |
| Nhịp thở nhanh | NEWS2 - nhịp thở | >= 22 lần/phút |
| Huyết áp tâm thu thấp | NEWS2 - huyết áp tâm thu | <= 100 mmHg |
| Thay đổi ý thức | NEWS2 - tri giác AVPU | Khác A/tỉnh táo |

Diễn giải:

- qSOFA 0-1: chưa đạt ngưỡng cảnh báo qSOFA.
- qSOFA >= 2: nguy cơ nhiễm trùng huyết cao hơn, cần đánh giá SOFA.

Yêu cầu hoàn thành:

- qSOFA phụ thuộc trực tiếp vào 3 dữ kiện NEWS2: nhịp thở, huyết áp tâm thu,
  tri giác.
- Nếu một trong 3 dữ kiện này chưa nhập, app nên đánh dấu dòng qSOFA tương ứng
  là thiếu dữ liệu.
- Không nên đưa ra kết luận qSOFA hoàn chỉnh khi chưa đủ 3 dữ kiện.

## Lactate

| Dữ liệu | Vai trò |
| --- | --- |
| Lactate tĩnh mạch | Hỗ trợ phân tầng mức lactate và đánh giá sốc nhiễm khuẩn |
| Thời gian lấy mẫu | Giúp đối chiếu lactate với thời điểm phân loại/giờ đầu |

Phân mức trong app:

| Lactate | Phân mức |
| --- | --- |
| < 2 mmol/L | Thấp |
| 2-3.9 mmol/L | Tăng |
| >= 4 mmol/L | Cao |

Yêu cầu hoàn thành:

- Nếu chưa nhập lactate, không nên kết luận sốc nhiễm khuẩn.
- Nếu có vận mạch nhưng thiếu lactate, UI nên báo "cần nhập lactate để hoàn
  tất đánh giá sốc nhiễm khuẩn".

## SOFA

SOFA gồm 6 hệ cơ quan, mỗi hệ 0-4 điểm:

| Hệ cơ quan | Dữ liệu cần nhập | Gợi ý nhập liệu |
| --- | --- | --- |
| Hô hấp | PaO2/FiO2 | Ghi rõ nếu có hỗ trợ hô hấp/oxy/vent/NIV/HF |
| Đông máu | Tiểu cầu | Đơn vị theo x10^3/mm3 |
| Gan | Bilirubin | Hỗ trợ mg/dL hoặc umol/L |
| Tim mạch | MAP hoặc thuốc vận mạch | Ghi MAP hoặc tên/liều vận mạch |
| Thần kinh | Glasgow Coma Scale | GCS 3-15 |
| Thận | Creatinin hoặc lượng nước tiểu | Có thể nhập creatinin và/hoặc ml nước tiểu/ngày |

Diễn giải trong app:

| Điều kiện | Kết quả |
| --- | --- |
| SOFA < 2 | Chưa đủ ngưỡng rối loạn cơ quan theo Sepsis-3 |
| SOFA >= 2 | Có nhiễm khuẩn huyết |
| Có vận mạch duy trì MAP >= 65 và lactate >= 2 mmol/L | Sốc nhiễm khuẩn |

Phân tầng nguy cơ SOFA:

| Tổng SOFA | Nhóm nguy cơ |
| --- | --- |
| < 9 | Thấp hơn |
| 9-11 | Trung gian |
| > 11 | Cao |

Yêu cầu hoàn thành:

- Không nên xem SOFA là hoàn tất nếu thiếu dữ kiện của 6 hệ cơ quan.
- Nếu chỉ nhập một phần SOFA, app có thể hiển thị điểm tạm tính nhưng cần ghi rõ
  "chưa đủ dữ kiện SOFA".
- Kết luận "Có nhiễm khuẩn huyết" cần SOFA hoàn tất hoặc ít nhất phải cho người
  dùng biết kết luận đang dựa trên dữ kiện đã nhập.
- Kết luận "Sốc nhiễm khuẩn" cần đồng thời có thông tin vận mạch và lactate.

## Quan hệ giữa các chỉ số

Các dữ kiện có quan hệ trực tiếp nên được đặt gần nhau để người dùng nhập nhanh
và hiểu vì sao kết quả thay đổi.

| Nhóm quan hệ | Dữ kiện nên đặt gần nhau | Lý do |
| --- | --- | --- |
| Hô hấp cấp | Nhịp thở, SpO2, thang SpO2 tăng CO2, thở oxy, SOFA hô hấp | Cùng phản ánh tình trạng hô hấp; nhịp thở còn dùng cho qSOFA |
| Huyết động | Huyết áp tâm thu, MAP/vận mạch, lactate | Huyết áp tâm thu dùng cho NEWS2/qSOFA; MAP/vận mạch và lactate dùng cho SOFA/sốc |
| Ý thức/thần kinh | AVPU, GCS | AVPU dùng cho NEWS2/qSOFA; GCS dùng cho SOFA thần kinh |
| Nhiễm trùng | Cơ quan nhiễm trùng, qSOFA, lactate, SOFA tổng | Đây là chuỗi xác nhận nguy cơ sepsis |
| Thận | Creatinin, nước tiểu | Cùng chấm SOFA thận, lấy điểm nặng hơn |
| Gan/đông máu | Bilirubin, tiểu cầu | Hai hệ SOFA thường cần xét nghiệm, nên đặt gần nhau trong nhóm xét nghiệm |

## Khuyến nghị bố cục nhập liệu

### 1. Hành chính

Đặt ở đầu form:

- Mã bệnh nhân
- Họ tên
- Tuổi
- Ngày nhập viện
- Giờ nhập viện
- Lý do nhập viện
- Cơ quan nhiễm trùng

### 2. Sinh hiệu và NEWS2

Ưu tiên nhóm theo dòng công việc tại giường bệnh:

1. Nhịp thở
2. SpO2 + nguy cơ hô hấp tăng CO2 + đang thở oxy
3. Huyết áp tâm thu + nhịp tim
4. Nhiệt độ
5. Tri giác AVPU
6. Chip điểm thành phần và tổng NEWS2

### 3. qSOFA tự động

Đặt ngay sau các trường NEWS2 liên quan, không tách quá xa:

- Nhịp thở >= 22
- Huyết áp tâm thu <= 100
- Tri giác bất thường
- Tổng qSOFA

Nếu thiếu nhịp thở/huyết áp/tri giác, từng dòng phải hiển thị trạng thái thiếu
dữ liệu thay vì chỉ hiện 0 điểm.

### 4. Lactate và huyết động nặng

Đặt gần nhau:

- Lactate tĩnh mạch
- Thời gian lấy mẫu
- Phân mức lactate
- Có dùng vận mạch
- MAP/vận mạch

Lý do: kết luận sốc nhiễm khuẩn phụ thuộc phối hợp vận mạch và lactate.

### 5. SOFA theo hệ cơ quan

Nên chia thành 3 cụm nhỏ:

- Hô hấp: PaO2/FiO2, hỗ trợ hô hấp.
- Huyết học/chuyển hóa: tiểu cầu, bilirubin.
- Huyết động/thần kinh/thận: MAP/vận mạch, GCS, creatinin/nước tiểu.

Sau cùng hiển thị:

- Điểm từng hệ cơ quan.
- Tổng SOFA.
- Ngưỡng Sepsis-3.
- Chẩn đoán gợi ý.

## Quy tắc thông báo thiếu dữ kiện

Khi một kết luận cần nhiều dữ kiện, app nên có trạng thái rõ ràng:

| Kết luận | Dữ kiện bắt buộc | Thông báo khi thiếu |
| --- | --- | --- |
| NEWS2 hoàn chỉnh | 7 tiêu chí NEWS2 | "Cần nhập đủ 7 tiêu chí NEWS2 để hoàn tất tính điểm." |
| qSOFA hoàn chỉnh | Nhịp thở, huyết áp tâm thu, tri giác | "Cần nhập nhịp thở, huyết áp tâm thu và tri giác để hoàn tất qSOFA." |
| SOFA hoàn chỉnh | 6 hệ cơ quan SOFA | "Cần nhập đủ 6 hệ cơ quan để hoàn tất SOFA." |
| Có nhiễm khuẩn huyết | SOFA đủ dữ kiện và tổng SOFA >= 2 | "Kết luận sepsis cần hoàn tất SOFA." |
| Sốc nhiễm khuẩn | Vận mạch, MAP >= 65 và lactate >= 2 mmol/L | "Cần nhập MAP và lactate để đánh giá sốc nhiễm khuẩn." |

## Quy tắc hiển thị điểm tạm tính

- Điểm tạm tính được phép hiển thị để hỗ trợ nhập liệu nhanh.
- Mọi điểm tạm tính cần phân biệt với điểm hoàn tất.
- Khi thiếu dữ liệu, không dùng màu xanh/ổn định cho kết luận tổng.
- Nên dùng trạng thái "Chưa đủ dữ kiện" với màu trung tính/muted.
- Chỉ dùng màu nguy cơ chính thức khi đã đủ dữ kiện của thang điểm tương ứng.

## Ghi chú triển khai hiện tại

- `ClinicalAssessment` là model dữ liệu chính.
- `recalculateClinicalAssessment` tự tính lại NEWS2, qSOFA, SOFA và chẩn đoán.
- qSOFA hiện được suy ra từ dữ liệu NEWS2 thay vì nhập riêng.
- Sốc nhiễm khuẩn hiện được xác định khi có vận mạch, MAP >= 65 và lactate >= 2 mmol/L.
- PDF/DOCX export nên tiếp tục thể hiện ô/dòng trống khi dữ liệu chưa được nhập.
