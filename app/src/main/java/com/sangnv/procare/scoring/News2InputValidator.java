package com.sangnv.procare.scoring;

import com.sangnv.procare.Model.ClinicalAssessment;

import java.util.ArrayList;
import java.util.List;

public final class News2InputValidator {
    private News2InputValidator() {
    }

    public static int scoreOxygenText(String value, int fallback) {
        if (!ClinicalValueParser.hasText(value)) {
            return fallback;
        }
        String normalized = value.trim().toLowerCase();
        if (normalized.contains("không") || normalized.contains("khong") || normalized.contains("room")
                || normalized.contains("khí phòng") || normalized.contains("khi phong")) {
            return 0;
        }
        return normalized.contains("oxy") || normalized.contains("oxygen") || normalized.contains("có") || normalized.contains("co") ? 2 : fallback;
    }

    public static List<String> missingRequiredFields(ClinicalAssessment assessment) {
        List<String> missing = new ArrayList<>();
        addMissingIfEmpty(missing, "respiratory_rate", assessment.news2RespirationMeasured, assessment.news2RespirationOption);
        addMissingIfEmpty(missing, "spo2", assessment.news2Spo2Measured, assessment.news2Spo2Option);
        addMissingIfEmpty(missing, "supplemental_oxygen", assessment.news2OxygenMeasured, assessment.news2OxygenOption);
        addMissingIfEmpty(missing, "systolic_bp", assessment.news2SystolicBpMeasured, assessment.news2SystolicBpOption);
        addMissingIfEmpty(missing, "pulse", assessment.news2HeartRateMeasured, assessment.news2HeartRateOption);
        addMissingIfEmpty(missing, "consciousness", assessment.news2ConsciousnessMeasured, assessment.news2ConsciousnessOption);
        addMissingIfEmpty(missing, "temperature", assessment.news2TemperatureMeasured, assessment.news2TemperatureOption);
        return missing;
    }

    public static int completedRequiredCount(ClinicalAssessment assessment) {
        return 7 - missingRequiredFields(assessment).size();
    }

    private static void addMissingIfEmpty(List<String> missing, String field, String measuredValue, String selectedOption) {
        if (!ClinicalValueParser.hasText(measuredValue) && !ClinicalValueParser.hasText(selectedOption)) {
            missing.add(field);
        }
    }
}
