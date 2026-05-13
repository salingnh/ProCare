package com.sangnv.procare;

import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.CheckBox;
import android.widget.CompoundButton;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.RadioButton;
import android.widget.RadioGroup;
import android.widget.TextView;

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
    private CheckBox qsofaRespirationView;
    private CheckBox qsofaSystolicBpView;
    private CheckBox qsofaConsciousnessView;
    private CheckBox vasopressorView;

    private TextView news2TotalView;
    private TextView qsofaTotalView;
    private TextView sofaTotalView;
    private TextView sepsisDiagnosisView;
    private TextView lastSavedView;

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
            recalculateAndSave(true);
            return true;
        }
        return super.onOptionsItemSelected(item);
    }

    private void buildAssessmentForm(LinearLayout container) {
        container.removeAllViews();
        addTitle(container, getString(R.string.assessment_form_title));

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
        news2RespirationMeasuredView = addEditText(container, getString(R.string.measured_value));
        news2RespirationGroup = addScoreRadioGroup(container, getString(R.string.news2_respiration), new String[]{"≤ 8", "9-11", "12-20", "21-24", "≥ 25"}, new int[]{3, 1, 0, 2, 3});
        news2Spo2MeasuredView = addEditText(container, getString(R.string.measured_value));
        news2Spo2Group = addScoreRadioGroup(container, getString(R.string.news2_spo2), new String[]{"≤ 91", "92-93", "94-95", "≥ 96"}, new int[]{3, 2, 1, 0});
        news2OxygenMeasuredView = addEditText(container, getString(R.string.measured_value));
        news2OxygenGroup = addScoreRadioGroup(container, getString(R.string.news2_oxygen), new String[]{getString(R.string.yes), getString(R.string.no)}, new int[]{2, 0});
        news2TemperatureMeasuredView = addEditText(container, getString(R.string.measured_value));
        news2TemperatureGroup = addScoreRadioGroup(container, getString(R.string.news2_temperature), new String[]{"≤ 35.0", "35.1-36.0", "36.1-38.0", "38.1-39.0", "≥ 39.1"}, new int[]{3, 1, 0, 1, 2});
        news2SystolicBpMeasuredView = addEditText(container, getString(R.string.measured_value));
        news2SystolicBpGroup = addScoreRadioGroup(container, getString(R.string.news2_systolic_bp), new String[]{"≤ 90", "91-100", "101-110", "111-219", "≥ 220"}, new int[]{3, 2, 1, 0, 3});
        news2HeartRateMeasuredView = addEditText(container, getString(R.string.measured_value));
        news2HeartRateGroup = addScoreRadioGroup(container, getString(R.string.news2_heart_rate), new String[]{"≤ 40", "41-50", "51-90", "91-110", "111-130", "≥ 131"}, new int[]{3, 1, 0, 1, 2, 3});
        news2ConsciousnessMeasuredView = addEditText(container, getString(R.string.measured_value));
        news2ConsciousnessGroup = addScoreRadioGroup(container, getString(R.string.news2_consciousness), new String[]{"Tỉnh (A)", "Gọi hỏi", "Đau", "Không đáp ứng"}, new int[]{0, 3, 3, 3});
        news2TotalView = addTotalText(container, getString(R.string.news2_total));

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
        assessment.news2OxygenMeasured = news2OxygenMeasuredView.getText().toString();
        assessment.news2TemperatureMeasured = news2TemperatureMeasuredView.getText().toString();
        assessment.news2SystolicBpMeasured = news2SystolicBpMeasuredView.getText().toString();
        assessment.news2HeartRateMeasured = news2HeartRateMeasuredView.getText().toString();
        assessment.news2ConsciousnessMeasured = news2ConsciousnessMeasuredView.getText().toString();
        assessment.news2Respiration = selectedScore(news2RespirationGroup);
        assessment.news2RespirationOption = selectedOption(news2RespirationGroup);
        assessment.news2Spo2 = selectedScore(news2Spo2Group);
        assessment.news2Spo2Option = selectedOption(news2Spo2Group);
        assessment.news2Oxygen = selectedScore(news2OxygenGroup);
        assessment.news2OxygenOption = selectedOption(news2OxygenGroup);
        assessment.news2Temperature = selectedScore(news2TemperatureGroup);
        assessment.news2TemperatureOption = selectedOption(news2TemperatureGroup);
        assessment.news2SystolicBp = selectedScore(news2SystolicBpGroup);
        assessment.news2SystolicBpOption = selectedOption(news2SystolicBpGroup);
        assessment.news2HeartRate = selectedScore(news2HeartRateGroup);
        assessment.news2HeartRateOption = selectedOption(news2HeartRateGroup);
        assessment.news2Consciousness = selectedScore(news2ConsciousnessGroup);
        assessment.news2ConsciousnessOption = selectedOption(news2ConsciousnessGroup);
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
                recalculateAndSave(true);
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
                recalculateAndSave(true);
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
