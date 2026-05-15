package com.sangnv.procare.scoring;

import com.sangnv.procare.Model.ClinicalAssessment;

public final class QsofaScoring {
    private QsofaScoring() {
    }

    public static int total(ClinicalAssessment assessment) {
        return booleanScore(assessment.qsofaRespiration) + booleanScore(assessment.qsofaSystolicBp)
                + booleanScore(assessment.qsofaConsciousness);
    }

    private static int booleanScore(boolean value) {
        return value ? 1 : 0;
    }
}
