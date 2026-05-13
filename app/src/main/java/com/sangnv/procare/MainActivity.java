package com.sangnv.procare;

import android.os.Bundle;
import android.graphics.Color;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.CompoundButton;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.RadioButton;
import android.widget.RadioGroup;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

import com.google.gson.JsonSyntaxException;
import com.google.gson.reflect.TypeToken;
import com.sangnv.procare.Model.ClinicalAssessment;
import com.sangnv.procare.utils.SharedPrefs;

import java.text.DateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

public class MainActivity extends AppCompatActivity {
    private static final String KEY_CURRENT_ASSESSMENT = "clinical_assessment_current";
    private static final String KEY_ASSESSMENT_HISTORY = "clinical_assessment_history";

    private ClinicalAssessment assessment;
    private boolean isBinding;

    private EditText patientIdView;
    private EditText admissionDateTimeView;
    private EditText fullNameView;
    private EditText ageView;
    private EditText suspectedInfectionView;
    private EditText wardView;
    private EditText otherComorbidityView;
    private EditText news2RespirationMeasuredView;
    private EditText news2Spo2MeasuredView;
    private EditText news2OxygenMeasuredView;
    private EditText news2TemperatureMeasuredView;
    private EditText news2SystolicBpMeasuredView;
    private EditText news2HeartRateMeasuredView;
    private EditText news2ConsciousnessMeasuredView;
    private EditText lactateView;
    private EditText lactateSampleTimeView;
    private EditText sofaRespirationMeasuredView;
    private EditText sofaCoagulationMeasuredView;
    private EditText sofaLiverMeasuredView;
    private EditText sofaCardiovascularMeasuredView;
    private EditText sofaNeurologicMeasuredView;
    private EditText sofaRenalMeasuredView;
    private EditText treatmentDaysView;

    private RadioGroup genderGroup;
    private RadioGroup lactateLevelGroup;
    private RadioGroup treatmentOutcomeGroup;
    private RadioGroup news2RespirationGroup;
    private RadioGroup news2Spo2Group;
    private RadioGroup news2OxygenGroup;
    private RadioGroup news2TemperatureGroup;
    private RadioGroup news2SystolicBpGroup;
    private RadioGroup news2HeartRateGroup;
    private RadioGroup news2ConsciousnessGroup;
    private RadioGroup sofaRespirationGroup;
    private RadioGroup sofaCoagulationGroup;
    private RadioGroup sofaLiverGroup;
    private RadioGroup sofaCardiovascularGroup;
    private RadioGroup sofaNeurologicGroup;
    private RadioGroup sofaRenalGroup;

    private CheckBox diabetesView;
    private CheckBox chronicKidneyDiseaseView;
    private CheckBox liverFailureView;
    private CheckBox hypertensionView;
    private CheckBox copdView;
    private CheckBox news2Spo2Scale2View;
    private CheckBox qsofaRespirationView;
    private CheckBox qsofaSystolicBpView;
    private CheckBox qsofaConsciousnessView;
    private CheckBox vasopressorView;

    private TextView quickSummaryView;
    private TextView news2TotalView;
    private TextView news2RiskView;
    private TextView news2ActionView;
    private TextView news2MonitoringView;
    private TextView news2HighestCriterionView;
    private TextView qsofaTotalView;
    private TextView sofaTotalView;
    private TextView sepsisDiagnosisView;
    private TextView lastSavedView;
    private Button saveAssessmentButton;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        setTitle(R.string.app_name);

        assessment = loadCurrentAssessment();
        buildAssessmentForm((LinearLayout) findViewById(R.id.form_container));
        bindAssessmentToViews();
        recalculateAndSave(false);
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        getMenuInflater().inflate(R.menu.main, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        if (item.getItemId() == R.id.action_clear_assessment) {
            assessment = new ClinicalAssessment();
            bindAssessmentToViews();
            recalculateAndSave(false);
            return true;
        }
        return super.onOptionsItemSelected(item);
    }

    private void buildAssessmentForm(LinearLayout container) {
        container.removeAllViews();
        addTitle(container, getString(R.string.assessment_form_title));
        quickSummaryView = addAlertText(container, getString(R.string.quick_summary_empty), "#455A64");

        addSection(container, getString(R.string.section_patient_info));
        patientIdView = addEditText(container, getString(R.string.patient_id));
        admissionDateTimeView = addEditText(container, getString(R.string.admission_datetime));
        fullNameView = addEditText(container, getString(R.string.full_name));
        ageView = addEditText(container, getString(R.string.age));
        genderGroup = addRadioGroup(container, getString(R.string.gender), new String[]{getString(R.string.male), getString(R.string.female)}, null);
        suspectedInfectionView = addEditText(container, getString(R.string.suspected_infection));
        wardView = addEditText(container, getString(R.string.ward));

        addLabel(container, getString(R.string.comorbidities));
        diabetesView = addCheckBox(container, getString(R.string.diabetes));
        chronicKidneyDiseaseView = addCheckBox(container, getString(R.string.chronic_kidney_disease));
        liverFailureView = addCheckBox(container, getString(R.string.liver_failure));
        hypertensionView = addCheckBox(container, getString(R.string.hypertension));
        copdView = addCheckBox(container, getString(R.string.copd));
        otherComorbidityView = addEditText(container, getString(R.string.other_comorbidity));

        addSection(container, getString(R.string.section_news2));
        addLabel(container, getString(R.string.news2_quick_hint));
        news2RespirationMeasuredView = addNumberEditText(container, getString(R.string.news2_respiration));
        news2RespirationGroup = addScoreRadioGroup(container, getString(R.string.news2_respiration), new String[]{"≤ 8", "9-11", "12-20", "21-24", "≥ 25"}, new int[]{3, 1, 0, 2, 3});
        news2Spo2Scale2View = addCheckBox(container, getString(R.string.news2_spo2_scale2));
        news2Spo2MeasuredView = addNumberEditText(container, getString(R.string.news2_spo2));
        news2Spo2Group = addScoreRadioGroup(container, getString(R.string.news2_spo2), new String[]{"≤ 91", "92-93", "94-95", "≥ 96"}, new int[]{3, 2, 1, 0});
        news2OxygenMeasuredView = addEditText(container, getString(R.string.news2_oxygen_note));
        news2OxygenGroup = addScoreRadioGroup(container, getString(R.string.news2_oxygen), new String[]{getString(R.string.yes), getString(R.string.no)}, new int[]{2, 0});
        news2TemperatureMeasuredView = addDecimalEditText(container, getString(R.string.news2_temperature));
        news2TemperatureGroup = addScoreRadioGroup(container, getString(R.string.news2_temperature), new String[]{"≤ 35.0", "35.1-36.0", "36.1-38.0", "38.1-39.0", "≥ 39.1"}, new int[]{3, 1, 0, 1, 2});
        news2SystolicBpMeasuredView = addNumberEditText(container, getString(R.string.news2_systolic_bp));
        news2SystolicBpGroup = addScoreRadioGroup(container, getString(R.string.news2_systolic_bp), new String[]{"≤ 90", "91-100", "101-110", "111-219", "≥ 220"}, new int[]{3, 2, 1, 0, 3});
        news2HeartRateMeasuredView = addNumberEditText(container, getString(R.string.news2_heart_rate));
        news2HeartRateGroup = addScoreRadioGroup(container, getString(R.string.news2_heart_rate), new String[]{"≤ 40", "41-50", "51-90", "91-110", "111-130", "≥ 131"}, new int[]{3, 1, 0, 1, 2, 3});
        news2ConsciousnessMeasuredView = addEditText(container, getString(R.string.news2_consciousness_hint));
        news2ConsciousnessGroup = addScoreRadioGroup(container, getString(R.string.news2_consciousness), new String[]{"Tỉnh (A)", "Lú lẫn mới", "Gọi hỏi (V)", "Đau (P)", "Không đáp ứng (U)"}, new int[]{0, 3, 3, 3, 3});
        news2TotalView = addTotalText(container, getString(R.string.news2_total));
        news2RiskView = addAlertText(container, getString(R.string.news2_risk_empty), "#455A64");
        news2ActionView = addLabel(container, getString(R.string.news2_action_empty));
        news2MonitoringView = addLabel(container, getString(R.string.news2_monitoring_empty));
        news2HighestCriterionView = addLabel(container, getString(R.string.news2_highest_empty));

        addSection(container, getString(R.string.section_qsofa));
        qsofaRespirationView = addCheckBox(container, getString(R.string.qsofa_respiration));
        qsofaSystolicBpView = addCheckBox(container, getString(R.string.qsofa_systolic_bp));
        qsofaConsciousnessView = addCheckBox(container, getString(R.string.qsofa_consciousness));
        qsofaTotalView = addTotalText(container, getString(R.string.qsofa_total));

        addSection(container, getString(R.string.section_lactate));
        lactateView = addEditText(container, getString(R.string.lactate_value));
        lactateSampleTimeView = addEditText(container, getString(R.string.lactate_sample_time));
        lactateLevelGroup = addRadioGroup(container, getString(R.string.lactate_level), new String[]{"< 2 mmol/L", "2 - 3.9 mmol/L", "≥ 4 mmol/L"}, null);

        addSection(container, getString(R.string.section_sofa));
        sofaRespirationMeasuredView = addEditText(container, getString(R.string.actual_result));
        sofaRespirationGroup = addScoreRadioGroup(container, getString(R.string.sofa_respiration), new String[]{"0", "1", "2", "3", "4"}, new int[]{0, 1, 2, 3, 4});
        sofaCoagulationMeasuredView = addEditText(container, getString(R.string.actual_result));
        sofaCoagulationGroup = addScoreRadioGroup(container, getString(R.string.sofa_coagulation), new String[]{"0", "1", "2", "3", "4"}, new int[]{0, 1, 2, 3, 4});
        sofaLiverMeasuredView = addEditText(container, getString(R.string.actual_result));
        sofaLiverGroup = addScoreRadioGroup(container, getString(R.string.sofa_liver), new String[]{"0", "1", "2", "3", "4"}, new int[]{0, 1, 2, 3, 4});
        sofaCardiovascularMeasuredView = addEditText(container, getString(R.string.actual_result));
        sofaCardiovascularGroup = addScoreRadioGroup(container, getString(R.string.sofa_cardiovascular), new String[]{"0", "1", "2", "3", "4"}, new int[]{0, 1, 2, 3, 4});
        sofaNeurologicMeasuredView = addEditText(container, getString(R.string.actual_result));
        sofaNeurologicGroup = addScoreRadioGroup(container, getString(R.string.sofa_neurologic), new String[]{"0", "1", "2", "3", "4"}, new int[]{0, 1, 2, 3, 4});
        sofaRenalMeasuredView = addEditText(container, getString(R.string.actual_result));
        sofaRenalGroup = addScoreRadioGroup(container, getString(R.string.sofa_renal), new String[]{"0", "1", "2", "3", "4"}, new int[]{0, 1, 2, 3, 4});
        vasopressorView = addCheckBox(container, getString(R.string.vasopressor));
        sofaTotalView = addTotalText(container, getString(R.string.sofa_total));

        addSection(container, getString(R.string.section_outcome));
        sepsisDiagnosisView = addTotalText(container, getString(R.string.sepsis_diagnosis));
        treatmentOutcomeGroup = addRadioGroup(container, getString(R.string.treatment_outcome), new String[]{getString(R.string.outcome_recovered), getString(R.string.outcome_transfer), getString(R.string.outcome_death)}, null);
        treatmentDaysView = addEditText(container, getString(R.string.treatment_days));
        saveAssessmentButton = addButton(container, getString(R.string.save_assessment));
        saveAssessmentButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                recalculateAndSave(false);
                if (!hasMinimalAssessmentData()) {
                    Toast.makeText(MainActivity.this, R.string.save_assessment_missing, Toast.LENGTH_SHORT).show();
                    return;
                }
                appendAssessmentHistory();
                lastSavedView.setText(getString(R.string.assessment_saved_format, DateFormat.getDateTimeInstance().format(new Date(assessment.savedAtMillis))));
            }
        });
        lastSavedView = addTotalText(container, getString(R.string.last_saved));
    }

    private void bindAssessmentToViews() {
        isBinding = true;
        patientIdView.setText(assessment.patientId);
        admissionDateTimeView.setText(assessment.admissionDateTime);
        fullNameView.setText(assessment.fullName);
        ageView.setText(assessment.age);
        checkRadioByText(genderGroup, assessment.gender);
        suspectedInfectionView.setText(assessment.suspectedInfection);
        wardView.setText(assessment.ward);
        diabetesView.setChecked(assessment.diabetes);
        chronicKidneyDiseaseView.setChecked(assessment.chronicKidneyDisease);
        liverFailureView.setChecked(assessment.liverFailure);
        hypertensionView.setChecked(assessment.hypertension);
        copdView.setChecked(assessment.copd);
        otherComorbidityView.setText(assessment.otherComorbidity);
        news2RespirationMeasuredView.setText(assessment.news2RespirationMeasured);
        news2Spo2MeasuredView.setText(assessment.news2Spo2Measured);
        news2Spo2Scale2View.setChecked(assessment.news2Spo2Scale2);
        news2OxygenMeasuredView.setText(assessment.news2OxygenMeasured);
        news2TemperatureMeasuredView.setText(assessment.news2TemperatureMeasured);
        news2SystolicBpMeasuredView.setText(assessment.news2SystolicBpMeasured);
        news2HeartRateMeasuredView.setText(assessment.news2HeartRateMeasured);
        news2ConsciousnessMeasuredView.setText(assessment.news2ConsciousnessMeasured);
        checkRadioByOption(news2RespirationGroup, assessment.news2RespirationOption, assessment.news2Respiration);
        checkRadioByOption(news2Spo2Group, assessment.news2Spo2Option, assessment.news2Spo2);
        checkRadioByOption(news2OxygenGroup, assessment.news2OxygenOption, assessment.news2Oxygen);
        checkRadioByOption(news2TemperatureGroup, assessment.news2TemperatureOption, assessment.news2Temperature);
        checkRadioByOption(news2SystolicBpGroup, assessment.news2SystolicBpOption, assessment.news2SystolicBp);
        checkRadioByOption(news2HeartRateGroup, assessment.news2HeartRateOption, assessment.news2HeartRate);
        checkRadioByOption(news2ConsciousnessGroup, assessment.news2ConsciousnessOption, assessment.news2Consciousness);
        qsofaRespirationView.setChecked(assessment.qsofaRespiration);
        qsofaSystolicBpView.setChecked(assessment.qsofaSystolicBp);
        qsofaConsciousnessView.setChecked(assessment.qsofaConsciousness);
        lactateView.setText(assessment.lactate);
        lactateSampleTimeView.setText(assessment.lactateSampleTime);
        checkRadioByText(lactateLevelGroup, assessment.lactateLevel);
        sofaRespirationMeasuredView.setText(assessment.sofaRespirationMeasured);
        sofaCoagulationMeasuredView.setText(assessment.sofaCoagulationMeasured);
        sofaLiverMeasuredView.setText(assessment.sofaLiverMeasured);
        sofaCardiovascularMeasuredView.setText(assessment.sofaCardiovascularMeasured);
        sofaNeurologicMeasuredView.setText(assessment.sofaNeurologicMeasured);
        sofaRenalMeasuredView.setText(assessment.sofaRenalMeasured);
        checkRadioByScore(sofaRespirationGroup, assessment.sofaRespiration);
        checkRadioByScore(sofaCoagulationGroup, assessment.sofaCoagulation);
        checkRadioByScore(sofaLiverGroup, assessment.sofaLiver);
        checkRadioByScore(sofaCardiovascularGroup, assessment.sofaCardiovascular);
        checkRadioByScore(sofaNeurologicGroup, assessment.sofaNeurologic);
        checkRadioByScore(sofaRenalGroup, assessment.sofaRenal);
        vasopressorView.setChecked(assessment.vasopressor);
        checkRadioByText(treatmentOutcomeGroup, assessment.treatmentOutcome);
        treatmentDaysView.setText(assessment.treatmentDays);
        isBinding = false;
    }

    private void recalculateAndSave(boolean appendHistory) {
        if (isBinding) {
            return;
        }

        updateAssessmentFromViews();
        assessment.news2Total = assessment.news2Respiration + assessment.news2Spo2 + assessment.news2Oxygen
                + assessment.news2Temperature + assessment.news2SystolicBp + assessment.news2HeartRate
                + assessment.news2Consciousness;
        assessment.qsofaTotal = booleanScore(assessment.qsofaRespiration) + booleanScore(assessment.qsofaSystolicBp)
                + booleanScore(assessment.qsofaConsciousness);
        assessment.sofaTotal = assessment.sofaRespiration + assessment.sofaCoagulation + assessment.sofaLiver
                + assessment.sofaCardiovascular + assessment.sofaNeurologic + assessment.sofaRenal;
        assessment.sepsisDiagnosis = buildSepsisDiagnosis();
        assessment.savedAtMillis = System.currentTimeMillis();

        updateQuickSummaryViews();
        news2TotalView.setText(getString(R.string.news2_total_format, assessment.news2Total));
        qsofaTotalView.setText(getString(R.string.qsofa_total_format, assessment.qsofaTotal));
        sofaTotalView.setText(getString(R.string.sofa_total_format, assessment.sofaTotal));
        sepsisDiagnosisView.setText(assessment.sepsisDiagnosis);
        lastSavedView.setText(getString(R.string.last_saved_format, DateFormat.getDateTimeInstance().format(new Date(assessment.savedAtMillis))));

        saveCurrentAssessment();
        if (appendHistory) {
            appendAssessmentHistory();
        }
    }

    private void updateAssessmentFromViews() {
        assessment.patientId = patientIdView.getText().toString();
        assessment.admissionDateTime = admissionDateTimeView.getText().toString();
        assessment.fullName = fullNameView.getText().toString();
        assessment.age = ageView.getText().toString();
        assessment.gender = selectedText(genderGroup);
        assessment.suspectedInfection = suspectedInfectionView.getText().toString();
        assessment.ward = wardView.getText().toString();
        assessment.diabetes = diabetesView.isChecked();
        assessment.chronicKidneyDisease = chronicKidneyDiseaseView.isChecked();
        assessment.liverFailure = liverFailureView.isChecked();
        assessment.hypertension = hypertensionView.isChecked();
        assessment.copd = copdView.isChecked();
        assessment.otherComorbidity = otherComorbidityView.getText().toString();
        assessment.news2RespirationMeasured = news2RespirationMeasuredView.getText().toString();
        assessment.news2Spo2Measured = news2Spo2MeasuredView.getText().toString();
        assessment.news2Spo2Scale2 = news2Spo2Scale2View.isChecked();
        assessment.news2OxygenMeasured = news2OxygenMeasuredView.getText().toString();
        assessment.news2TemperatureMeasured = news2TemperatureMeasuredView.getText().toString();
        assessment.news2SystolicBpMeasured = news2SystolicBpMeasuredView.getText().toString();
        assessment.news2HeartRateMeasured = news2HeartRateMeasuredView.getText().toString();
        assessment.news2ConsciousnessMeasured = news2ConsciousnessMeasuredView.getText().toString();
        assessment.news2Oxygen = selectedScore(news2OxygenGroup);
        assessment.news2OxygenOption = selectedOption(news2OxygenGroup);
        applyNews2AutoScores();
        assessment.qsofaRespiration = qsofaRespirationView.isChecked();
        assessment.qsofaSystolicBp = qsofaSystolicBpView.isChecked();
        assessment.qsofaConsciousness = qsofaConsciousnessView.isChecked();
        assessment.lactate = lactateView.getText().toString();
        assessment.lactateSampleTime = lactateSampleTimeView.getText().toString();
        assessment.lactateLevel = selectedText(lactateLevelGroup);
        assessment.sofaRespirationMeasured = sofaRespirationMeasuredView.getText().toString();
        assessment.sofaCoagulationMeasured = sofaCoagulationMeasuredView.getText().toString();
        assessment.sofaLiverMeasured = sofaLiverMeasuredView.getText().toString();
        assessment.sofaCardiovascularMeasured = sofaCardiovascularMeasuredView.getText().toString();
        assessment.sofaNeurologicMeasured = sofaNeurologicMeasuredView.getText().toString();
        assessment.sofaRenalMeasured = sofaRenalMeasuredView.getText().toString();
        assessment.sofaRespiration = selectedScore(sofaRespirationGroup);
        assessment.sofaCoagulation = selectedScore(sofaCoagulationGroup);
        assessment.sofaLiver = selectedScore(sofaLiverGroup);
        assessment.sofaCardiovascular = selectedScore(sofaCardiovascularGroup);
        assessment.sofaNeurologic = selectedScore(sofaNeurologicGroup);
        assessment.sofaRenal = selectedScore(sofaRenalGroup);
        assessment.vasopressor = vasopressorView.isChecked();
        assessment.treatmentOutcome = selectedText(treatmentOutcomeGroup);
        assessment.treatmentDays = treatmentDaysView.getText().toString();
    }

    private void applyNews2AutoScores() {
        assessment.news2Respiration = scoreRespiration(parseInteger(assessment.news2RespirationMeasured), selectedScore(news2RespirationGroup));
        assessment.news2RespirationOption = optionByScore(news2RespirationGroup, assessment.news2Respiration);
        safelyCheckRadioByScore(news2RespirationGroup, assessment.news2Respiration);

        assessment.news2Spo2 = assessment.news2Spo2Scale2
                ? scoreSpo2Scale2(parseInteger(assessment.news2Spo2Measured), assessment.news2Oxygen > 0, selectedScore(news2Spo2Group))
                : scoreSpo2Scale1(parseInteger(assessment.news2Spo2Measured), selectedScore(news2Spo2Group));
        assessment.news2Spo2Option = assessment.news2Spo2Scale2
                ? getString(R.string.news2_spo2_scale2_option)
                : optionByScore(news2Spo2Group, assessment.news2Spo2);
        safelyCheckRadioByScore(news2Spo2Group, assessment.news2Spo2);

        assessment.news2Temperature = scoreTemperature(parseDouble(assessment.news2TemperatureMeasured), selectedScore(news2TemperatureGroup));
        assessment.news2TemperatureOption = optionByScore(news2TemperatureGroup, assessment.news2Temperature);
        safelyCheckRadioByScore(news2TemperatureGroup, assessment.news2Temperature);

        assessment.news2SystolicBp = scoreSystolicBp(parseInteger(assessment.news2SystolicBpMeasured), selectedScore(news2SystolicBpGroup));
        assessment.news2SystolicBpOption = optionByScore(news2SystolicBpGroup, assessment.news2SystolicBp);
        safelyCheckRadioByScore(news2SystolicBpGroup, assessment.news2SystolicBp);

        assessment.news2HeartRate = scoreHeartRate(parseInteger(assessment.news2HeartRateMeasured), selectedScore(news2HeartRateGroup));
        assessment.news2HeartRateOption = optionByScore(news2HeartRateGroup, assessment.news2HeartRate);
        safelyCheckRadioByScore(news2HeartRateGroup, assessment.news2HeartRate);

        assessment.news2Consciousness = scoreConsciousness(assessment.news2ConsciousnessMeasured, selectedScore(news2ConsciousnessGroup));
        assessment.news2ConsciousnessOption = consciousnessOption(assessment.news2ConsciousnessMeasured, news2ConsciousnessGroup);
        safelyCheckRadioByScore(news2ConsciousnessGroup, assessment.news2Consciousness);

        autoSyncQsofaFromVitals();
    }

    private void autoSyncQsofaFromVitals() {
        boolean oldBinding = isBinding;
        isBinding = true;
        Integer respiration = parseInteger(assessment.news2RespirationMeasured);
        Integer systolicBp = parseInteger(assessment.news2SystolicBpMeasured);
        if (respiration != null) {
            qsofaRespirationView.setChecked(respiration >= 22);
            assessment.qsofaRespiration = respiration >= 22;
        }
        if (systolicBp != null) {
            qsofaSystolicBpView.setChecked(systolicBp <= 100);
            assessment.qsofaSystolicBp = systolicBp <= 100;
        }
        boolean alteredConsciousness = assessment.news2Consciousness == 3;
        if (hasText(assessment.news2ConsciousnessMeasured) || findCheckedRadioButton(news2ConsciousnessGroup) != null) {
            qsofaConsciousnessView.setChecked(alteredConsciousness);
            assessment.qsofaConsciousness = alteredConsciousness;
        }
        isBinding = oldBinding;
    }

    private int scoreRespiration(Integer value, int fallback) {
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

    private int scoreSpo2Scale1(Integer value, int fallback) {
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

    private int scoreSpo2Scale2(Integer value, boolean oxygen, int fallback) {
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

    private int scoreTemperature(Double value, int fallback) {
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

    private int scoreSystolicBp(Integer value, int fallback) {
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

    private int scoreHeartRate(Integer value, int fallback) {
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

    private int scoreConsciousness(String value, int fallback) {
        if (!hasText(value)) {
            return fallback;
        }
        String normalized = value.trim().toUpperCase();
        return normalized.equals("A") || normalized.contains("TINH") || normalized.contains("TỈNH") ? 0 : 3;
    }

    private Integer parseInteger(String value) {
        if (!hasText(value)) {
            return null;
        }
        String digits = value.trim().replaceAll("[^0-9-]", "");
        if (!hasText(digits)) {
            return null;
        }
        try {
            return Integer.parseInt(digits);
        } catch (NumberFormatException exception) {
            return null;
        }
    }

    private Double parseDouble(String value) {
        if (!hasText(value)) {
            return null;
        }
        String normalized = value.trim().replace(',', '.').replaceAll("[^0-9.-]", "");
        if (!hasText(normalized)) {
            return null;
        }
        try {
            return Double.parseDouble(normalized);
        } catch (NumberFormatException exception) {
            return null;
        }
    }

    private boolean hasText(String value) {
        return value != null && !value.trim().isEmpty();
    }

    private void updateQuickSummaryViews() {
        int color = Color.parseColor(news2AlertColor());
        String risk = news2RiskText();
        String action = news2ActionText();
        String monitoring = news2MonitoringText();
        String highestCriterion = highestNews2CriterionText();
        quickSummaryView.setText(getString(R.string.quick_summary_format, assessment.news2Total, risk, action));
        quickSummaryView.setTextColor(Color.WHITE);
        quickSummaryView.setBackgroundColor(color);
        news2RiskView.setText(risk);
        news2RiskView.setTextColor(Color.WHITE);
        news2RiskView.setBackgroundColor(color);
        news2ActionView.setText(action);
        news2MonitoringView.setText(monitoring);
        news2HighestCriterionView.setText(highestCriterion);
    }

    private String news2RiskText() {
        if (assessment.news2Total >= 7) {
            return getString(R.string.news2_risk_emergency);
        }
        if (assessment.news2Total >= 5) {
            return getString(R.string.news2_risk_urgent);
        }
        if (hasSingleThreeScore()) {
            return getString(R.string.news2_risk_single_three);
        }
        if (assessment.news2Total == 0) {
            return getString(R.string.news2_risk_low_zero);
        }
        return getString(R.string.news2_risk_low);
    }

    private String news2ActionText() {
        if (assessment.news2Total >= 7) {
            return getString(R.string.news2_action_emergency);
        }
        if (assessment.news2Total >= 5) {
            return getString(R.string.news2_action_urgent);
        }
        if (hasSingleThreeScore()) {
            return getString(R.string.news2_action_single_three);
        }
        return getString(R.string.news2_action_low);
    }

    private String news2MonitoringText() {
        if (assessment.news2Total >= 7) {
            return getString(R.string.news2_monitoring_emergency);
        }
        if (assessment.news2Total >= 5 || hasSingleThreeScore()) {
            return getString(R.string.news2_monitoring_hourly);
        }
        if (assessment.news2Total == 0) {
            return getString(R.string.news2_monitoring_low_zero);
        }
        return getString(R.string.news2_monitoring_low);
    }

    private String news2AlertColor() {
        if (assessment.news2Total >= 7) {
            return "#B71C1C";
        }
        if (assessment.news2Total >= 5 || hasSingleThreeScore()) {
            return "#E65100";
        }
        if (assessment.news2Total > 0) {
            return "#F9A825";
        }
        return "#2E7D32";
    }

    private boolean hasSingleThreeScore() {
        return assessment.news2Respiration == 3 || assessment.news2Spo2 == 3 || assessment.news2Temperature == 3
                || assessment.news2SystolicBp == 3 || assessment.news2HeartRate == 3 || assessment.news2Consciousness == 3;
    }

    private String highestNews2CriterionText() {
        StringBuilder builder = new StringBuilder(getString(R.string.news2_highest_prefix));
        appendCriterion(builder, getString(R.string.news2_respiration), assessment.news2Respiration);
        appendCriterion(builder, getString(R.string.news2_spo2), assessment.news2Spo2);
        appendCriterion(builder, getString(R.string.news2_oxygen), assessment.news2Oxygen);
        appendCriterion(builder, getString(R.string.news2_temperature), assessment.news2Temperature);
        appendCriterion(builder, getString(R.string.news2_systolic_bp), assessment.news2SystolicBp);
        appendCriterion(builder, getString(R.string.news2_heart_rate), assessment.news2HeartRate);
        appendCriterion(builder, getString(R.string.news2_consciousness), assessment.news2Consciousness);
        if (builder.length() == getString(R.string.news2_highest_prefix).length()) {
            return getString(R.string.news2_highest_empty);
        }
        return builder.toString();
    }

    private void appendCriterion(StringBuilder builder, String label, int score) {
        if (score < 3) {
            return;
        }
        if (builder.length() > getString(R.string.news2_highest_prefix).length()) {
            builder.append(", ");
        }
        builder.append(label);
    }

    private boolean hasMinimalAssessmentData() {
        boolean hasPatient = hasText(assessment.patientId) || hasText(assessment.fullName);
        boolean hasNews2Input = hasText(assessment.news2RespirationMeasured) || hasText(assessment.news2Spo2Measured)
                || hasText(assessment.news2TemperatureMeasured) || hasText(assessment.news2SystolicBpMeasured)
                || hasText(assessment.news2HeartRateMeasured) || hasText(assessment.news2ConsciousnessMeasured);
        return hasPatient && hasNews2Input;
    }

    private String buildSepsisDiagnosis() {
        boolean hasSepsis = assessment.sofaTotal >= 2;
        boolean shock = assessment.vasopressor && lactateAtLeastTwo();
        if (shock) {
            return getString(R.string.diagnosis_shock);
        }
        if (hasSepsis) {
            return getString(R.string.diagnosis_sepsis);
        }
        return getString(R.string.diagnosis_no_sepsis);
    }

    private boolean lactateAtLeastTwo() {
        if (assessment.lactateLevel != null && !assessment.lactateLevel.isEmpty()) {
            return !assessment.lactateLevel.startsWith("<");
        }
        try {
            return Double.parseDouble(assessment.lactate.trim().replace(',', '.')) >= 2.0;
        } catch (NumberFormatException exception) {
            return false;
        }
    }

    private void saveCurrentAssessment() {
        SharedPrefs.getInstance().put(KEY_CURRENT_ASSESSMENT, App.self().getGSon().toJson(assessment));
    }

    private void appendAssessmentHistory() {
        String json = SharedPrefs.getInstance().get(KEY_ASSESSMENT_HISTORY, String.class);
        List<ClinicalAssessment> history = null;
        if (json != null && !json.trim().isEmpty()) {
            try {
                history = App.self().getGSon().fromJson(json, new TypeToken<List<ClinicalAssessment>>() {
                }.getType());
            } catch (JsonSyntaxException exception) {
                history = null;
            }
        }
        if (history == null) {
            history = new ArrayList<>();
        }
        history.add(App.self().getGSon().fromJson(App.self().getGSon().toJson(assessment), ClinicalAssessment.class));
        SharedPrefs.getInstance().put(KEY_ASSESSMENT_HISTORY, App.self().getGSon().toJson(history));
    }

    private ClinicalAssessment loadCurrentAssessment() {
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

    private Button addButton(LinearLayout container, String text) {
        Button button = new Button(this);
        button.setText(text);
        container.addView(button, matchWrapParams());
        return button;
    }

    private TextView addAlertText(LinearLayout container, String text, String color) {
        TextView textView = addLabel(container, text);
        textView.setTextSize(18);
        textView.setTextColor(Color.WHITE);
        textView.setBackgroundColor(Color.parseColor(color));
        textView.setPadding(16, 16, 16, 16);
        return textView;
    }

    private EditText addNumberEditText(LinearLayout container, String hint) {
        EditText editText = addEditText(container, hint);
        editText.setInputType(android.text.InputType.TYPE_CLASS_NUMBER);
        return editText;
    }

    private EditText addDecimalEditText(LinearLayout container, String hint) {
        EditText editText = addEditText(container, hint);
        editText.setInputType(android.text.InputType.TYPE_CLASS_NUMBER | android.text.InputType.TYPE_NUMBER_FLAG_DECIMAL);
        return editText;
    }

    private EditText addEditText(LinearLayout container, String hint) {
        EditText editText = new EditText(this);
        editText.setHint(hint);
        editText.setSingleLine(false);
        editText.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {
            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
                recalculateAndSave(false);
            }

            @Override
            public void afterTextChanged(Editable s) {
            }
        });
        container.addView(editText, matchWrapParams());
        return editText;
    }

    private CheckBox addCheckBox(LinearLayout container, String text) {
        CheckBox checkBox = new CheckBox(this);
        checkBox.setText(text);
        checkBox.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                recalculateAndSave(false);
            }
        });
        container.addView(checkBox, matchWrapParams());
        return checkBox;
    }

    private RadioGroup addScoreRadioGroup(LinearLayout container, String label, String[] options, int[] scores) {
        return addRadioGroup(container, label, options, scores);
    }

    private RadioGroup addRadioGroup(LinearLayout container, String label, String[] options, int[] scores) {
        addLabel(container, label);
        RadioGroup group = new RadioGroup(this);
        group.setOrientation(RadioGroup.VERTICAL);
        for (int i = 0; i < options.length; i++) {
            RadioButton radioButton = new RadioButton(this);
            radioButton.setId(View.generateViewId());
            radioButton.setText(scores == null ? options[i] : options[i] + " (" + scores[i] + " điểm)");
            radioButton.setContentDescription(options[i]);
            radioButton.setTag(scores == null ? options[i] : scores[i]);
            group.addView(radioButton, matchWrapParams());
        }
        group.setOnCheckedChangeListener(new RadioGroup.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(RadioGroup group, int checkedId) {
                recalculateAndSave(false);
            }
        });
        container.addView(group, matchWrapParams());
        return group;
    }

    private TextView addTotalText(LinearLayout container, String text) {
        TextView textView = addLabel(container, text);
        textView.setTextSize(18);
        return textView;
    }

    private void addTitle(LinearLayout container, String text) {
        TextView textView = addLabel(container, text);
        textView.setTextSize(22);
    }

    private void addSection(LinearLayout container, String text) {
        TextView textView = addLabel(container, text);
        textView.setTextSize(20);
        textView.setPadding(0, 24, 0, 8);
    }

    private TextView addLabel(LinearLayout container, String text) {
        TextView textView = new TextView(this);
        textView.setText(text);
        textView.setPadding(0, 12, 0, 4);
        container.addView(textView, matchWrapParams());
        return textView;
    }

    private LinearLayout.LayoutParams matchWrapParams() {
        return new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT);
    }

    private void safelyCheckRadioByScore(RadioGroup group, int score) {
        boolean oldBinding = isBinding;
        isBinding = true;
        checkRadioByScore(group, score);
        isBinding = oldBinding;
    }

    private String optionByScore(RadioGroup group, int score) {
        for (int i = 0; i < group.getChildCount(); i++) {
            View child = group.getChildAt(i);
            if (child.getTag() instanceof Integer && ((Integer) child.getTag()) == score && child.getContentDescription() != null) {
                return child.getContentDescription().toString();
            }
        }
        return selectedOption(group);
    }

    private String consciousnessOption(String measuredValue, RadioGroup group) {
        if (hasText(measuredValue)) {
            return measuredValue.trim();
        }
        return selectedOption(group);
    }

    private int selectedScore(RadioGroup group) {
        RadioButton checked = findCheckedRadioButton(group);
        if (checked == null || !(checked.getTag() instanceof Integer)) {
            return 0;
        }
        return (Integer) checked.getTag();
    }

    private String selectedText(RadioGroup group) {
        RadioButton checked = findCheckedRadioButton(group);
        if (checked == null) {
            return "";
        }
        Object tag = checked.getTag();
        return tag instanceof String ? (String) tag : checked.getText().toString();
    }

    private String selectedOption(RadioGroup group) {
        RadioButton checked = findCheckedRadioButton(group);
        if (checked == null || checked.getContentDescription() == null) {
            return "";
        }
        return checked.getContentDescription().toString();
    }

    private RadioButton findCheckedRadioButton(RadioGroup group) {
        int checkedId = group.getCheckedRadioButtonId();
        return checkedId == -1 ? null : group.findViewById(checkedId);
    }

    private void checkRadioByScore(RadioGroup group, int score) {
        checkRadioByTag(group, score);
    }

    private void checkRadioByOption(RadioGroup group, String option, int fallbackScore) {
        if (option == null || option.isEmpty()) {
            group.clearCheck();
            return;
        }
        for (int i = 0; i < group.getChildCount(); i++) {
            View child = group.getChildAt(i);
            if (option.contentEquals(child.getContentDescription())) {
                group.check(child.getId());
                return;
            }
        }
        checkRadioByScore(group, fallbackScore);
    }

    private void checkRadioByText(RadioGroup group, String text) {
        if (text == null || text.isEmpty()) {
            group.clearCheck();
            return;
        }
        checkRadioByTag(group, text);
    }

    private void checkRadioByTag(RadioGroup group, Object tag) {
        for (int i = 0; i < group.getChildCount(); i++) {
            View child = group.getChildAt(i);
            if (tag.equals(child.getTag())) {
                group.check(child.getId());
                return;
            }
        }
        group.clearCheck();
    }

    private int booleanScore(boolean value) {
        return value ? 1 : 0;
    }
}
