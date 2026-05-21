enum ClinicalAssessmentInputMode {
  detailed,
  quick,
}

class ClinicalAssessment {
  static const assessmentModeDetailed = 'detailed';
  static const assessmentModeQuick = 'quick';

  String assessmentMode;
  String patientId;
  String admissionDateTime;
  String admissionDate;
  String admissionTime;
  String fullName;
  String age;
  String gender;
  String suspectedInfection;
  String admissionReason;
  String infectionOrgan;
  String ward;
  bool diabetes;
  bool chronicKidneyDisease;
  bool liverFailure;
  bool hypertension;
  bool copd;
  String otherComorbidity;

  String news2RespirationMeasured;
  int news2Respiration;
  String news2RespirationOption;
  bool news2RespirationSelected;
  String news2Spo2Measured;
  bool news2Spo2Scale2;
  int news2Spo2;
  String news2Spo2Option;
  bool news2Spo2Selected;
  String news2OxygenMeasured;
  int news2Oxygen;
  String news2OxygenOption;
  bool news2OxygenSelected;
  String news2TemperatureMeasured;
  int news2Temperature;
  String news2TemperatureOption;
  bool news2TemperatureSelected;
  String news2SystolicBpMeasured;
  int news2SystolicBp;
  String news2SystolicBpOption;
  bool news2SystolicBpSelected;
  String news2HeartRateMeasured;
  int news2HeartRate;
  String news2HeartRateOption;
  bool news2HeartRateSelected;
  String news2ConsciousnessMeasured;
  int news2Consciousness;
  String news2ConsciousnessOption;
  bool news2ConsciousnessSelected;
  int news2Total;

  bool qsofaRespiration;
  bool qsofaRespirationSelected;
  bool qsofaSystolicBp;
  bool qsofaSystolicBpSelected;
  bool qsofaConsciousness;
  bool qsofaConsciousnessSelected;
  int qsofaTotal;

  String lactate;
  String lactateSampleTime;
  String lactateLevel;

  String sofaRespirationMeasured;
  int sofaRespiration;
  bool sofaRespirationSelected;
  String sofaCoagulationMeasured;
  int sofaCoagulation;
  bool sofaCoagulationSelected;
  String sofaLiverMeasured;
  String sofaLiverUnit;
  int sofaLiver;
  bool sofaLiverSelected;
  String sofaCardiovascularMeasured;
  int sofaCardiovascular;
  bool sofaCardiovascularSelected;
  String sofaNeurologicMeasured;
  int sofaNeurologic;
  bool sofaNeurologicSelected;
  String sofaRenalMeasured;
  String sofaRenalUnit;
  int sofaRenal;
  bool sofaRenalSelected;
  int sofaTotal;
  bool vasopressor;

  String sepsisDiagnosis;
  String treatmentOutcome;
  String treatmentDays;
  int createdAtMillis;
  int modifiedAtMillis;
  int savedAtMillis;

  ClinicalAssessment({
    this.assessmentMode = assessmentModeDetailed,
    this.patientId = '',
    this.admissionDateTime = '',
    this.admissionDate = '',
    this.admissionTime = '',
    this.fullName = '',
    this.age = '',
    this.gender = '',
    this.suspectedInfection = '',
    this.admissionReason = '',
    this.infectionOrgan = '',
    this.ward = '',
    this.diabetes = false,
    this.chronicKidneyDisease = false,
    this.liverFailure = false,
    this.hypertension = false,
    this.copd = false,
    this.otherComorbidity = '',
    this.news2RespirationMeasured = '',
    this.news2Respiration = 0,
    this.news2RespirationOption = '',
    this.news2RespirationSelected = false,
    this.news2Spo2Measured = '',
    this.news2Spo2Scale2 = false,
    this.news2Spo2 = 0,
    this.news2Spo2Option = '',
    this.news2Spo2Selected = false,
    this.news2OxygenMeasured = '',
    this.news2Oxygen = 0,
    this.news2OxygenOption = '',
    this.news2OxygenSelected = false,
    this.news2TemperatureMeasured = '',
    this.news2Temperature = 0,
    this.news2TemperatureOption = '',
    this.news2TemperatureSelected = false,
    this.news2SystolicBpMeasured = '',
    this.news2SystolicBp = 0,
    this.news2SystolicBpOption = '',
    this.news2SystolicBpSelected = false,
    this.news2HeartRateMeasured = '',
    this.news2HeartRate = 0,
    this.news2HeartRateOption = '',
    this.news2HeartRateSelected = false,
    this.news2ConsciousnessMeasured = '',
    this.news2Consciousness = 0,
    this.news2ConsciousnessOption = '',
    this.news2ConsciousnessSelected = false,
    this.news2Total = 0,
    this.qsofaRespiration = false,
    this.qsofaRespirationSelected = false,
    this.qsofaSystolicBp = false,
    this.qsofaSystolicBpSelected = false,
    this.qsofaConsciousness = false,
    this.qsofaConsciousnessSelected = false,
    this.qsofaTotal = 0,
    this.lactate = '',
    this.lactateSampleTime = '',
    this.lactateLevel = '',
    this.sofaRespirationMeasured = '',
    this.sofaRespiration = 0,
    this.sofaRespirationSelected = false,
    this.sofaCoagulationMeasured = '',
    this.sofaCoagulation = 0,
    this.sofaCoagulationSelected = false,
    this.sofaLiverMeasured = '',
    this.sofaLiverUnit = 'mg/dL',
    this.sofaLiver = 0,
    this.sofaLiverSelected = false,
    this.sofaCardiovascularMeasured = '',
    this.sofaCardiovascular = 0,
    this.sofaCardiovascularSelected = false,
    this.sofaNeurologicMeasured = '',
    this.sofaNeurologic = 0,
    this.sofaNeurologicSelected = false,
    this.sofaRenalMeasured = '',
    this.sofaRenalUnit = 'mg/dL',
    this.sofaRenal = 0,
    this.sofaRenalSelected = false,
    this.sofaTotal = 0,
    this.vasopressor = false,
    this.sepsisDiagnosis = '',
    this.treatmentOutcome = '',
    this.treatmentDays = '',
    this.createdAtMillis = 0,
    this.modifiedAtMillis = 0,
    this.savedAtMillis = 0,
  });

  factory ClinicalAssessment.fromJson(Map<String, dynamic> json) {
    return ClinicalAssessment(
      assessmentMode: _assessmentMode(json, 'assessmentMode'),
      patientId: _string(json, 'patientId'),
      admissionDateTime: _string(json, 'admissionDateTime'),
      admissionDate: _string(json, 'admissionDate'),
      admissionTime: _string(json, 'admissionTime'),
      fullName: _string(json, 'fullName'),
      age: _string(json, 'age'),
      gender: _string(json, 'gender'),
      suspectedInfection: _string(json, 'suspectedInfection'),
      admissionReason: _string(json, 'admissionReason'),
      infectionOrgan: _string(json, 'infectionOrgan'),
      ward: _string(json, 'ward'),
      diabetes: _bool(json, 'diabetes'),
      chronicKidneyDisease: _bool(json, 'chronicKidneyDisease'),
      liverFailure: _bool(json, 'liverFailure'),
      hypertension: _bool(json, 'hypertension'),
      copd: _bool(json, 'copd'),
      otherComorbidity: _string(json, 'otherComorbidity'),
      news2RespirationMeasured: _string(json, 'news2RespirationMeasured'),
      news2Respiration: _int(json, 'news2Respiration'),
      news2RespirationOption: _string(json, 'news2RespirationOption'),
      news2RespirationSelected: _bool(json, 'news2RespirationSelected'),
      news2Spo2Measured: _string(json, 'news2Spo2Measured'),
      news2Spo2Scale2: _bool(json, 'news2Spo2Scale2'),
      news2Spo2: _int(json, 'news2Spo2'),
      news2Spo2Option: _string(json, 'news2Spo2Option'),
      news2Spo2Selected: _bool(json, 'news2Spo2Selected'),
      news2OxygenMeasured: _string(json, 'news2OxygenMeasured'),
      news2Oxygen: _int(json, 'news2Oxygen'),
      news2OxygenOption: _string(json, 'news2OxygenOption'),
      news2OxygenSelected: _bool(json, 'news2OxygenSelected'),
      news2TemperatureMeasured: _string(json, 'news2TemperatureMeasured'),
      news2Temperature: _int(json, 'news2Temperature'),
      news2TemperatureOption: _string(json, 'news2TemperatureOption'),
      news2TemperatureSelected: _bool(json, 'news2TemperatureSelected'),
      news2SystolicBpMeasured: _string(json, 'news2SystolicBpMeasured'),
      news2SystolicBp: _int(json, 'news2SystolicBp'),
      news2SystolicBpOption: _string(json, 'news2SystolicBpOption'),
      news2SystolicBpSelected: _bool(json, 'news2SystolicBpSelected'),
      news2HeartRateMeasured: _string(json, 'news2HeartRateMeasured'),
      news2HeartRate: _int(json, 'news2HeartRate'),
      news2HeartRateOption: _string(json, 'news2HeartRateOption'),
      news2HeartRateSelected: _bool(json, 'news2HeartRateSelected'),
      news2ConsciousnessMeasured: _string(json, 'news2ConsciousnessMeasured'),
      news2Consciousness: _int(json, 'news2Consciousness'),
      news2ConsciousnessOption: _string(json, 'news2ConsciousnessOption'),
      news2ConsciousnessSelected: _bool(json, 'news2ConsciousnessSelected'),
      news2Total: _int(json, 'news2Total'),
      qsofaRespiration: _bool(json, 'qsofaRespiration'),
      qsofaRespirationSelected: _bool(json, 'qsofaRespirationSelected'),
      qsofaSystolicBp: _bool(json, 'qsofaSystolicBp'),
      qsofaSystolicBpSelected: _bool(json, 'qsofaSystolicBpSelected'),
      qsofaConsciousness: _bool(json, 'qsofaConsciousness'),
      qsofaConsciousnessSelected: _bool(json, 'qsofaConsciousnessSelected'),
      qsofaTotal: _int(json, 'qsofaTotal'),
      lactate: _string(json, 'lactate'),
      lactateSampleTime: _string(json, 'lactateSampleTime'),
      lactateLevel: _string(json, 'lactateLevel'),
      sofaRespirationMeasured: _string(json, 'sofaRespirationMeasured'),
      sofaRespiration: _int(json, 'sofaRespiration'),
      sofaRespirationSelected: _bool(json, 'sofaRespirationSelected'),
      sofaCoagulationMeasured: _string(json, 'sofaCoagulationMeasured'),
      sofaCoagulation: _int(json, 'sofaCoagulation'),
      sofaCoagulationSelected: _bool(json, 'sofaCoagulationSelected'),
      sofaLiverMeasured: _string(json, 'sofaLiverMeasured'),
      sofaLiverUnit: _unit(json, 'sofaLiverUnit'),
      sofaLiver: _int(json, 'sofaLiver'),
      sofaLiverSelected: _bool(json, 'sofaLiverSelected'),
      sofaCardiovascularMeasured: _string(json, 'sofaCardiovascularMeasured'),
      sofaCardiovascular: _int(json, 'sofaCardiovascular'),
      sofaCardiovascularSelected: _bool(json, 'sofaCardiovascularSelected'),
      sofaNeurologicMeasured: _string(json, 'sofaNeurologicMeasured'),
      sofaNeurologic: _int(json, 'sofaNeurologic'),
      sofaNeurologicSelected: _bool(json, 'sofaNeurologicSelected'),
      sofaRenalMeasured: _string(json, 'sofaRenalMeasured'),
      sofaRenalUnit: _unit(json, 'sofaRenalUnit'),
      sofaRenal: _int(json, 'sofaRenal'),
      sofaRenalSelected: _bool(json, 'sofaRenalSelected'),
      sofaTotal: _int(json, 'sofaTotal'),
      vasopressor: _bool(json, 'vasopressor'),
      sepsisDiagnosis: _string(json, 'sepsisDiagnosis'),
      treatmentOutcome: _string(json, 'treatmentOutcome'),
      treatmentDays: _string(json, 'treatmentDays'),
      createdAtMillis: _int(json, 'createdAtMillis'),
      modifiedAtMillis: _int(json, 'modifiedAtMillis'),
      savedAtMillis: _int(json, 'savedAtMillis'),
    );
  }

  ClinicalAssessment clone() => ClinicalAssessment.fromJson(toJson());

  Map<String, dynamic> toJson() {
    return {
      'assessmentMode': assessmentMode,
      'patientId': patientId,
      'admissionDateTime': admissionDateTime,
      'admissionDate': admissionDate,
      'admissionTime': admissionTime,
      'fullName': fullName,
      'age': age,
      'gender': gender,
      'suspectedInfection': suspectedInfection,
      'admissionReason': admissionReason,
      'infectionOrgan': infectionOrgan,
      'ward': ward,
      'diabetes': diabetes,
      'chronicKidneyDisease': chronicKidneyDisease,
      'liverFailure': liverFailure,
      'hypertension': hypertension,
      'copd': copd,
      'otherComorbidity': otherComorbidity,
      'news2RespirationMeasured': news2RespirationMeasured,
      'news2Respiration': news2Respiration,
      'news2RespirationOption': news2RespirationOption,
      'news2RespirationSelected': news2RespirationSelected,
      'news2Spo2Measured': news2Spo2Measured,
      'news2Spo2Scale2': news2Spo2Scale2,
      'news2Spo2': news2Spo2,
      'news2Spo2Option': news2Spo2Option,
      'news2Spo2Selected': news2Spo2Selected,
      'news2OxygenMeasured': news2OxygenMeasured,
      'news2Oxygen': news2Oxygen,
      'news2OxygenOption': news2OxygenOption,
      'news2OxygenSelected': news2OxygenSelected,
      'news2TemperatureMeasured': news2TemperatureMeasured,
      'news2Temperature': news2Temperature,
      'news2TemperatureOption': news2TemperatureOption,
      'news2TemperatureSelected': news2TemperatureSelected,
      'news2SystolicBpMeasured': news2SystolicBpMeasured,
      'news2SystolicBp': news2SystolicBp,
      'news2SystolicBpOption': news2SystolicBpOption,
      'news2SystolicBpSelected': news2SystolicBpSelected,
      'news2HeartRateMeasured': news2HeartRateMeasured,
      'news2HeartRate': news2HeartRate,
      'news2HeartRateOption': news2HeartRateOption,
      'news2HeartRateSelected': news2HeartRateSelected,
      'news2ConsciousnessMeasured': news2ConsciousnessMeasured,
      'news2Consciousness': news2Consciousness,
      'news2ConsciousnessOption': news2ConsciousnessOption,
      'news2ConsciousnessSelected': news2ConsciousnessSelected,
      'news2Total': news2Total,
      'qsofaRespiration': qsofaRespiration,
      'qsofaRespirationSelected': qsofaRespirationSelected,
      'qsofaSystolicBp': qsofaSystolicBp,
      'qsofaSystolicBpSelected': qsofaSystolicBpSelected,
      'qsofaConsciousness': qsofaConsciousness,
      'qsofaConsciousnessSelected': qsofaConsciousnessSelected,
      'qsofaTotal': qsofaTotal,
      'lactate': lactate,
      'lactateSampleTime': lactateSampleTime,
      'lactateLevel': lactateLevel,
      'sofaRespirationMeasured': sofaRespirationMeasured,
      'sofaRespiration': sofaRespiration,
      'sofaRespirationSelected': sofaRespirationSelected,
      'sofaCoagulationMeasured': sofaCoagulationMeasured,
      'sofaCoagulation': sofaCoagulation,
      'sofaCoagulationSelected': sofaCoagulationSelected,
      'sofaLiverMeasured': sofaLiverMeasured,
      'sofaLiverUnit': sofaLiverUnit,
      'sofaLiver': sofaLiver,
      'sofaLiverSelected': sofaLiverSelected,
      'sofaCardiovascularMeasured': sofaCardiovascularMeasured,
      'sofaCardiovascular': sofaCardiovascular,
      'sofaCardiovascularSelected': sofaCardiovascularSelected,
      'sofaNeurologicMeasured': sofaNeurologicMeasured,
      'sofaNeurologic': sofaNeurologic,
      'sofaNeurologicSelected': sofaNeurologicSelected,
      'sofaRenalMeasured': sofaRenalMeasured,
      'sofaRenalUnit': sofaRenalUnit,
      'sofaRenal': sofaRenal,
      'sofaRenalSelected': sofaRenalSelected,
      'sofaTotal': sofaTotal,
      'vasopressor': vasopressor,
      'sepsisDiagnosis': sepsisDiagnosis,
      'treatmentOutcome': treatmentOutcome,
      'treatmentDays': treatmentDays,
      'createdAtMillis': createdAtMillis,
      'modifiedAtMillis': modifiedAtMillis,
      'savedAtMillis': savedAtMillis,
    };
  }

  ClinicalAssessmentInputMode get inputMode =>
      parseAssessmentInputMode(assessmentMode);

  set inputMode(ClinicalAssessmentInputMode mode) {
    assessmentMode = assessmentModeValue(mode);
  }

  bool get isQuickMode => inputMode == ClinicalAssessmentInputMode.quick;

  bool get isDetailedMode => !isQuickMode;

  static ClinicalAssessmentInputMode parseAssessmentInputMode(String value) {
    return value.trim().toLowerCase() == assessmentModeQuick
        ? ClinicalAssessmentInputMode.quick
        : ClinicalAssessmentInputMode.detailed;
  }

  static String assessmentModeValue(ClinicalAssessmentInputMode mode) {
    return switch (mode) {
      ClinicalAssessmentInputMode.quick => assessmentModeQuick,
      ClinicalAssessmentInputMode.detailed => assessmentModeDetailed,
    };
  }

  static String normalizeAssessmentMode(String value) {
    return assessmentModeValue(parseAssessmentInputMode(value));
  }

  static String _string(Map<String, dynamic> json, String key) {
    final value = json[key];
    return value == null ? '' : value.toString();
  }

  static String _unit(Map<String, dynamic> json, String key) {
    final value = _string(json, key).trim();
    if (value == 'µmol/L' || value.toLowerCase() == 'umol/l') {
      return 'µmol/L';
    }
    return 'mg/dL';
  }

  static String _assessmentMode(Map<String, dynamic> json, String key) {
    return normalizeAssessmentMode(_string(json, key));
  }

  static int _int(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _bool(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is bool) {
      return value;
    }
    return value?.toString().toLowerCase() == 'true';
  }
}
