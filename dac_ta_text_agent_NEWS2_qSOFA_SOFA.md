# ĐẶC TẢ VĂN BẢN CHO AI AGENT: TÍNH ĐIỂM NEWS2, qSOFA, SOFA

## 0. Mục tiêu

Tài liệu này dùng làm ngữ cảnh cho AI agent hoặc developer xây dựng app hỗ trợ đánh giá nhanh người bệnh.

Agent cần thực hiện 4 việc chính:

1. Thu thập dữ liệu đầu vào từ người dùng hoặc hệ thống HIS/EMR.
2. Tính điểm theo từng thang: NEWS2, qSOFA, SOFA.
3. Diễn giải mức nguy cơ theo tổng điểm.
4. Đề xuất mức phản ứng phù hợp, nhưng không thay thế quyết định của bác sĩ.

Các thang điểm trong tài liệu này chỉ là công cụ hỗ trợ sàng lọc, cảnh báo sớm và phân tầng nguy cơ.

---

# 1. NGUYÊN TẮC CHUNG CHO AGENT

## 1.1. Quy tắc xử lý dữ liệu thiếu

Nếu thiếu dữ liệu bắt buộc:

- Không tự đoán giá trị.
- Không tính điểm hoàn chỉnh nếu thiếu thông số cần thiết.
- Trả về danh sách trường còn thiếu.
- Có thể tính điểm tạm thời nếu người dùng cho phép, nhưng phải ghi rõ là "điểm chưa đầy đủ".

Ví dụ:

```json
{
  "status": "missing_required_inputs",
  "missing_fields": ["respiratory_rate", "systolic_bp"],
  "message": "Chưa đủ dữ liệu để tính NEWS2 hoàn chỉnh."
}
```

## 1.2. Quy tắc xử lý đơn vị

Agent phải kiểm tra đơn vị:

| Thông số | Đơn vị chuẩn |
|---|---|
| Nhịp thở | lần/phút |
| SpO2 | % |
| Nhiệt độ | °C |
| Huyết áp tâm thu | mmHg |
| Mạch | lần/phút |
| PaO2 | mmHg hoặc kPa |
| FiO2 | dạng thập phân, ví dụ 0.21, 0.4, 1.0 |
| Creatinine | mg/dL hoặc µmol/L |
| Bilirubin | mg/dL hoặc µmol/L |
| Tiểu cầu | x10^3/µL hoặc x10^9/L |
| Nước tiểu | mL/ngày |
| Glasgow | 3–15 điểm |

Nếu đơn vị khác chuẩn, agent phải chuyển đổi trước khi tính.

## 1.3. Quy tắc trả lời

Kết quả nên trả về theo cấu trúc:

```json
{
  "scale": "NEWS2",
  "total_score": 7,
  "risk_level": "high",
  "interpretation": "Nguy cơ cao",
  "recommendation": "Cần đánh giá khẩn cấp bởi bác sĩ/cấp cứu nội viện.",
  "component_scores": [
    {
      "name": "respiratory_rate",
      "value": 28,
      "score": 3,
      "reason": "Nhịp thở >= 25 lần/phút"
    }
  ],
  "warnings": [
    "Công cụ chỉ hỗ trợ đánh giá nhanh, không thay thế bác sĩ."
  ]
}
```

---

# 2. THANG ĐIỂM NEWS2

## 2.1. Mục đích

NEWS2 dùng để phát hiện sớm tình trạng bệnh nhân xấu đi dựa trên các dấu hiệu sinh tồn.

## 2.2. Dữ liệu đầu vào NEWS2

| Trường | Bắt buộc | Kiểu dữ liệu | Mô tả |
|---|---:|---|---|
| respiratory_rate | Có | number | Nhịp thở, lần/phút |
| spo2 | Có | number | Độ bão hòa oxy máu, % |
| spo2_scale | Có | enum | `scale1` hoặc `scale2` |
| supplemental_oxygen | Có | boolean | Có thở oxy hay không |
| systolic_bp | Có | number | Huyết áp tâm thu, mmHg |
| pulse | Có | number | Mạch, lần/phút |
| consciousness | Có | enum | `alert`, `new_confusion`, `voice`, `pain`, `unresponsive` |
| temperature | Có | number | Nhiệt độ, °C |

## 2.3. NEWS2: Nhịp thở

| Điều kiện | Điểm |
|---|---:|
| <= 8 | 3 |
| 9–11 | 1 |
| 12–20 | 0 |
| 21–24 | 2 |
| >= 25 | 3 |

```yaml
respiratory_rate:
  - if: value <= 8
    score: 3
  - if: 9 <= value <= 11
    score: 1
  - if: 12 <= value <= 20
    score: 0
  - if: 21 <= value <= 24
    score: 2
  - if: value >= 25
    score: 3
```

## 2.4. NEWS2: SpO2 Scale 1

Dùng cho đa số bệnh nhân.

| Điều kiện SpO2 | Điểm |
|---|---:|
| <= 91 | 3 |
| 92–93 | 2 |
| 94–95 | 1 |
| >= 96 | 0 |

```yaml
spo2_scale1:
  - if: value <= 91
    score: 3
  - if: 92 <= value <= 93
    score: 2
  - if: 94 <= value <= 95
    score: 1
  - if: value >= 96
    score: 0
```

## 2.5. NEWS2: SpO2 Scale 2

Dùng cho bệnh nhân có nguy cơ suy hô hấp tăng CO2, ví dụ COPD giữ CO2, nếu bác sĩ chỉ định.

| Điều kiện SpO2 | Điểm |
|---|---:|
| <= 83 | 3 |
| 84–85 | 2 |
| 86–87 | 1 |
| 88–92 | 0 |
| 93–94 | 1 |
| 95–96 | 2 |
| >= 97 | 3 |

```yaml
spo2_scale2:
  - if: value <= 83
    score: 3
  - if: 84 <= value <= 85
    score: 2
  - if: 86 <= value <= 87
    score: 1
  - if: 88 <= value <= 92
    score: 0
  - if: 93 <= value <= 94
    score: 1
  - if: 95 <= value <= 96
    score: 2
  - if: value >= 97
    score: 3
```

## 2.6. NEWS2: Oxy bổ sung

| Điều kiện | Điểm |
|---|---:|
| Không thở oxy | 0 |
| Có thở oxy | 2 |

```yaml
supplemental_oxygen:
  - if: value == false
    score: 0
  - if: value == true
    score: 2
```

## 2.7. NEWS2: Huyết áp tâm thu

| Điều kiện SBP | Điểm |
|---|---:|
| <= 90 | 3 |
| 91–100 | 2 |
| 101–110 | 1 |
| 111–219 | 0 |
| >= 220 | 3 |

```yaml
systolic_bp:
  - if: value <= 90
    score: 3
  - if: 91 <= value <= 100
    score: 2
  - if: 101 <= value <= 110
    score: 1
  - if: 111 <= value <= 219
    score: 0
  - if: value >= 220
    score: 3
```

## 2.8. NEWS2: Mạch

| Điều kiện mạch | Điểm |
|---|---:|
| <= 40 | 3 |
| 41–50 | 1 |
| 51–90 | 0 |
| 91–110 | 1 |
| 111–130 | 2 |
| >= 131 | 3 |

```yaml
pulse:
  - if: value <= 40
    score: 3
  - if: 41 <= value <= 50
    score: 1
  - if: 51 <= value <= 90
    score: 0
  - if: 91 <= value <= 110
    score: 1
  - if: 111 <= value <= 130
    score: 2
  - if: value >= 131
    score: 3
```

## 2.9. NEWS2: Ý thức

| Trạng thái | Điểm |
|---|---:|
| Alert | 0 |
| New confusion | 3 |
| Voice | 3 |
| Pain | 3 |
| Unresponsive | 3 |

```yaml
consciousness:
  - if: value == "alert"
    score: 0
  - if: value in ["new_confusion", "voice", "pain", "unresponsive"]
    score: 3
```

## 2.10. NEWS2: Nhiệt độ

| Điều kiện nhiệt độ | Điểm |
|---|---:|
| <= 35.0 | 3 |
| 35.1–36.0 | 1 |
| 36.1–38.0 | 0 |
| 38.1–39.0 | 1 |
| >= 39.1 | 2 |

```yaml
temperature:
  - if: value <= 35.0
    score: 3
  - if: 35.1 <= value <= 36.0
    score: 1
  - if: 36.1 <= value <= 38.0
    score: 0
  - if: 38.1 <= value <= 39.0
    score: 1
  - if: value >= 39.1
    score: 2
```

## 2.11. Công thức NEWS2

```text
NEWS2_total =
  respiratory_rate_score
+ spo2_score
+ supplemental_oxygen_score
+ systolic_bp_score
+ pulse_score
+ consciousness_score
+ temperature_score
```

## 2.12. Diễn giải NEWS2

| Tổng điểm | Mức nguy cơ | Ý nghĩa | Gợi ý phản ứng |
|---:|---|---|---|
| 0 | Rất thấp | Sinh hiệu ổn định | Theo dõi định kỳ |
| 1–4 | Thấp | Có bất thường nhẹ | Điều dưỡng/bác sĩ đánh giá theo quy trình |
| Bất kỳ thông số = 3 | Điểm đỏ | Một thông số rất bất thường | Cần đánh giá sớm |
| 5–6 | Trung bình | Nguy cơ diễn biến xấu | Tăng tần suất theo dõi, bác sĩ đánh giá khẩn |
| >= 7 | Cao | Nguy cơ cao, có thể cần hồi sức/cấp cứu | Kích hoạt phản ứng khẩn/cấp cứu nội viện |

```yaml
news2_interpretation:
  - if: total_score == 0
    risk_level: very_low
    action: routine_monitoring
  - if: 1 <= total_score <= 4 and no_component_score_3
    risk_level: low
    action: clinical_review_by_protocol
  - if: any_component_score == 3 and total_score < 5
    risk_level: red_score
    action: urgent_clinical_review
  - if: 5 <= total_score <= 6
    risk_level: medium
    action: urgent_review_and_increase_monitoring
  - if: total_score >= 7
    risk_level: high
    action: emergency_response
```

---

# 3. THANG ĐIỂM qSOFA

## 3.1. Mục đích

qSOFA là công cụ đánh giá nhanh nguy cơ xấu ở bệnh nhân nghi nhiễm trùng, đặc biệt ngoài ICU.

## 3.2. Dữ liệu đầu vào qSOFA

| Trường | Bắt buộc | Kiểu dữ liệu | Mô tả |
|---|---:|---|---|
| respiratory_rate | Có | number | Nhịp thở, lần/phút |
| systolic_bp | Có | number | Huyết áp tâm thu, mmHg |
| altered_mental_status | Có | boolean | Thay đổi ý thức hay không |

## 3.3. Tiêu chí qSOFA

| Tiêu chí | Điều kiện | Điểm |
|---|---|---:|
| Nhịp thở nhanh | respiratory_rate >= 22 | 1 |
| Huyết áp thấp | systolic_bp <= 100 | 1 |
| Thay đổi ý thức | altered_mental_status = true | 1 |

```yaml
qsofa:
  respiratory_rate:
    if: respiratory_rate >= 22
    score: 1
    else_score: 0
  systolic_bp:
    if: systolic_bp <= 100
    score: 1
    else_score: 0
  altered_mental_status:
    if: altered_mental_status == true
    score: 1
    else_score: 0
```

## 3.4. Công thức qSOFA

```text
qSOFA_total = respiratory_rate_score + systolic_bp_score + altered_mental_status_score
```

Tổng điểm: 0–3.

## 3.5. Diễn giải qSOFA

| Tổng điểm | Mức nguy cơ | Ý nghĩa | Gợi ý phản ứng |
|---:|---|---|---|
| 0–1 | Chưa đủ ngưỡng nguy cơ cao | Không loại trừ nhiễm trùng nặng | Tiếp tục đánh giá lâm sàng |
| >= 2 | Nguy cơ cao | Có nguy cơ kết cục xấu ở bệnh nhân nghi nhiễm trùng | Đánh giá nhiễm trùng, rối loạn cơ quan, cân nhắc sepsis pathway |

```yaml
qsofa_interpretation:
  - if: total_score <= 1
    risk_level: not_high_by_qsofa
    action: continue_clinical_assessment
  - if: total_score >= 2
    risk_level: high
    action: evaluate_for_sepsis_and_organ_dysfunction
```

---

# 4. THANG ĐIỂM SOFA

## 4.1. Mục đích

SOFA đánh giá mức độ rối loạn chức năng cơ quan. SOFA gồm 6 hệ cơ quan, mỗi hệ 0–4 điểm.

Các hệ cơ quan:

1. Hô hấp
2. Đông máu
3. Gan
4. Tim mạch
5. Thần kinh trung ương
6. Thận

Tổng điểm SOFA: 0–24.

## 4.2. Dữ liệu đầu vào SOFA

| Trường | Bắt buộc | Kiểu dữ liệu | Mô tả |
|---|---:|---|---|
| pao2 | Có nếu tính hô hấp | number | PaO2 |
| fio2 | Có nếu tính hô hấp | number | FiO2 dạng 0.21–1.0 |
| respiratory_support | Có | boolean | Có hỗ trợ hô hấp hay không |
| platelet | Có | number | Tiểu cầu |
| bilirubin | Có | number | Bilirubin |
| mean_arterial_pressure | Có | number | Huyết áp trung bình MAP |
| vasopressor_type | Không | enum | dopamine, dobutamine, epinephrine, norepinephrine |
| vasopressor_dose | Không | number | Liều thuốc vận mạch |
| gcs | Có | number | Glasgow Coma Scale |
| creatinine | Có | number | Creatinine |
| urine_output | Không | number | Nước tiểu mL/ngày |
| baseline_sofa | Không | number | SOFA nền, mặc định 0 nếu chưa rõ |

## 4.3. SOFA: Hô hấp

Tính tỷ lệ:

```text
pao2_fio2_ratio = PaO2 / FiO2
```

Nếu PaO2 dùng kPa:

```text
PaO2_mmHg = PaO2_kPa * 7.50062
```

| PaO2/FiO2 | Điều kiện bổ sung | Điểm |
|---|---|---:|
| >= 400 | Không | 0 |
| < 400 | Không | 1 |
| < 300 | Không | 2 |
| < 200 | Có hỗ trợ hô hấp | 3 |
| < 100 | Có hỗ trợ hô hấp | 4 |

```yaml
sofa_respiratory:
  - if: pao2_fio2_ratio < 100 and respiratory_support == true
    score: 4
  - else_if: pao2_fio2_ratio < 200 and respiratory_support == true
    score: 3
  - else_if: pao2_fio2_ratio < 300
    score: 2
  - else_if: pao2_fio2_ratio < 400
    score: 1
  - else:
    score: 0
```

## 4.4. SOFA: Đông máu

| Tiểu cầu | Điểm |
|---|---:|
| >= 150 | 0 |
| < 150 | 1 |
| < 100 | 2 |
| < 50 | 3 |
| < 20 | 4 |

```yaml
sofa_coagulation:
  - if: platelet < 20
    score: 4
  - else_if: platelet < 50
    score: 3
  - else_if: platelet < 100
    score: 2
  - else_if: platelet < 150
    score: 1
  - else:
    score: 0
```

## 4.5. SOFA: Gan

Nếu bilirubin đơn vị µmol/L:

```text
bilirubin_mg_dl = bilirubin_umol_l / 17.1
```

| Bilirubin mg/dL | Điểm |
|---|---:|
| < 1.2 | 0 |
| 1.2–1.9 | 1 |
| 2.0–5.9 | 2 |
| 6.0–11.9 | 3 |
| >= 12.0 | 4 |

```yaml
sofa_liver:
  - if: bilirubin_mg_dl >= 12.0
    score: 4
  - else_if: 6.0 <= bilirubin_mg_dl <= 11.9
    score: 3
  - else_if: 2.0 <= bilirubin_mg_dl <= 5.9
    score: 2
  - else_if: 1.2 <= bilirubin_mg_dl <= 1.9
    score: 1
  - else:
    score: 0
```

## 4.6. SOFA: Tim mạch

| Điều kiện | Điểm |
|---|---:|
| MAP >= 70 mmHg và không dùng vận mạch | 0 |
| MAP < 70 mmHg | 1 |
| Dopamine <= 5 hoặc Dobutamine bất kỳ liều | 2 |
| Dopamine > 5 hoặc Epinephrine <= 0.1 hoặc Norepinephrine <= 0.1 | 3 |
| Dopamine > 15 hoặc Epinephrine > 0.1 hoặc Norepinephrine > 0.1 | 4 |

```yaml
sofa_cardiovascular:
  - if: dopamine_dose > 15
    score: 4
  - else_if: epinephrine_dose > 0.1
    score: 4
  - else_if: norepinephrine_dose > 0.1
    score: 4
  - else_if: dopamine_dose > 5
    score: 3
  - else_if: epinephrine_dose > 0 and epinephrine_dose <= 0.1
    score: 3
  - else_if: norepinephrine_dose > 0 and norepinephrine_dose <= 0.1
    score: 3
  - else_if: dopamine_dose > 0 and dopamine_dose <= 5
    score: 2
  - else_if: dobutamine_dose > 0
    score: 2
  - else_if: mean_arterial_pressure < 70
    score: 1
  - else:
    score: 0
```

Ghi chú: liều thuốc vận mạch thường tính theo µg/kg/phút.

## 4.7. SOFA: Thần kinh trung ương

| GCS | Điểm |
|---|---:|
| 15 | 0 |
| 13–14 | 1 |
| 10–12 | 2 |
| 6–9 | 3 |
| < 6 | 4 |

```yaml
sofa_cns:
  - if: gcs < 6
    score: 4
  - else_if: 6 <= gcs <= 9
    score: 3
  - else_if: 10 <= gcs <= 12
    score: 2
  - else_if: 13 <= gcs <= 14
    score: 1
  - else_if: gcs == 15
    score: 0
```

## 4.8. SOFA: Thận

Nếu creatinine dùng µmol/L:

```text
creatinine_mg_dl = creatinine_umol_l / 88.4
```

| Creatinine mg/dL | Nước tiểu | Điểm |
|---|---|---:|
| < 1.2 | Không xét | 0 |
| 1.2–1.9 | Không xét | 1 |
| 2.0–3.4 | Không xét | 2 |
| 3.5–4.9 | < 500 mL/ngày | 3 |
| >= 5.0 | < 200 mL/ngày | 4 |

```yaml
sofa_renal_by_creatinine:
  - if: creatinine_mg_dl >= 5.0
    score: 4
  - else_if: 3.5 <= creatinine_mg_dl <= 4.9
    score: 3
  - else_if: 2.0 <= creatinine_mg_dl <= 3.4
    score: 2
  - else_if: 1.2 <= creatinine_mg_dl <= 1.9
    score: 1
  - else:
    score: 0

sofa_renal_by_urine:
  - if: urine_output_ml_day < 200
    score: 4
  - else_if: urine_output_ml_day < 500
    score: 3
  - else:
    score: 0

sofa_renal_final:
  score: max(renal_by_creatinine_score, renal_by_urine_score)
```

## 4.9. Công thức SOFA

```text
SOFA_total =
  respiratory_score
+ coagulation_score
+ liver_score
+ cardiovascular_score
+ cns_score
+ renal_score
```

## 4.10. Delta SOFA

```text
delta_SOFA = current_SOFA - baseline_SOFA
```

Nếu chưa biết SOFA nền, có thể mặc định baseline_SOFA = 0, nhưng phải ghi chú.

## 4.11. Diễn giải SOFA

| Điều kiện | Ý nghĩa |
|---|---|
| SOFA càng cao | Rối loạn chức năng cơ quan càng nặng |
| delta_SOFA >= 2 trong bối cảnh nghi nhiễm trùng | Gợi ý rối loạn chức năng cơ quan liên quan nhiễm trùng |
| SOFA ban đầu < 9 | Nguy cơ tử vong thấp hơn nhóm điểm cao |
| SOFA ban đầu 9–11 | Nguy cơ trung gian |
| SOFA ban đầu > 11 | Nguy cơ tử vong rất cao |

```yaml
sofa_interpretation:
  - if: delta_sofa >= 2 and suspected_infection == true
    sepsis_related_organ_dysfunction: true
    action: evaluate_sepsis_pathway
  - if: total_score < 9
    mortality_risk_group: lower
  - if: 9 <= total_score <= 11
    mortality_risk_group: intermediate
  - if: total_score > 11
    mortality_risk_group: very_high
```

---

# 5. LOGIC GỢI Ý CHỌN THANG ĐIỂM

## 5.1. Khi cần cảnh báo sớm bệnh nhân xấu đi

Dùng NEWS2.

Ví dụ:
- Bệnh nhân nội trú.
- Điều dưỡng nhập dấu hiệu sinh tồn.
- Cần phát hiện bệnh nhân có nguy cơ diễn biến xấu.

## 5.2. Khi nghi nhiễm trùng/sepsis và cần sàng lọc nhanh

Dùng qSOFA.

Ví dụ:
- Bệnh nhân sốt, nghi nhiễm trùng.
- Bệnh nhân ở cấp cứu hoặc khoa thường.
- Cần nhận diện nhanh nguy cơ kết cục xấu.

## 5.3. Khi cần đánh giá rối loạn cơ quan

Dùng SOFA.

Ví dụ:
- Bệnh nhân nghi sepsis.
- Có dữ liệu xét nghiệm.
- Cần đánh giá mức độ suy cơ quan.
- Cần theo dõi delta SOFA.

## 5.4. Luồng đề xuất

```text
Nếu có dấu hiệu sinh tồn cơ bản:
  Tính NEWS2.

Nếu nghi nhiễm trùng:
  Tính qSOFA.
  Nếu có xét nghiệm và dữ liệu cơ quan:
    Tính SOFA.
    Tính delta SOFA nếu có baseline.

Nếu NEWS2 >= 7 hoặc qSOFA >= 2 hoặc delta SOFA >= 2:
  Gắn nhãn cần đánh giá khẩn.
```

---

# 6. MẪU OUTPUT CHUẨN CHO AGENT

```json
{
  "patient_context": {
    "suspected_infection": true,
    "location": "emergency_department"
  },
  "scores": {
    "NEWS2": {
      "total": 7,
      "risk_level": "high",
      "interpretation": "Nguy cơ cao"
    },
    "qSOFA": {
      "total": 2,
      "risk_level": "high",
      "interpretation": "Nguy cơ cao ở bệnh nhân nghi nhiễm trùng"
    },
    "SOFA": {
      "total": 8,
      "baseline": 2,
      "delta": 6,
      "interpretation": "Tăng SOFA >= 2, gợi ý rối loạn cơ quan liên quan nhiễm trùng"
    }
  },
  "overall_alert": {
    "level": "urgent",
    "reason": [
      "NEWS2 >= 7",
      "qSOFA >= 2",
      "delta SOFA >= 2"
    ],
    "recommendation": "Cần bác sĩ đánh giá khẩn, cân nhắc quy trình sepsis/cấp cứu nội viện."
  },
  "safety_note": "Kết quả chỉ hỗ trợ đánh giá nhanh, không thay thế chẩn đoán và quyết định điều trị của bác sĩ."
}
```

## 6.2. Output khi thiếu dữ liệu

```json
{
  "status": "incomplete",
  "can_calculate": false,
  "scale": "SOFA",
  "missing_fields": [
    "platelet",
    "bilirubin",
    "gcs"
  ],
  "message": "Chưa đủ dữ liệu để tính SOFA hoàn chỉnh.",
  "suggested_next_questions": [
    "Số lượng tiểu cầu là bao nhiêu?",
    "Bilirubin là bao nhiêu?",
    "Điểm Glasgow là bao nhiêu?"
  ]
}
```

---

# 7. TEST CASES CHO DEVELOPER

## 7.1. NEWS2 test case

Input:

```json
{
  "respiratory_rate": 28,
  "spo2": 90,
  "spo2_scale": "scale1",
  "supplemental_oxygen": true,
  "systolic_bp": 95,
  "pulse": 120,
  "consciousness": "alert",
  "temperature": 38.5
}
```

Expected component scores:

```json
{
  "respiratory_rate": 3,
  "spo2": 3,
  "supplemental_oxygen": 2,
  "systolic_bp": 2,
  "pulse": 2,
  "consciousness": 0,
  "temperature": 1,
  "NEWS2_total": 13,
  "risk_level": "high"
}
```

## 7.2. qSOFA test case

Input:

```json
{
  "respiratory_rate": 24,
  "systolic_bp": 90,
  "altered_mental_status": false
}
```

Expected:

```json
{
  "respiratory_rate_score": 1,
  "systolic_bp_score": 1,
  "altered_mental_status_score": 0,
  "qSOFA_total": 2,
  "risk_level": "high"
}
```

## 7.3. SOFA test case

Input:

```json
{
  "pao2": 80,
  "fio2": 0.4,
  "respiratory_support": true,
  "platelet": 80,
  "bilirubin_mg_dl": 3.0,
  "mean_arterial_pressure": 65,
  "vasopressors": [],
  "gcs": 12,
  "creatinine_mg_dl": 2.5,
  "urine_output_ml_day": 900,
  "baseline_sofa": 0,
  "suspected_infection": true
}
```

Expected:

```json
{
  "pao2_fio2_ratio": 200,
  "respiratory_score": 2,
  "coagulation_score": 2,
  "liver_score": 2,
  "cardiovascular_score": 1,
  "cns_score": 2,
  "renal_score": 2,
  "SOFA_total": 11,
  "delta_SOFA": 11,
  "sepsis_related_organ_dysfunction": true,
  "mortality_risk_group": "intermediate"
}
```

---

# 8. CẢNH BÁO AN TOÀN LÂM SÀNG

Agent/app phải luôn hiển thị ghi chú:

```text
Các thang điểm NEWS2, qSOFA và SOFA chỉ hỗ trợ đánh giá nhanh, sàng lọc và phân tầng nguy cơ. Kết quả không thay thế đánh giá lâm sàng, chẩn đoán hoặc quyết định điều trị của bác sĩ.
```

Không được dùng các thang điểm này để tự động kết luận:

- Bệnh nhân chắc chắn bị sepsis.
- Bệnh nhân chắc chắn không bị sepsis.
- Bệnh nhân chắc chắn cần hoặc không cần ICU.
- Có thể trì hoãn xử trí nếu bác sĩ đánh giá tình trạng nguy cấp.

---

# 9. THIẾT KẾ FORM NHẬP LIỆU GỢI Ý

## 9.1. Form tối thiểu cho NEWS2 + qSOFA

```yaml
vital_signs:
  respiratory_rate:
    label: "Nhịp thở"
    unit: "lần/phút"
    required: true
  spo2:
    label: "SpO2"
    unit: "%"
    required: true
  spo2_scale:
    label: "Thang SpO2"
    options: [scale1, scale2]
    default: scale1
    required: true
  supplemental_oxygen:
    label: "Có thở oxy?"
    type: boolean
    required: true
  systolic_bp:
    label: "Huyết áp tâm thu"
    unit: "mmHg"
    required: true
  pulse:
    label: "Mạch"
    unit: "lần/phút"
    required: true
  temperature:
    label: "Nhiệt độ"
    unit: "°C"
    required: true
  consciousness:
    label: "Ý thức"
    options: [alert, new_confusion, voice, pain, unresponsive]
    required: true
  suspected_infection:
    label: "Nghi nhiễm trùng?"
    type: boolean
    required: false
```

## 9.2. Form mở rộng cho SOFA

```yaml
organ_function:
  pao2:
    label: "PaO2"
    unit: "mmHg"
    required: conditional
  fio2:
    label: "FiO2"
    unit: "decimal"
    required: conditional
  respiratory_support:
    label: "Có hỗ trợ hô hấp?"
    type: boolean
    required: true
  platelet:
    label: "Tiểu cầu"
    unit: "x10^3/uL"
    required: true
  bilirubin:
    label: "Bilirubin"
    unit: "mg/dL"
    required: true
  mean_arterial_pressure:
    label: "MAP"
    unit: "mmHg"
    required: true
  vasopressors:
    label: "Thuốc vận mạch"
    type: list
    required: false
  gcs:
    label: "Glasgow"
    unit: "score"
    required: true
  creatinine:
    label: "Creatinine"
    unit: "mg/dL"
    required: true
  urine_output:
    label: "Nước tiểu 24 giờ"
    unit: "mL/day"
    required: false
  baseline_sofa:
    label: "SOFA nền"
    type: number
    default: 0
    required: false
```

---

# 10. PSEUDOCODE TRIỂN KHAI

```pseudo
function calculate_all_scores(input):
    result = {}

    if has_required_news2_fields(input):
        result.NEWS2 = calculate_news2(input)
    else:
        result.NEWS2 = missing_fields_response("NEWS2")

    if has_required_qsofa_fields(input):
        result.qSOFA = calculate_qsofa(input)
    else:
        result.qSOFA = missing_fields_response("qSOFA")

    if has_required_sofa_fields(input):
        result.SOFA = calculate_sofa(input)
    else:
        result.SOFA = missing_fields_response("SOFA")

    result.overall_alert = combine_alerts(result)

    return result

function combine_alerts(result):
    reasons = []

    if result.NEWS2.total >= 7:
        reasons.append("NEWS2 >= 7")

    if result.NEWS2.any_component_score == 3:
        reasons.append("NEWS2 có điểm đỏ")

    if result.qSOFA.total >= 2:
        reasons.append("qSOFA >= 2")

    if result.SOFA.delta >= 2 and input.suspected_infection == true:
        reasons.append("Delta SOFA >= 2 trong bối cảnh nghi nhiễm trùng")

    if reasons contains any high risk:
        return {
            level: "urgent",
            reasons: reasons,
            recommendation: "Cần bác sĩ đánh giá khẩn."
        }

    return {
        level: "routine_or_monitor",
        reasons: reasons,
        recommendation: "Tiếp tục theo dõi và đánh giá theo lâm sàng."
    }
```
