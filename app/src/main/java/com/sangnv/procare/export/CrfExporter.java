package com.sangnv.procare.export;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.RectF;
import android.graphics.Typeface;
import android.graphics.pdf.PdfDocument;
import android.os.Environment;

import com.sangnv.procare.Model.ClinicalAssessment;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

public final class CrfExporter {
    public enum Format {
        PDF("pdf", "application/pdf"),
        DOCX("docx", "application/vnd.openxmlformats-officedocument.wordprocessingml.document");

        public final String extension;
        public final String mimeType;

        Format(String extension, String mimeType) {
            this.extension = extension;
            this.mimeType = mimeType;
        }
    }

    private static final int PAGE_WIDTH = 612;
    private static final int PAGE_HEIGHT = 792;
    private static final int MARGIN = 42;
    private static final int LINE = 16;
    private static final int HIGHLIGHT = 0xFFFFE5CC;

    private CrfExporter() {
    }

    public static File export(Context context, ClinicalAssessment assessment, Format format) throws IOException {
        ClinicalAssessment safeAssessment = assessment == null ? new ClinicalAssessment() : assessment;
        File directory = context.getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS);
        if (directory == null) {
            directory = context.getFilesDir();
        }
        if (!directory.exists() && !directory.mkdirs()) {
            throw new IOException("Cannot create export directory.");
        }
        File file = new File(directory, buildFileName(safeAssessment, format));
        if (format == Format.PDF) {
            writePdf(file, safeAssessment);
        } else {
            writeDocx(file, safeAssessment);
        }
        return file;
    }

    public static String buildFileName(ClinicalAssessment assessment, Format format) {
        ClinicalAssessment safeAssessment = assessment == null ? new ClinicalAssessment() : assessment;
        String identity = firstText(safeAssessment.patientId, safeAssessment.fullName, "benh-nhan");
        String timestamp = new SimpleDateFormat("yyyyMMdd-HHmm", Locale.US).format(new Date());
        return "NEWS2-L-" + sanitizeFileName(identity) + "-" + timestamp + "." + format.extension;
    }

    public static String sanitizeFileName(String value) {
        String normalized = value == null ? "" : value.trim();
        if (normalized.isEmpty()) {
            return "benh-nhan";
        }
        String safe = normalized.replaceAll("[^\\p{L}\\p{N}._-]+", "-")
                .replaceAll("-{2,}", "-")
                .replaceAll("^-|-$", "");
        return safe.isEmpty() ? "benh-nhan" : safe;
    }

    private static void writePdf(File file, ClinicalAssessment assessment) throws IOException {
        PdfDocument document = new PdfDocument();
        try {
            PdfDocument.Page page1 = document.startPage(new PdfDocument.PageInfo.Builder(PAGE_WIDTH, PAGE_HEIGHT, 1).create());
            drawPageOne(page1.getCanvas(), assessment);
            document.finishPage(page1);

            PdfDocument.Page page2 = document.startPage(new PdfDocument.PageInfo.Builder(PAGE_WIDTH, PAGE_HEIGHT, 2).create());
            drawPageTwo(page2.getCanvas(), assessment);
            document.finishPage(page2);

            FileOutputStream outputStream = new FileOutputStream(file);
            try {
                document.writeTo(outputStream);
            } finally {
                outputStream.close();
            }
        } finally {
            document.close();
        }
    }

    private static void drawPageOne(Canvas canvas, ClinicalAssessment a) {
        Paint text = textPaint(12, false);
        Paint bold = textPaint(12, true);
        Paint title = textPaint(14, true);
        int y = 34;
        drawText(canvas, title, "BẢNG THU THẬP SỐ LIỆU NGHIÊN CỨU (CRF)", MARGIN, y);
        y += 34;
        drawText(canvas, text, "Mã bệnh nhân (ID): " + lineValue(a.patientId, 16)
                + "    Ngày giờ vào viện: " + admissionText(a), MARGIN, y);
        y += 28;
        drawText(canvas, title, "I. TIÊU CHUẨN LỰA CHỌN VÀ LOẠI TRỪ", MARGIN, y);
        y += 18;
        String[][] eligibility = {
                {"Tiêu chí", "Có", "Không"},
                {"1. Bệnh nhân ≥ 18 tuổi nhập viện tại Khoa Cấp cứu", "☐", "☐"},
                {"2. Nghi ngờ nhiễm trùng (có chỉ định dùng kháng sinh TM và/hoặc cấy máu)", "☐", "☐"},
                {"3. Có xét nghiệm định lượng nồng độ lactate máu tĩnh mạch lúc phân loại/giờ đầu", "☐", "☐"},
                {"4. Tử vong trong vòng 24 giờ đầu trước khi hoàn thành xét nghiệm", "☐", "☐"},
                {"5. Đã can thiệp hồi sức/kháng sinh liều cao từ tuyến dưới chuyển lên", "☐", "☐"},
                {"(Bệnh nhân đủ điều kiện tham gia nghiên cứu khi tiêu chí 1, 2, 3 là \"Có\" và tiêu chí 4, 5 là \"Không\")", "", ""}
        };
        y = drawTable(canvas, eligibility, new float[]{430, 60, 60}, MARGIN, y, 19, 10);
        y += 20;
        drawText(canvas, title, "II. THÔNG TIN HÀNH CHÍNH & BỆNH NỀN", MARGIN, y);
        y += 24;
        drawText(canvas, bold, "•   Họ và tên: " + lineValue(a.fullName, 72), MARGIN + 18, y);
        y += LINE;
        drawText(canvas, bold, "•   Tuổi: " + lineValue(a.age, 14) + "  Giới tính: ☐ Nam      ☐ Nữ", MARGIN + 18, y);
        y += LINE;
        drawText(canvas, bold, "•   Lý do vào viện: " + lineValue(firstText(a.admissionReason, a.suspectedInfection), 68), MARGIN + 18, y);
        y += LINE;
        drawText(canvas, bold, "•   Cơ quan nhiễm trùng: " + lineValue(firstText(a.infectionOrgan, a.suspectedInfection), 62), MARGIN + 18, y);
        y += LINE;
        drawText(canvas, bold, "•   Bệnh lý nền: ☐ ĐTĐ  ☐ Suy thận  ☐ Suy gan  ☐ Tăng HA  ☐ COPD   Khác: ..........", MARGIN + 18, y);
        y += 30;
        drawText(canvas, title, "III. ĐÁNH GIÁ BAN ĐẦU LÚC NHẬP VIỆN (TẠI PHÒNG TRIAGE)", MARGIN, y);
        y += 24;
        drawText(canvas, text, "1. Thang điểm NEWS2 (Khoanh/Đánh dấu vào khoảng giá trị và ghi điểm số tương ứng)", MARGIN, y);
        y += 16;
        drawNews2Pdf(canvas, a, MARGIN, y);
    }

    private static void drawPageTwo(Canvas canvas, ClinicalAssessment a) {
        Paint text = textPaint(12, false);
        Paint title = textPaint(14, true);
        int y = 54;
        drawText(canvas, text, "2. Thang điểm qSOFA", MARGIN, y);
        y += 18;
        String[][] qsofa = {
                {"Tiêu chí", "Điểm", "Đánh giá"},
                {"Nhịp thở ≥ 22 lần/phút", "1", qsofaChoice(a.qsofaRespiration, hasText(a.news2RespirationMeasured) || hasText(a.news2RespirationOption))},
                {"Huyết áp tâm thu ≤ 100 mmHg", "1", qsofaChoice(a.qsofaSystolicBp, hasText(a.news2SystolicBpMeasured) || hasText(a.news2SystolicBpOption))},
                {"Rối loạn ý thức (GCS < 15)", "1", qsofaChoice(a.qsofaConsciousness, hasText(a.news2ConsciousnessMeasured) || hasText(a.news2ConsciousnessOption))},
                {"TỔNG ĐIỂM qSOFA", "", qsofaTotalText(a)}
        };
        y = drawTable(canvas, qsofa, new float[]{210, 90, 250}, MARGIN, y, 22, 10) + 14;
        drawText(canvas, text, "3. Dấu ấn sinh học ban đầu", MARGIN, y);
        y += 20;
        drawText(canvas, text, "•   Nồng độ Lactate tĩnh mạch: " + lineValue(a.lactate, 24) + " mmol/L", MARGIN + 18, y);
        y += LINE;
        drawText(canvas, text, "•   Thời gian lấy mẫu: " + lineValue(a.lactateSampleTime, 22), MARGIN + 18, y);
        y += LINE;
        drawText(canvas, text, "•   Phân mức độ:   " + checked(isLactateLow(a.lactateLevel)) + " < 2 mmol/L      "
                + checked(isLactateIntermediate(a.lactateLevel)) + " 2 - 3.9 mmol/L      "
                + checked(isLactateHigh(a.lactateLevel)) + " ≥ 4 mmol/L", MARGIN + 18, y);
        y += 26;
        drawText(canvas, title, "IV. THANG ĐIỂM SOFA (TIÊU CHUẨN VÀNG TRONG 24H)", MARGIN, y);
        y += 16;
        String[][] sofa = {
                {"Cơ quan", "Thông số / Kết quả thực tế", "Điểm số (0 - 4)"},
                {"Hô hấp", "PaO2/FiO2 (mmHg): " + lineValue(a.sofaRespirationMeasured, 42), scoreIfPresent(a.sofaRespiration, a.sofaRespirationMeasured, null)},
                {"Đông máu", "Tiểu cầu (G/L): " + lineValue(a.sofaCoagulationMeasured, 47), scoreIfPresent(a.sofaCoagulation, a.sofaCoagulationMeasured, null)},
                {"Gan", "Bilirubin toàn phần (µmol/L): " + lineValue(a.sofaLiverMeasured, 38), scoreIfPresent(a.sofaLiver, a.sofaLiverMeasured, null)},
                {"Tim mạch", "MAP/Vận mạch: " + lineValue(a.sofaCardiovascularMeasured, 48), scoreIfPresent(a.sofaCardiovascular, a.sofaCardiovascularMeasured, a.vasopressor ? "vasopressor" : "")},
                {"Thần kinh", "Điểm Glasgow (GCS): " + lineValue(a.sofaNeurologicMeasured, 45), scoreIfPresent(a.sofaNeurologic, a.sofaNeurologicMeasured, null)},
                {"Thận", "Creatinin/nước tiểu: " + lineValue(a.sofaRenalMeasured, 45), scoreIfPresent(a.sofaRenal, a.sofaRenalMeasured, null)},
                {"TỔNG ĐIỂM SOFA", "", sofaTotalText(a)},
                {"Ghi chú đánh giá SOFA: Tăng ≥ 2 điểm so với điểm nền (nếu bệnh nhân không có bệnh nền suy tạng, mặc định điểm SOFA nền = 0).", "", ""}
        };
        y = drawTable(canvas, sofa, new float[]{130, 330, 90}, MARGIN, y, 27, 10) + 18;
        drawText(canvas, title, "V. KẾT CỤC LÂM SÀNG", MARGIN, y);
        y += 20;
        drawText(canvas, text, "1. Chẩn đoán xác định (Theo Sepsis-3):", MARGIN, y);
        y += LINE;
        drawText(canvas, text, "•   " + checked(contains(a.sepsisDiagnosis, "Có Nhiễm") || contains(a.sepsisDiagnosis, "Có nhiễm")) + " Có Nhiễm khuẩn huyết (SOFA ≥ 2)", MARGIN + 18, y);
        y += LINE;
        drawText(canvas, text, "•   " + checked(contains(a.sepsisDiagnosis, "Không")) + " Không Nhiễm khuẩn huyết (SOFA < 2)", MARGIN + 18, y);
        y += LINE;
        drawText(canvas, text, "•   " + checked(contains(a.sepsisDiagnosis, "Sốc")) + " Sốc nhiễm khuẩn", MARGIN + 18, y);
        y += 22;
        drawText(canvas, text, "2. Kết quả điều trị:", MARGIN, y);
        y += LINE;
        drawText(canvas, text, "•   " + checked(contains(a.treatmentOutcome, "Khỏi")) + " Khỏi / Đỡ ra viện", MARGIN + 18, y);
        y += LINE;
        drawText(canvas, text, "•   " + checked(contains(a.treatmentOutcome, "Chuyển")) + " Chuyển viện (Tuyến TW)", MARGIN + 18, y);
        y += LINE;
        drawText(canvas, text, "•   " + checked(contains(a.treatmentOutcome, "Tử vong") || contains(a.treatmentOutcome, "Nặng")) + " Nặng xin về / Tử vong", MARGIN + 18, y);
        y += 22;
        drawText(canvas, text, "3. Số ngày điều trị: " + lineValue(a.treatmentDays, 28) + " ngày.", MARGIN, y);
    }

    private static void drawNews2Pdf(Canvas canvas, ClinicalAssessment a, int x, int y) {
        Paint text = textPaint(10, false);
        Paint bold = textPaint(10, true);
        float[] widths = {86, 48, 54, 54, 54, 54, 54, 54, 54, 48};
        String[][] rows = {
                {"Thông số", "Thực đo", "Điểm 3", "Điểm 2", "Điểm 1", "Điểm 0", "Điểm 1", "Điểm 2", "Điểm 3", "Điểm"},
                {"Nhịp thở (l/p)", a.news2RespirationMeasured, "≤ 8", "", "9-11", "12-20", "", "21-24", "≥ 25", scoreIfPresent(a.news2Respiration, a.news2RespirationMeasured, a.news2RespirationOption)},
                {"SpO2 Thang 1 (%)", a.news2Spo2Scale2 ? "" : a.news2Spo2Measured, "≤ 91", "92-93", "94-95", "≥ 96", "", "", "", a.news2Spo2Scale2 ? "" : scoreIfPresent(a.news2Spo2, a.news2Spo2Measured, a.news2Spo2Option)},
                {"SpO2 Thang 2 (%)*", a.news2Spo2Scale2 ? a.news2Spo2Measured : "", "≤ 83", "84-85", "86-87", "88-92", "93-94", "95-96", "≥ 97", a.news2Spo2Scale2 ? scoreIfPresent(a.news2Spo2, a.news2Spo2Measured, a.news2Spo2Option) : ""},
                {"Thở oxy", a.news2OxygenMeasured, "Có", "", "", "Không", "", "", "", scoreIfPresent(a.news2Oxygen, a.news2OxygenMeasured, a.news2OxygenOption)},
                {"Nhiệt độ (°C)", a.news2TemperatureMeasured, "≤ 35.0", "", "35.1-36", "36.1-38", "38.1-39", "≥ 39.1", "", scoreIfPresent(a.news2Temperature, a.news2TemperatureMeasured, a.news2TemperatureOption)},
                {"HA tâm thu (mmHg)", a.news2SystolicBpMeasured, "≤ 90", "91-100", "101-110", "111-219", "", "", "≥ 220", scoreIfPresent(a.news2SystolicBp, a.news2SystolicBpMeasured, a.news2SystolicBpOption)},
                {"Nhịp tim (l/p)", a.news2HeartRateMeasured, "≤ 40", "", "41-50", "51-90", "91-110", "111-130", "≥ 131", scoreIfPresent(a.news2HeartRate, a.news2HeartRateMeasured, a.news2HeartRateOption)},
                {"Tri giác (AVPU)", a.news2ConsciousnessMeasured, "K.Đ.Ư", "Đau", "Gọi hỏi", "Tỉnh (A)", "", "", "", scoreIfPresent(a.news2Consciousness, a.news2ConsciousnessMeasured, a.news2ConsciousnessOption)},
                {"TỔNG ĐIỂM NEWS2", "", "", "", "", "", "", "", "", news2TotalText(a)}
        };
        Paint line = new Paint(Paint.ANTI_ALIAS_FLAG);
        line.setColor(Color.BLACK);
        line.setStyle(Paint.Style.STROKE);
        for (int r = 0; r < rows.length; r++) {
            int rowHeight = r == 0 ? 28 : 31;
            int left = x;
            for (int c = 0; c < rows[r].length; c++) {
                RectF rect = new RectF(left, y, left + widths[c], y + rowHeight);
                if (r > 0 && c == 9 && hasText(rows[r][c]) && !rows[r][0].startsWith("TỔNG")) {
                    Paint fill = new Paint();
                    fill.setColor(HIGHLIGHT);
                    fill.setStyle(Paint.Style.FILL);
                    canvas.drawRect(rect, fill);
                }
                canvas.drawRect(rect, line);
                drawMultiline(canvas, r == 0 || c == 0 ? bold : text, emptyAsDots(rows[r][c]), rect.left + 4, rect.top + 12, widths[c] - 8, 11);
                left += widths[c];
            }
            y += rowHeight;
        }
        drawText(canvas, text, "*Ghi chú: SpO2 Thang 2 chỉ dùng cho BN suy hô hấp tăng CO2 (COPD).", x, y + 14);
    }

    private static int drawTable(Canvas canvas, String[][] rows, float[] widths, int x, int y, int rowHeight, int textSize) {
        Paint text = textPaint(textSize, false);
        Paint bold = textPaint(textSize, true);
        Paint border = new Paint(Paint.ANTI_ALIAS_FLAG);
        border.setColor(Color.BLACK);
        border.setStyle(Paint.Style.STROKE);
        for (int r = 0; r < rows.length; r++) {
            int left = x;
            for (int c = 0; c < widths.length; c++) {
                RectF rect = new RectF(left, y, left + widths[c], y + rowHeight);
                canvas.drawRect(rect, border);
                String value = c < rows[r].length ? rows[r][c] : "";
                drawMultiline(canvas, r == 0 || c == 0 ? bold : text, value, rect.left + 5, rect.top + 13, widths[c] - 10, textSize + 2);
                left += widths[c];
            }
            y += rowHeight;
        }
        return y;
    }

    private static void writeDocx(File file, ClinicalAssessment a) throws IOException {
        ZipOutputStream zip = new ZipOutputStream(new FileOutputStream(file));
        try {
            addZip(zip, "[Content_Types].xml", "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>"
                    + "<Types xmlns=\"http://schemas.openxmlformats.org/package/2006/content-types\">"
                    + "<Default Extension=\"rels\" ContentType=\"application/vnd.openxmlformats-package.relationships+xml\"/>"
                    + "<Default Extension=\"xml\" ContentType=\"application/xml\"/>"
                    + "<Override PartName=\"/word/document.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml\"/>"
                    + "</Types>");
            addZip(zip, "_rels/.rels", "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>"
                    + "<Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\">"
                    + "<Relationship Id=\"rId1\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument\" Target=\"word/document.xml\"/>"
                    + "</Relationships>");
            addZip(zip, "word/document.xml", buildDocumentXml(a));
        } finally {
            zip.close();
        }
    }

    private static String buildDocumentXml(ClinicalAssessment a) {
        StringBuilder xml = new StringBuilder();
        xml.append("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>");
        xml.append("<w:document xmlns:w=\"http://schemas.openxmlformats.org/wordprocessingml/2006/main\"><w:body>");
        p(xml, "BẢNG THU THẬP SỐ LIỆU NGHIÊN CỨU (CRF)", true);
        p(xml, "Mã bệnh nhân (ID): " + textOrDots(a.patientId) + "    Ngày giờ vào viện: " + admissionText(a), false);
        p(xml, "I. TIÊU CHUẨN LỰA CHỌN VÀ LOẠI TRỪ", true);
        table(xml, new String[][]{
                {"Tiêu chí", "Có", "Không"},
                {"1. Bệnh nhân ≥ 18 tuổi nhập viện tại Khoa Cấp cứu", "☐", "☐"},
                {"2. Nghi ngờ nhiễm trùng (có chỉ định dùng kháng sinh TM và/hoặc cấy máu)", "☐", "☐"},
                {"3. Có xét nghiệm định lượng nồng độ lactate máu tĩnh mạch lúc phân loại/giờ đầu", "☐", "☐"},
                {"4. Tử vong trong vòng 24 giờ đầu trước khi hoàn thành xét nghiệm", "☐", "☐"},
                {"5. Đã can thiệp hồi sức/kháng sinh liều cao từ tuyến dưới chuyển lên", "☐", "☐"}
        });
        p(xml, "II. THÔNG TIN HÀNH CHÍNH & BỆNH NỀN", true);
        p(xml, "• Họ và tên: " + textOrDots(a.fullName), false);
        p(xml, "• Tuổi: " + textOrDots(a.age) + "    Giới tính: ☐ Nam    ☐ Nữ", false);
        p(xml, "• Lý do vào viện: " + textOrDots(firstText(a.admissionReason, a.suspectedInfection)), false);
        p(xml, "• Cơ quan nhiễm trùng: " + textOrDots(firstText(a.infectionOrgan, a.suspectedInfection)), false);
        p(xml, "• Bệnh lý nền: ☐ ĐTĐ  ☐ Suy thận  ☐ Suy gan  ☐ Tăng HA  ☐ COPD   Khác: ..........", false);
        p(xml, "III. ĐÁNH GIÁ BAN ĐẦU LÚC NHẬP VIỆN (TẠI PHÒNG TRIAGE)", true);
        table(xml, news2DocxRows(a));
        p(xml, "2. Thang điểm qSOFA", true);
        table(xml, new String[][]{
                {"Tiêu chí", "Điểm", "Đánh giá"},
                {"Nhịp thở ≥ 22 lần/phút", "1", qsofaChoice(a.qsofaRespiration, hasText(a.news2RespirationMeasured) || hasText(a.news2RespirationOption))},
                {"Huyết áp tâm thu ≤ 100 mmHg", "1", qsofaChoice(a.qsofaSystolicBp, hasText(a.news2SystolicBpMeasured) || hasText(a.news2SystolicBpOption))},
                {"Rối loạn ý thức (GCS < 15)", "1", qsofaChoice(a.qsofaConsciousness, hasText(a.news2ConsciousnessMeasured) || hasText(a.news2ConsciousnessOption))},
                {"TỔNG ĐIỂM qSOFA", "", qsofaTotalText(a)}
        });
        p(xml, "3. Dấu ấn sinh học ban đầu", true);
        p(xml, "• Nồng độ Lactate tĩnh mạch: " + textOrDots(a.lactate) + " mmol/L", false);
        p(xml, "• Thời gian lấy mẫu: " + textOrDots(a.lactateSampleTime), false);
        p(xml, "• Phân mức độ: " + checked(isLactateLow(a.lactateLevel)) + " < 2 mmol/L    "
                + checked(isLactateIntermediate(a.lactateLevel)) + " 2 - 3.9 mmol/L    "
                + checked(isLactateHigh(a.lactateLevel)) + " ≥ 4 mmol/L", false);
        p(xml, "IV. THANG ĐIỂM SOFA (TIÊU CHUẨN VÀNG TRONG 24H)", true);
        table(xml, new String[][]{
                {"Cơ quan", "Thông số / Kết quả thực tế", "Điểm số (0 - 4)"},
                {"Hô hấp", "PaO2/FiO2 (mmHg): " + textOrDots(a.sofaRespirationMeasured), scoreIfPresent(a.sofaRespiration, a.sofaRespirationMeasured, null)},
                {"Đông máu", "Tiểu cầu (G/L): " + textOrDots(a.sofaCoagulationMeasured), scoreIfPresent(a.sofaCoagulation, a.sofaCoagulationMeasured, null)},
                {"Gan", "Bilirubin toàn phần (µmol/L): " + textOrDots(a.sofaLiverMeasured), scoreIfPresent(a.sofaLiver, a.sofaLiverMeasured, null)},
                {"Tim mạch", "MAP/Vận mạch: " + textOrDots(a.sofaCardiovascularMeasured), scoreIfPresent(a.sofaCardiovascular, a.sofaCardiovascularMeasured, a.vasopressor ? "vasopressor" : "")},
                {"Thần kinh", "Điểm Glasgow (GCS): " + textOrDots(a.sofaNeurologicMeasured), scoreIfPresent(a.sofaNeurologic, a.sofaNeurologicMeasured, null)},
                {"Thận", "Creatinin/nước tiểu: " + textOrDots(a.sofaRenalMeasured), scoreIfPresent(a.sofaRenal, a.sofaRenalMeasured, null)},
                {"TỔNG ĐIỂM SOFA", "", sofaTotalText(a)}
        });
        p(xml, "V. KẾT CỤC LÂM SÀNG", true);
        p(xml, "1. Chẩn đoán xác định (Theo Sepsis-3):", false);
        p(xml, "• " + checked(contains(a.sepsisDiagnosis, "Có Nhiễm") || contains(a.sepsisDiagnosis, "Có nhiễm")) + " Có Nhiễm khuẩn huyết (SOFA ≥ 2)", false);
        p(xml, "• " + checked(contains(a.sepsisDiagnosis, "Không")) + " Không Nhiễm khuẩn huyết (SOFA < 2)", false);
        p(xml, "• " + checked(contains(a.sepsisDiagnosis, "Sốc")) + " Sốc nhiễm khuẩn", false);
        p(xml, "2. Kết quả điều trị:", false);
        p(xml, "• " + checked(contains(a.treatmentOutcome, "Khỏi")) + " Khỏi / Đỡ ra viện", false);
        p(xml, "• " + checked(contains(a.treatmentOutcome, "Chuyển")) + " Chuyển viện (Tuyến TW)", false);
        p(xml, "• " + checked(contains(a.treatmentOutcome, "Tử vong") || contains(a.treatmentOutcome, "Nặng")) + " Nặng xin về / Tử vong", false);
        p(xml, "3. Số ngày điều trị: " + textOrDots(a.treatmentDays) + " ngày.", false);
        xml.append("<w:sectPr><w:pgSz w:w=\"12240\" w:h=\"15840\"/><w:pgMar w:top=\"720\" w:right=\"720\" w:bottom=\"720\" w:left=\"720\"/></w:sectPr>");
        xml.append("</w:body></w:document>");
        return xml.toString();
    }

    private static String[][] news2DocxRows(ClinicalAssessment a) {
        return new String[][]{
                {"Thông số", "Thực đo", "Điểm 3", "Điểm 2", "Điểm 1", "Điểm 0", "Điểm 1", "Điểm 2", "Điểm 3", "Điểm"},
                {"Nhịp thở (l/p)", textOrDots(a.news2RespirationMeasured), "≤ 8", "", "9-11", "12-20", "", "21-24", "≥ 25", scoreIfPresent(a.news2Respiration, a.news2RespirationMeasured, a.news2RespirationOption)},
                {"SpO2 Thang 1 (%)", a.news2Spo2Scale2 ? "" : textOrDots(a.news2Spo2Measured), "≤ 91", "92-93", "94-95", "≥ 96", "", "", "", a.news2Spo2Scale2 ? "" : scoreIfPresent(a.news2Spo2, a.news2Spo2Measured, a.news2Spo2Option)},
                {"SpO2 Thang 2 (%)*", a.news2Spo2Scale2 ? textOrDots(a.news2Spo2Measured) : "", "≤ 83", "84-85", "86-87", "88-92", "93-94", "95-96", "≥ 97", a.news2Spo2Scale2 ? scoreIfPresent(a.news2Spo2, a.news2Spo2Measured, a.news2Spo2Option) : ""},
                {"Thở oxy", textOrDots(a.news2OxygenMeasured), "Có", "", "", "Không", "", "", "", scoreIfPresent(a.news2Oxygen, a.news2OxygenMeasured, a.news2OxygenOption)},
                {"Nhiệt độ (°C)", textOrDots(a.news2TemperatureMeasured), "≤ 35.0", "", "35.1-36", "36.1-38", "38.1-39", "≥ 39.1", "", scoreIfPresent(a.news2Temperature, a.news2TemperatureMeasured, a.news2TemperatureOption)},
                {"HA tâm thu (mmHg)", textOrDots(a.news2SystolicBpMeasured), "≤ 90", "91-100", "101-110", "111-219", "", "", "≥ 220", scoreIfPresent(a.news2SystolicBp, a.news2SystolicBpMeasured, a.news2SystolicBpOption)},
                {"Nhịp tim (l/p)", textOrDots(a.news2HeartRateMeasured), "≤ 40", "", "41-50", "51-90", "91-110", "111-130", "≥ 131", scoreIfPresent(a.news2HeartRate, a.news2HeartRateMeasured, a.news2HeartRateOption)},
                {"Tri giác (AVPU)", textOrDots(a.news2ConsciousnessMeasured), "K.Đ.Ư", "Đau", "Gọi hỏi", "Tỉnh (A)", "", "", "", scoreIfPresent(a.news2Consciousness, a.news2ConsciousnessMeasured, a.news2ConsciousnessOption)},
                {"TỔNG ĐIỂM NEWS2", "", "", "", "", "", "", "", "", news2TotalText(a)}
        };
    }

    private static void table(StringBuilder xml, String[][] rows) {
        xml.append("<w:tbl><w:tblPr><w:tblBorders><w:top w:val=\"single\" w:sz=\"6\"/><w:left w:val=\"single\" w:sz=\"6\"/><w:bottom w:val=\"single\" w:sz=\"6\"/><w:right w:val=\"single\" w:sz=\"6\"/><w:insideH w:val=\"single\" w:sz=\"6\"/><w:insideV w:val=\"single\" w:sz=\"6\"/></w:tblBorders></w:tblPr>");
        for (String[] row : rows) {
            xml.append("<w:tr>");
            for (int c = 0; c < row.length; c++) {
                String cell = row[c];
                boolean highlight = c == row.length - 1 && row.length > 3 && hasText(cell)
                        && !"Điểm".equals(cell) && !cell.startsWith("....") && !row[0].startsWith("TỔNG");
                xml.append("<w:tc><w:tcPr><w:tcW w:w=\"1800\" w:type=\"dxa\"/>");
                if (highlight) {
                    xml.append("<w:shd w:val=\"clear\" w:color=\"auto\" w:fill=\"FFE5CC\"/>");
                }
                xml.append("</w:tcPr>");
                p(xml, cell == null ? "" : cell, false);
                xml.append("</w:tc>");
            }
            xml.append("</w:tr>");
        }
        xml.append("</w:tbl>");
    }

    private static void p(StringBuilder xml, String text, boolean bold) {
        xml.append("<w:p><w:r>");
        if (bold) {
            xml.append("<w:rPr><w:b/></w:rPr>");
        }
        xml.append("<w:t xml:space=\"preserve\">").append(escapeXml(text)).append("</w:t></w:r></w:p>");
    }

    private static void addZip(ZipOutputStream zip, String name, String value) throws IOException {
        zip.putNextEntry(new ZipEntry(name));
        zip.write(value.getBytes("UTF-8"));
        zip.closeEntry();
    }

    private static Paint textPaint(int size, boolean bold) {
        Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        paint.setColor(Color.BLACK);
        paint.setTextSize(size);
        paint.setTypeface(Typeface.create(Typeface.SERIF, bold ? Typeface.BOLD : Typeface.NORMAL));
        return paint;
    }

    private static void drawText(Canvas canvas, Paint paint, String text, float x, float y) {
        canvas.drawText(text == null ? "" : text, x, y, paint);
    }

    private static void drawMultiline(Canvas canvas, Paint paint, String value, float x, float y, float maxWidth, int lineHeight) {
        String[] words = (value == null ? "" : value).split("\\s+");
        StringBuilder line = new StringBuilder();
        for (String word : words) {
            String next = line.length() == 0 ? word : line + " " + word;
            if (paint.measureText(next) > maxWidth && line.length() > 0) {
                canvas.drawText(line.toString(), x, y, paint);
                y += lineHeight;
                line.setLength(0);
                line.append(word);
            } else {
                line.setLength(0);
                line.append(next);
            }
        }
        if (line.length() > 0) {
            canvas.drawText(line.toString(), x, y, paint);
        }
    }

    private static String admissionText(ClinicalAssessment a) {
        String date = firstText(a.admissionDate, "");
        String time = firstText(a.admissionTime, "");
        if (date.isEmpty() && time.isEmpty() && hasText(a.admissionDateTime)) {
            return a.admissionDateTime;
        }
        return (time.isEmpty() ? "......... giờ ......... phút" : time)
                + ", ngày " + (date.isEmpty() ? "........./........./202......" : date);
    }

    private static String checked(boolean checked) {
        return checked ? "☑" : "☐";
    }

    static String scoreIfPresent(int score, String measuredValue, String selectedOption) {
        return hasText(measuredValue) || hasText(selectedOption) ? String.valueOf(score) : "";
    }

    static String qsofaChoice(boolean value, boolean completed) {
        if (!completed) {
            return "☐ Có (1 điểm)      ☐ Không (0 điểm)";
        }
        return checked(value) + " Có (1 điểm)      " + checked(!value) + " Không (0 điểm)";
    }

    static String news2TotalText(ClinicalAssessment assessment) {
        return allNews2Completed(assessment) ? assessment.news2Total + "/21" : dots(8);
    }

    static String qsofaTotalText(ClinicalAssessment assessment) {
        return anyQsofaCompleted(assessment) ? assessment.qsofaTotal + " / 3 điểm" : dots(24) + " / 3 điểm";
    }

    static String sofaTotalText(ClinicalAssessment assessment) {
        return anySofaCompleted(assessment) ? assessment.sofaTotal + " / 24" : dots(24) + " / 24";
    }

    private static boolean allNews2Completed(ClinicalAssessment assessment) {
        return (hasText(assessment.news2RespirationMeasured) || hasText(assessment.news2RespirationOption))
                && (hasText(assessment.news2Spo2Measured) || hasText(assessment.news2Spo2Option))
                && (hasText(assessment.news2OxygenMeasured) || hasText(assessment.news2OxygenOption))
                && (hasText(assessment.news2TemperatureMeasured) || hasText(assessment.news2TemperatureOption))
                && (hasText(assessment.news2SystolicBpMeasured) || hasText(assessment.news2SystolicBpOption))
                && (hasText(assessment.news2HeartRateMeasured) || hasText(assessment.news2HeartRateOption))
                && (hasText(assessment.news2ConsciousnessMeasured) || hasText(assessment.news2ConsciousnessOption));
    }

    private static boolean anyQsofaCompleted(ClinicalAssessment assessment) {
        return hasText(assessment.news2RespirationMeasured) || hasText(assessment.news2RespirationOption)
                || hasText(assessment.news2SystolicBpMeasured) || hasText(assessment.news2SystolicBpOption)
                || hasText(assessment.news2ConsciousnessMeasured) || hasText(assessment.news2ConsciousnessOption);
    }

    private static boolean anySofaCompleted(ClinicalAssessment assessment) {
        return hasText(assessment.sofaRespirationMeasured)
                || hasText(assessment.sofaCoagulationMeasured)
                || hasText(assessment.sofaLiverMeasured)
                || hasText(assessment.sofaCardiovascularMeasured)
                || hasText(assessment.sofaNeurologicMeasured)
                || hasText(assessment.sofaRenalMeasured)
                || assessment.vasopressor;
    }

    static boolean isLactateLow(String value) {
        return startsWith(value, "<");
    }

    static boolean isLactateIntermediate(String value) {
        return hasText(value) && !isLactateLow(value) && contains(value, "2") && !isLactateHigh(value);
    }

    static boolean isLactateHigh(String value) {
        return contains(value, "4");
    }

    private static String emptyAsDots(String value) {
        return hasText(value) ? value : "......";
    }

    private static String textOrDots(String value) {
        return hasText(value) ? value.trim() : "........................";
    }

    private static String lineValue(String value, int dots) {
        return hasText(value) ? value.trim() : dots(dots);
    }

    private static String dots(int count) {
        StringBuilder builder = new StringBuilder();
        for (int i = 0; i < count; i++) {
            builder.append('.');
        }
        return builder.toString();
    }

    private static String firstText(String first, String fallback) {
        return hasText(first) ? first.trim() : (fallback == null ? "" : fallback.trim());
    }

    private static String firstText(String first, String second, String fallback) {
        if (hasText(first)) {
            return first.trim();
        }
        if (hasText(second)) {
            return second.trim();
        }
        return fallback;
    }

    private static boolean hasText(String value) {
        return value != null && !value.trim().isEmpty();
    }

    private static boolean contains(String value, String needle) {
        return value != null && needle != null && value.toLowerCase(Locale.getDefault()).contains(needle.toLowerCase(Locale.getDefault()));
    }

    private static boolean startsWith(String value, String prefix) {
        return value != null && prefix != null && value.trim().startsWith(prefix);
    }

    private static String escapeXml(String value) {
        if (value == null) {
            return "";
        }
        return value.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&apos;");
    }
}
