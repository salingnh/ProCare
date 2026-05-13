package com.sangnv.procare.data;

import com.google.gson.JsonSyntaxException;
import com.google.gson.reflect.TypeToken;
import com.sangnv.procare.App;
import com.sangnv.procare.Model.ClinicalAssessment;
import com.sangnv.procare.utils.SharedPrefs;

import java.util.ArrayList;
import java.util.List;

public final class AssessmentRepository {
    private static final String KEY_CURRENT_ASSESSMENT = "clinical_assessment_current";
    private static final String KEY_ASSESSMENT_HISTORY = "clinical_assessment_history";

    public ClinicalAssessment loadCurrentAssessment() {
        String json = SharedPrefs.getInstance().get(KEY_CURRENT_ASSESSMENT, String.class);
        if (json == null || json.trim().isEmpty()) {
            return new ClinicalAssessment();
        }
        try {
            ClinicalAssessment savedAssessment = App.self().getGSon().fromJson(json, ClinicalAssessment.class);
            return savedAssessment == null ? new ClinicalAssessment() : savedAssessment;
        } catch (JsonSyntaxException exception) {
            return new ClinicalAssessment();
        }
    }

    public void saveCurrentAssessment(ClinicalAssessment assessment) {
        SharedPrefs.getInstance().put(KEY_CURRENT_ASSESSMENT, App.self().getGSon().toJson(assessment));
    }

    public List<ClinicalAssessment> loadAssessmentHistory() {
        String json = SharedPrefs.getInstance().get(KEY_ASSESSMENT_HISTORY, String.class);
        if (json == null || json.trim().isEmpty()) {
            return new ArrayList<>();
        }
        try {
            List<ClinicalAssessment> history = App.self().getGSon().fromJson(json, new TypeToken<List<ClinicalAssessment>>() {
            }.getType());
            return history == null ? new ArrayList<ClinicalAssessment>() : history;
        } catch (JsonSyntaxException exception) {
            return new ArrayList<>();
        }
    }

    public void appendAssessmentHistory(ClinicalAssessment assessment) {
        List<ClinicalAssessment> history = loadAssessmentHistory();
        history.add(App.self().getGSon().fromJson(App.self().getGSon().toJson(assessment), ClinicalAssessment.class));
        SharedPrefs.getInstance().put(KEY_ASSESSMENT_HISTORY, App.self().getGSon().toJson(history));
    }
}
