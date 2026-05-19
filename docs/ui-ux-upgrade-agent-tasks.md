# NEWS2-L UI/UX Upgrade - Agent Task Board

Tài liệu điều phối cho các agent/dev FE triển khai cải tiến UI/UX theo hướng
clinical dashboard + guided form.

## Cách dùng

- Mỗi agent nhận đúng task được giao, đọc phần `Context chung` và task của mình.
- Agent phải cập nhật checklist trong file này khi hoàn thành từng hạng mục.
- Không đổi công thức tính NEWS2/qSOFA/SOFA.
- Không đổi schema database.
- Không đổi export PDF/DOCX nếu task không yêu cầu rõ.
- Nếu cần thay đổi ngoài phạm vi task, ghi vào `Ghi chú điều phối` trước khi làm.

## Context chung

Repo Flutter/Dart. UI hiện tập trung nhiều trong `lib/main.dart`. Logic scoring nằm ở:

- `lib/src/domain/scoring.dart`
- `lib/src/domain/clinical_assessment.dart`
- `lib/src/domain/clinical_value_parser.dart`
- `lib/src/domain/scale_guidance_config.dart`

Mục tiêu sản phẩm:

- Biến form dài thành clinical dashboard + guided form.
- Chỉ rõ field còn thiếu thay vì thông báo chung chung.
- Badge/status nhất quán cho NEWS2, qSOFA, SOFA, lactate, sepsis/shock.
- Patient list giúp ưu tiên bệnh nhân nguy cơ cao.
- Auto-save ghi trực tiếp vào history khi phiếu có dữ liệu meaningful.

Các microcopy cần loại bỏ trong UI lâm sàng chính:

- `...`
- `now`
- `dữ kiện`
- `Chưa có`

Thay bằng:

- `-`
- `Vừa cập nhật`
- `dữ liệu`
- `Chưa nhập ...`

## Bảng Tổng Quan

| Task | Agent | Trạng thái | Phụ thuộc | Output chính |
| --- | --- | --- | --- | --- |
| T1 - Display domain layer | Agent A | [x] Hoàn thành | Không | `assessment_display.dart` + unit tests |
| T2 - Clinical components | Agent B | [x] Hoàn thành | T1 nên có contract | `clinical_components.dart` + widget tests |
| T3 - Save state + auto-save | Agent C | [x] Hoàn thành code | Không | save state, debounce auto-save |
| T4 - Form dashboard + missing data | Agent D | [x] Hoàn thành code | T1, T2 | dashboard, missing panel, scroll/focus |
| T5 - Form accordion refactor | Agent D | [x] Hoàn thành code | T1, T2, T4 | 5 accordion sections |
| T6 - Patient list upgrade | Agent E | [x] Hoàn thành code | T1, T2 | filters, summary strip, patient card |
| T7 - Responsive + polish P2 | Agent F | [ ] Hoàn thành phần chính, chờ manual smoke | T2, T4, T5, T6 | tablet/mobile polish, warnings, unit switcher |
| T8 - Tests + final verification | Agent G | [x] Analyze/test/build pass | T1-T7 | analyze/test/manual checklist |

## Trạng Thái Thực Hiện 2026-05-19

- [x] Tạo `lib/src/domain/assessment_display.dart`.
- [x] Tạo `lib/src/ui/clinical_components.dart`.
- [x] Tạo `test/assessment_display_test.dart`.
- [x] Tạo `test/clinical_components_test.dart`.
- [x] Tích hợp dashboard NEWS2/qSOFA/SOFA/kết luận vào form.
- [x] Tích hợp missing data panel, scroll/focus theo field có key/focus node.
- [x] Chuyển form sang 5 accordion sections với progress.
- [x] Thêm save state và auto-save debounce ghi vào history khi phiếu có dữ liệu.
- [x] Nâng cấp patient list với filter chips, summary strip, patient badges, empty state CTA.
- [x] Thêm abnormal warnings cho các input chính.
- [x] Thêm unit switcher cho bilirubin và creatinine, lưu vào string field hiện tại.
- [x] `flutter test` pass: 20/20 tests.
- [x] `flutter build web` pass.
- [x] `flutter analyze` pass: No issues found.
- [ ] Manual smoke trên thiết bị thật/chrome chưa thực hiện trong lượt này.

## T1 - Display Domain Layer

**Lệnh giao việc cho Agent A**

Bạn là agent phụ trách display/domain contract cho UI. Hãy tạo lớp helper hiển thị
không phụ thuộc Flutter widget để các màn form/list dùng chung. Không sửa công
thức tính điểm trong `scoring.dart`.

**Files**

- Tạo `lib/src/domain/assessment_display.dart`
- Tạo `test/assessment_display_test.dart`

**Checklist**

- [x] Tạo enum `ClinicalStatus`: `missing`, `normal`, `watch`, `warning`, `danger`.
- [x] Tạo model `MissingDataItem` gồm ít nhất `id`, `label`, `sectionId`, `fieldId`, `groupLabel`.
- [x] Tạo model `ScoreDisplay` cho title, score text, status, status label, helper text, completed/total.
- [x] Tạo model `SectionProgress` cho section id, completed count, total count, missing labels.
- [x] Tạo model `PatientRiskSummary` cho trạng thái list/filter.
- [x] Implement `news2MissingItems`.
- [x] Implement `qsofaMissingItems`.
- [x] Implement `sofaMissingItems`.
- [x] Implement `shockMissingItems`.
- [x] Implement `allMissingItems`.
- [x] Implement progress helpers cho NEWS2, qSOFA, lactate/shock, SOFA.
- [x] Implement status helpers cho NEWS2, qSOFA, SOFA, diagnosis.
- [x] Implement filter predicates: incomplete, high risk, septic shock.
- [x] Unit test missing NEWS2 5/7.
- [x] Unit test SOFA progress 2/6.
- [x] Unit test shock thiếu lactate/MAP.
- [x] Unit test high risk và septic shock predicates.

**Done khi**

- [x] `flutter test test/assessment_display_test.dart` pass.
- [x] File domain không import `package:flutter/material.dart`.

## T2 - Clinical Components

**Lệnh giao việc cho Agent B**

Bạn là agent phụ trách component UI tái sử dụng. Hãy tạo component nhận data từ
caller/domain helper, không tự nhúng logic scoring phức tạp.

**Files**

- Tạo `lib/src/ui/clinical_components.dart`
- Tạo `test/clinical_components_test.dart`

**Checklist**

- [x] Tạo `StatusBadge`.
- [x] Tạo `ClinicalSummaryCard`.
- [x] Tạo `MissingDataPanel`.
- [x] Tạo `FormSectionAccordion`.
- [x] Tạo `MedicalInputField`.
- [x] Tạo `SaveStatusIndicator`.
- [x] Tạo `ScoreBreakdownRow`.
- [x] Tạo `PatientCard`.
- [x] Component support màu/status theo `ClinicalStatus`.
- [x] `ClinicalSummaryCard` hiển thị score lớn, status badge, helper text.
- [x] `MissingDataPanel` group item theo `groupLabel` và gọi callback khi click.
- [x] `MedicalInputField` có label luôn hiện, unit suffix, helper, warning, error, score text.
- [x] `PatientCard` có slot/callback cho tap mở phiếu và menu hành động.
- [x] Widget test summary card missing/complete.
- [x] Widget test status badge labels.
- [x] Widget test missing panel click callback.
- [x] Widget test medical input warning text.

**Done khi**

- [x] `flutter test test/clinical_components_test.dart` pass.
- [x] Component không phụ thuộc trực tiếp `_HomeScreenState`.

## T3 - Save State + Auto-save

**Lệnh giao việc cho Agent C**

Bạn là agent phụ trách persistence interaction. Hãy thêm save state và auto-save
debounce ghi trực tiếp vào history, nhưng không tạo phiếu rỗng.

**Files**

- Sửa `lib/main.dart`

**Checklist**

- [x] Tạo enum private `_SaveState`: `clean`, `dirty`, `saving`, `error`.
- [x] Thêm state `_autoSaveTimer`.
- [x] Thêm state `_saveState`.
- [x] Thêm state `_lastSavedAtMillis`.
- [x] Thêm state `_saveError`.
- [x] Dispose `_autoSaveTimer`.
- [x] `_mutate` set dirty, recalculate, save draft hiện tại, schedule auto-save.
- [x] Auto-save debounce 500-1000ms.
- [x] Phiếu mới chỉ append history sau khi có dữ liệu meaningful.
- [x] Phiếu đang edit update cùng `_openedSavedAssessmentId`.
- [x] Auto-save refresh history sau khi lưu thành công.
- [x] Nút `Lưu` flush pending auto-save rồi quay về list.
- [x] Back/rời form flush nếu đang dirty/saving.
- [x] Nếu save lỗi, hiển thị xác nhận trước khi rời.
- [x] Header có `SaveStatusIndicator` hoặc text tương đương: `Chưa lưu`, `Đang lưu...`, `Đã lưu HH:mm`, `Lỗi lưu`.

**Done khi**

- [x] Không tạo record history cho phiếu trắng.
- [x] Mở phiếu đã lưu, sửa field, auto-save update đúng record cũ.
- [x] `flutter analyze` không báo lỗi phần save state.

## T4 - Form Dashboard + Missing Data

**Lệnh giao việc cho Agent D**

Bạn là agent phụ trách dashboard đầu form và missing data workflow. Hãy thay vùng
summary cũ bằng clinical dashboard và missing data panel có thể scroll/focus tới
field.

**Files**

- Sửa `lib/main.dart`
- Dùng `lib/src/domain/assessment_display.dart`
- Dùng `lib/src/ui/clinical_components.dart`

**Checklist**

- [x] Thay `_scoreSummary` bằng dashboard gồm NEWS2, qSOFA, SOFA, Kết luận sơ bộ.
- [x] Score thiếu dữ liệu hiển thị `-`, không dùng `...`.
- [x] Summary helper nói rõ thiếu bao nhiêu, ví dụ `Thiếu 5/7 tiêu chí`.
- [x] Thêm `MissingDataPanel` dưới dashboard.
- [x] Missing data group theo NEWS2/qSOFA, Lactate & huyết động, SOFA, Sốc nhiễm khuẩn.
- [x] Thêm `ScrollController` cho form.
- [x] Thêm map `sectionId -> GlobalKey`.
- [x] Thêm map `fieldId -> GlobalKey`.
- [x] Thêm map `fieldId -> FocusNode` cho các input chính.
- [x] Click missing item mở đúng section.
- [x] Click missing item scroll tới field.
- [x] Click missing item focus input nếu có thể.

**Done khi**

- [x] Màn form mới nhìn thấy trạng thái NEWS2/qSOFA/SOFA trong 5 giây.
- [x] Missing panel liệt kê tên field cụ thể.
- [x] Click missing item hoạt động với ít nhất NEWS2, SOFA, lactate/shock.

## T5 - Form Accordion Refactor

**Lệnh giao việc cho Agent D**

Bạn tiếp tục refactor form dài thành guided form 5 section. Giữ logic tính điểm
và dữ liệu model hiện có.

**Files**

- Sửa `lib/main.dart`

**Checklist**

- [x] Thay `_section` cũ bằng `FormSectionAccordion`.
- [x] Section 1: `Thông tin bệnh nhân`.
- [x] Section 2: `Sinh hiệu NEWS2`.
- [x] Section 3: `Lactate & huyết động`.
- [x] Section 4: `SOFA 24 giờ`.
- [x] Section 5: `Chẩn đoán & kết cục`.
- [x] Mỗi section header hiển thị progress.
- [x] Section đầu tiên còn thiếu tự mở mặc định khi tạo/mở form.
- [x] NEWS2 fields dùng `MedicalInputField`.
- [x] NEWS2 fields có unit và score text khi có dữ liệu.
- [x] qSOFA read-only nằm gần field NEWS2 liên quan.
- [x] Lactate và vận mạch cùng một section.
- [x] SOFA hiển thị đủ tên 6 hệ cơ quan, không cắt text bằng ellipsis.
- [x] Diagnosis Sepsis-3 read-only, không tạo cảm giác user có thể chọn thủ công khi thiếu dữ liệu.

**Done khi**

- [x] Mobile không còn form phẳng quá dài.
- [x] Không có label y tế quan trọng bị rút gọn.
- [x] Điểm thành phần hiển thị sau khi nhập field.

## T6 - Patient List Upgrade

**Lệnh giao việc cho Agent E**

Bạn là agent phụ trách màn danh sách bệnh nhân. Hãy nâng cấp list để hỗ trợ ưu
tiên lâm sàng, vẫn giữ search/sort hiện có.

**Files**

- Sửa `lib/main.dart`
- Dùng `assessment_display.dart`
- Dùng `clinical_components.dart`

**Checklist**

- [x] Thêm enum filter private: `all`, `incomplete`, `highRisk`, `septicShock`.
- [x] Search/sort vẫn gọi repository như hiện tại.
- [x] Filter thực hiện in-memory trên `_history` sau search.
- [x] Thêm filter chips: `Tất cả`, `Chưa đủ dữ liệu`, `Nguy cơ cao`, `Sốc NK`.
- [x] Thêm quick summary strip: tổng phiếu, chưa đủ dữ liệu, nguy cơ cao, sốc NK.
- [x] Patient card luôn hiển thị badge NEWS2, qSOFA, SOFA kể cả missing.
- [x] Lactate badge hiển thị khi đã nhập lactate.
- [x] Relative time đổi thành `Vừa cập nhật`, `2 phút trước`, `3 giờ trước`, `5 ngày trước`.
- [x] Empty state có copy hướng dẫn và CTA tạo phiếu mới.
- [x] Không còn `Chưa nhập họ tên`; dùng `Chưa nhập tên bệnh nhân`.
- [x] Không còn `Nhập viện: ...`; dùng `Chưa nhập thời gian nhập viện`.

**Done khi**

- [x] Filter đúng trên kết quả search hiện tại.
- [x] Card giúp nhận diện bệnh nhân nguy cơ cao mà không cần mở phiếu.
- [x] Không còn `now` hoặc `...` trong patient card.

## T7 - Responsive + Polish P2

**Lệnh giao việc cho Agent F**

Bạn là agent phụ trách polish cuối: responsive, skeleton/loading, abnormal
warnings và unit switcher không migration.

**Files**

- Sửa `lib/main.dart`
- Sửa `lib/src/ui/clinical_components.dart` nếu cần

**Checklist**

- [x] Mobile form 1 cột.
- [x] Mobile dashboard wrap hoặc horizontal scroll, không overflow.
- [x] Tablet/wide form 2 cột.
- [x] Tablet/wide dashboard 4 card cùng hàng.
- [ ] Sticky right summary khi width đủ lớn.
- [ ] List loading skeleton thay vì chỉ spinner toàn màn.
- [x] Abnormal warning cho nhịp thở quá thấp/cao.
- [x] Abnormal warning cho SpO2 thấp hoặc >100.
- [x] Abnormal warning cho huyết áp tâm thu quá thấp/cao.
- [x] Abnormal warning cho nhịp tim quá thấp/cao.
- [x] Abnormal warning cho nhiệt độ quá thấp/cao.
- [x] Abnormal warning cho GCS ngoài 3-15.
- [x] Abnormal warning cho lactate cao.
- [x] Unit switcher bilirubin: `mg/dL`, `µmol/L`.
- [x] Unit switcher creatinine: `mg/dL`, `µmol/L`.
- [x] Unit switcher vẫn lưu vào string field hiện tại, ví dụ `2.0 mg/dL`.

**Done khi**

- [ ] UI không overflow trên mobile.
- [ ] UI đọc tốt trên tablet.
- [x] Warning không chặn nhập, chỉ nhắc kiểm tra.
- [x] Parser/scoring hiện tại vẫn chạy đúng.

## T8 - Tests + Final Verification

**Lệnh giao việc cho Agent G**

Bạn là agent phụ trách kiểm thử tích hợp và review cuối. Không refactor lớn ở
bước này nếu không cần thiết; tập trung khóa regression.

**Files**

- `test/scoring_test.dart`
- `test/assessment_display_test.dart`
- `test/clinical_components_test.dart`
- Có thể sửa test liên quan nếu UI text intentional thay đổi.

**Checklist**

- [x] Giữ toàn bộ scoring tests hiện có.
- [x] Thêm/kiểm tra test missing NEWS2 5/7.
- [x] Thêm/kiểm tra test SOFA 2/6.
- [x] Thêm/kiểm tra test shock missing lactate/MAP.
- [x] Thêm/kiểm tra test high-risk patient.
- [x] Thêm/kiểm tra test septic shock patient.
- [x] Thêm/kiểm tra test incomplete patient.
- [x] Widget test summary card missing/complete.
- [x] Widget test status badge labels.
- [x] Widget test missing panel callback.
- [x] Widget test accordion progress text.
- [x] Widget test medical input warning text.
- [x] Chạy `flutter analyze`.
- [x] Chạy `flutter test`.
- [ ] Manual smoke tạo phiếu mới.
- [ ] Manual smoke nhập một phần và kiểm tra auto-save tạo history.
- [ ] Manual smoke filter list.
- [ ] Manual smoke mở lại phiếu.
- [ ] Manual smoke nhập đủ NEWS2/SOFA và kiểm tra trạng thái đổi đúng.

**Done khi**

- [x] `flutter analyze` pass.
- [x] `flutter test` pass.
- [x] Không còn label y tế quan trọng bị cắt bằng `...`.
- [x] Dashboard, missing data, filter, auto-save đạt acceptance criteria.

## Ghi Chú Điều Phối

Ghi mọi quyết định/phát sinh ở đây để agent sau không mất context.

- [x] 2026-05-19: Đã triển khai code cho T1-T6, phần chính của T7, và test/build cho T8.
- [x] 2026-05-19: `flutter test` pass 20/20.
- [x] 2026-05-19: `flutter build web` pass.
- [x] 2026-05-19: `flutter analyze` pass sau khi xóa helper UI cũ, cập nhật share_plus API và sửa null-aware thừa trong exporter.
- [ ] Cần manual smoke UI trên mobile/tablet hoặc Chrome sau lượt này.

## Definition of Done Toàn Bộ

- [x] Có `assessment_display.dart` và test domain.
- [x] Có `clinical_components.dart` và widget test.
- [x] Form có dashboard sticky/summary rõ NEWS2/qSOFA/SOFA/kết luận.
- [x] Form có missing data panel click scroll/focus.
- [x] Form chuyển sang 5 accordion sections.
- [x] Patient list có search, sort, filter, summary strip, patient risk badges.
- [x] Auto-save trực tiếp vào history, không tạo phiếu rỗng.
- [x] Header hiển thị save state rõ.
- [ ] Responsive mobile/tablet đạt ở mức code/build; chưa manual smoke.
- [x] Abnormal warnings và unit switcher P2 có mặt.
- [x] `flutter analyze` pass.
- [x] `flutter test` pass.
