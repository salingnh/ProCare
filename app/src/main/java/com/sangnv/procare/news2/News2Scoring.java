package com.sangnv.procare.news2;

import android.graphics.Color;

import com.sangnv.procare.Model.ClinicalAssessment;

public final class News2Scoring {
    public static final int COLOR_SUCCESS = Color.rgb(16, 185, 129);
    public static final int COLOR_WARNING = Color.rgb(234, 179, 8);
    public static final int COLOR_ORANGE = Color.rgb(249, 115, 22);
    public static final int COLOR_DANGER = Color.rgb(220, 38, 38);

    private News2Scoring() {
    }

    public static int total(ClinicalAssessment assessment) {
        return assessment.news2Respiration + assessment.news2Spo2 + assessment.news2Oxygen
                + assessment.news2Temperature + assessment.news2SystolicBp + assessment.news2HeartRate
                + assessment.news2Consciousness;
    }

    public static boolean hasSingleThreeScore(ClinicalAssessment assessment) {
        return assessment.news2Respiration == 3 || assessment.news2Spo2 == 3 || assessment.news2Temperature == 3
                || assessment.news2SystolicBp == 3 || assessment.news2HeartRate == 3 || assessment.news2Consciousness == 3;
    }

    public static int riskColor(ClinicalAssessment assessment) {
        if (assessment.news2Total >= 7) {
            return COLOR_DANGER;
        }
        if (assessment.news2Total >= 5) {
            return COLOR_ORANGE;
        }
        if (hasSingleThreeScore(assessment)) {
            return COLOR_WARNING;
        }
        return COLOR_SUCCESS;
    }

    public static int scoreRespiration(Integer value, int fallback) {
        if (value == null) {
            return fallback;
        }
        if (value <= 8) {
            return 3;
        }
        if (value <= 11) {
            return 1;
        }
        if (value <= 20) {
            return 0;
        }
        if (value <= 24) {
            return 2;
        }
        return 3;
    }

    public static int scoreSpo2Scale1(Integer value, int fallback) {
        if (value == null) {
            return fallback;
        }
        if (value <= 91) {
            return 3;
        }
        if (value <= 93) {
            return 2;
        }
        if (value <= 95) {
            return 1;
        }
        return 0;
    }

    public static int scoreSpo2Scale2(Integer value, boolean oxygen, int fallback) {
        if (value == null) {
            return fallback;
        }
        if (!oxygen) {
            if (value <= 83) {
                return 3;
            }
            if (value <= 85) {
                return 2;
            }
            if (value <= 87) {
                return 1;
            }
            return 0;
        }
        if (value <= 92) {
            return 0;
        }
        if (value <= 94) {
            return 1;
        }
        if (value <= 96) {
            return 2;
        }
        return 3;
    }

    public static int scoreTemperature(Double value, int fallback) {
        if (value == null) {
            return fallback;
        }
        if (value <= 35.0) {
            return 3;
        }
        if (value <= 36.0) {
            return 1;
        }
        if (value <= 38.0) {
            return 0;
        }
        if (value <= 39.0) {
            return 1;
        }
        return 2;
    }

    public static int scoreSystolicBp(Integer value, int fallback) {
        if (value == null) {
            return fallback;
        }
        if (value <= 90) {
            return 3;
        }
        if (value <= 100) {
            return 2;
        }
        if (value <= 110) {
            return 1;
        }
        if (value <= 219) {
            return 0;
        }
        return 3;
    }

    public static int scoreHeartRate(Integer value, int fallback) {
        if (value == null) {
            return fallback;
        }
        if (value <= 40) {
            return 3;
        }
        if (value <= 50) {
            return 1;
        }
        if (value <= 90) {
            return 0;
        }
        if (value <= 110) {
            return 1;
        }
        if (value <= 130) {
            return 2;
        }
        return 3;
    }

    public static int scoreConsciousness(String value, int fallback) {
        if (value == null || value.trim().isEmpty()) {
            return fallback;
        }
        String normalized = value.trim().toUpperCase();
        return normalized.equals("A") || normalized.contains("TINH") || normalized.contains("TỈNH") ? 0 : 3;
    }
}
