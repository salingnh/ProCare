package com.sangnv.procare.export;

import com.sangnv.procare.Model.ClinicalAssessment;

import org.junit.Test;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;

public class CrfExporterTest {
    @Test
    public void sanitizeFileName_keepsVietnameseLettersAndRemovesUnsafeSeparators() {
        assertEquals("Nguyễn-Văn-A-01", CrfExporter.sanitizeFileName("Nguyễn Văn A / 01"));
    }

    @Test
    public void buildFileName_usesPatientIdAndFormatExtension() {
        ClinicalAssessment assessment = new ClinicalAssessment();
        assessment.patientId = "BN 001";

        String fileName = CrfExporter.buildFileName(assessment, CrfExporter.Format.PDF);

        assertTrue(fileName.startsWith("NEWS2-L-BN-001-"));
        assertTrue(fileName.endsWith(".pdf"));
    }

    @Test
    public void sanitizeFileName_usesFallbackForBlankInput() {
        assertEquals("benh-nhan", CrfExporter.sanitizeFileName("   "));
    }

    @Test
    public void scoreIfPresent_leavesMissingClinicalScoresBlank() {
        assertEquals("", CrfExporter.scoreIfPresent(0, "", ""));
        assertEquals("0", CrfExporter.scoreIfPresent(0, "12", ""));
        assertEquals("3", CrfExporter.scoreIfPresent(3, "", "≥ 25"));
    }

    @Test
    public void qsofaChoice_leavesUnknownCriterionUnticked() {
        assertEquals("☐ Có (1 điểm)      ☐ Không (0 điểm)", CrfExporter.qsofaChoice(false, false));
        assertEquals("☐ Có (1 điểm)      ☑ Không (0 điểm)", CrfExporter.qsofaChoice(false, true));
        assertEquals("☑ Có (1 điểm)      ☐ Không (0 điểm)", CrfExporter.qsofaChoice(true, true));
    }

    @Test
    public void totalsRemainBlankUntilRequiredDataExists() {
        ClinicalAssessment assessment = new ClinicalAssessment();
        assertEquals("........", CrfExporter.news2TotalText(assessment));
        assertEquals("........................ / 3 điểm", CrfExporter.qsofaTotalText(assessment));
        assertEquals("........................ / 24", CrfExporter.sofaTotalText(assessment));

        assessment.news2RespirationMeasured = "22";
        assessment.qsofaTotal = 1;
        assertEquals("1 / 3 điểm", CrfExporter.qsofaTotalText(assessment));
    }

    @Test
    public void lactateBandsAreMutuallyExclusive() {
        assertTrue(CrfExporter.isLactateLow("< 2 mmol/L"));
        assertTrue(CrfExporter.isLactateIntermediate("≥ 2 mmol/L"));
        assertTrue(CrfExporter.isLactateHigh("≥ 4 mmol/L"));
    }
}
