package com.sangnv.procare.Model;

public class ClinicalAssessment {
    public String patientId = "";
    public String admissionDateTime = "";
    public String fullName = "";
    public String age = "";
    public String gender = "";
    public String suspectedInfection = "";
    public String ward = "";
    public boolean diabetes;
    public boolean chronicKidneyDisease;
    public boolean liverFailure;
    public boolean hypertension;
    public boolean copd;
    public String otherComorbidity = "";

    public String news2RespirationMeasured = "";
    public int news2Respiration;
    public String news2RespirationOption = "";
    public String news2Spo2Measured = "";
    public boolean news2Spo2Scale2;
    public int news2Spo2;
    public String news2Spo2Option = "";
    public String news2OxygenMeasured = "";
    public int news2Oxygen;
    public String news2OxygenOption = "";
    public String news2TemperatureMeasured = "";
    public int news2Temperature;
    public String news2TemperatureOption = "";
    public String news2SystolicBpMeasured = "";
    public int news2SystolicBp;
    public String news2SystolicBpOption = "";
    public String news2HeartRateMeasured = "";
    public int news2HeartRate;
    public String news2HeartRateOption = "";
    public String news2ConsciousnessMeasured = "";
    public int news2Consciousness;
    public String news2ConsciousnessOption = "";
    public int news2Total;

    public boolean qsofaRespiration;
    public boolean qsofaSystolicBp;
    public boolean qsofaConsciousness;
    public int qsofaTotal;

    public String lactate = "";
    public String lactateSampleTime = "";
    public String lactateLevel = "";

    public String sofaRespirationMeasured = "";
    public int sofaRespiration;
    public String sofaCoagulationMeasured = "";
    public int sofaCoagulation;
    public String sofaLiverMeasured = "";
    public int sofaLiver;
    public String sofaCardiovascularMeasured = "";
    public int sofaCardiovascular;
    public String sofaNeurologicMeasured = "";
    public int sofaNeurologic;
    public String sofaRenalMeasured = "";
    public int sofaRenal;
    public int sofaTotal;
    public boolean vasopressor;

    public String sepsisDiagnosis = "";
    public String treatmentOutcome = "";
    public String treatmentDays = "";
    public long savedAtMillis;
}
