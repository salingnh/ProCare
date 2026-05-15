package com.sangnv.procare.scoring;

import com.sangnv.procare.Model.ClinicalAssessment;

public final class SofaScoring {
    public static final int RISK_LOW = 0;
    public static final int RISK_INTERMEDIATE = 1;
    public static final int RISK_HIGH = 2;

    private SofaScoring() {
    }

    public static int total(ClinicalAssessment assessment) {
        return assessment.sofaRespiration + assessment.sofaCoagulation + assessment.sofaLiver
                + assessment.sofaCardiovascular + assessment.sofaNeurologic + assessment.sofaRenal;
    }

    public static int riskGroup(int sofaTotal) {
        if (sofaTotal > 11) {
            return RISK_HIGH;
        }
        if (sofaTotal >= 9) {
            return RISK_INTERMEDIATE;
        }
        return RISK_LOW;
    }

    public static boolean hasSepsisBySofa(ClinicalAssessment assessment) {
        return assessment.sofaTotal >= 2;
    }

    public static boolean hasSepticShock(ClinicalAssessment assessment) {
        return assessment.vasopressor && lactateAtLeastTwo(assessment);
    }

    public static boolean lactateAtLeastTwo(ClinicalAssessment assessment) {
        if (assessment.lactateLevel != null && !assessment.lactateLevel.isEmpty()) {
            return !assessment.lactateLevel.startsWith("<");
        }
        Double lactate = ClinicalValueParser.parseDouble(assessment.lactate);
        return lactate != null && lactate >= 2.0;
    }

    public static int scoreRespiration(String value, int fallback) {
        Double ratio = ClinicalValueParser.parseDouble(value);
        if (ratio == null) {
            return fallback;
        }
        boolean support = value.toLowerCase().contains("oxy") || value.toLowerCase().contains("tho")
                || value.toLowerCase().contains("thở") || value.toLowerCase().contains("vent")
                || value.toLowerCase().contains("hf") || value.toLowerCase().contains("niv");
        if (ratio < 100 && support) {
            return 4;
        }
        if (ratio < 200 && support) {
            return 3;
        }
        if (ratio < 300) {
            return 2;
        }
        if (ratio < 400) {
            return 1;
        }
        return 0;
    }

    public static int scoreCoagulation(String value, int fallback) {
        Double platelet = ClinicalValueParser.parseDouble(value);
        if (platelet == null) {
            return fallback;
        }
        if (platelet < 20) {
            return 4;
        }
        if (platelet < 50) {
            return 3;
        }
        if (platelet < 100) {
            return 2;
        }
        if (platelet < 150) {
            return 1;
        }
        return 0;
    }

    public static int scoreLiver(String value, int fallback) {
        Double bilirubin = ClinicalValueParser.parseDouble(value);
        if (bilirubin == null) {
            return fallback;
        }
        String lower = value.toLowerCase();
        if (lower.contains("umol") || lower.contains("µmol")) {
            bilirubin = bilirubin / 17.1;
        }
        if (bilirubin >= 12.0) {
            return 4;
        }
        if (bilirubin >= 6.0) {
            return 3;
        }
        if (bilirubin >= 2.0) {
            return 2;
        }
        if (bilirubin >= 1.2) {
            return 1;
        }
        return 0;
    }

    public static int scoreCardiovascular(String value, boolean vasopressor, int fallback) {
        String lower = value == null ? "" : value.toLowerCase();
        Double number = ClinicalValueParser.parseDouble(value);
        if (lower.contains("nor") || lower.contains("epi")) {
            if (number != null && number > 0.1) {
                return 4;
            }
            return 3;
        }
        if (lower.contains("dopamine")) {
            if (number != null && number > 15) {
                return 4;
            }
            if (number != null && number > 5) {
                return 3;
            }
            return 2;
        }
        if (lower.contains("dobutamine")) {
            return 2;
        }
        if (vasopressor) {
            return Math.max(fallback, 2);
        }
        if (number == null) {
            return fallback;
        }
        return number < 70 ? 1 : 0;
    }

    public static int scoreNeurologic(String value, int fallback) {
        Integer gcs = ClinicalValueParser.parseInteger(value);
        if (gcs == null) {
            return fallback;
        }
        if (gcs < 6) {
            return 4;
        }
        if (gcs <= 9) {
            return 3;
        }
        if (gcs <= 12) {
            return 2;
        }
        if (gcs <= 14) {
            return 1;
        }
        return 0;
    }

    public static int scoreRenal(String value, int fallback) {
        Double creatinine = ClinicalValueParser.parseDouble(value);
        Integer urineOutput = extractUrineOutput(value);
        int creatinineScore = fallback;
        if (creatinine != null) {
            String lower = value.toLowerCase();
            if (lower.contains("umol") || lower.contains("µmol")) {
                creatinine = creatinine / 88.4;
            }
            if (creatinine >= 5.0) {
                creatinineScore = 4;
            } else if (creatinine >= 3.5) {
                creatinineScore = 3;
            } else if (creatinine >= 2.0) {
                creatinineScore = 2;
            } else if (creatinine >= 1.2) {
                creatinineScore = 1;
            } else {
                creatinineScore = 0;
            }
        }
        int urineScore = 0;
        if (urineOutput != null) {
            if (urineOutput < 200) {
                urineScore = 4;
            } else if (urineOutput < 500) {
                urineScore = 3;
            }
        }
        return Math.max(creatinineScore, urineScore);
    }

    private static Integer extractUrineOutput(String value) {
        if (!ClinicalValueParser.hasText(value)) {
            return null;
        }
        String lower = value.toLowerCase();
        int urineIndex = lower.indexOf("ml");
        if (urineIndex < 0 && !lower.contains("nước tiểu") && !lower.contains("nuoc tieu")) {
            return null;
        }
        return ClinicalValueParser.parseInteger(value.substring(0, urineIndex > 0 ? urineIndex : value.length()));
    }
}
