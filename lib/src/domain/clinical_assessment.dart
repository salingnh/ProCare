class ClinicalAssessment {
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
  String news2Spo2Measured;
  bool news2Spo2Scale2;
  int news2Spo2;
  String news2Spo2Option;
  String news2OxygenMeasured;
  int news2Oxygen;
  String news2OxygenOption;
  String news2TemperatureMeasured;
  int news2Temperature;
  String news2TemperatureOption;
  String news2SystolicBpMeasured;
  int news2SystolicBp;
  String news2SystolicBpOption;
  String news2HeartRateMeasured;
  int news2HeartRate;
  String news2HeartRateOption;
  String news2ConsciousnessMeasured;
  int news2Consciousness;
  String news2ConsciousnessOption;
  int news2Total;

  bool qsofaRespiration;
  bool qsofaSystolicBp;
  bool qsofaConsciousness;
  int qsofaTotal;

  String lactate;
  String lactateSampleTime;
  String lactateLevel;

  String sofaRespirationMeasured;
  int sofaRespiration;
  String sofaCoagulationMeasured;
  int sofaCoagulation;
  String sofaLiverMeasured;
  int sofaLiver;
  String sofaCardiovascularMeasured;
  int sofaCardiovascular;
  String sofaNeurologicMeasured;
  int sofaNeurologic;
  String sofaRenalMeasured;
  int sofaRenal;
  int sofaTotal;
  bool vasopressor;

  String sepsisDiagnosis;
  String treatmentOutcome;
  String treatmentDays;
  int createdAtMillis;
  int modifiedAtMillis;
  int savedAtMillis;

  ClinicalAssessment({
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
    this.news2Spo2Measured = '',
    this.news2Spo2Scale2 = false,
    this.news2Spo2 = 0,
    this.news2Spo2Option = '',
    this.news2OxygenMeasured = '',
    this.news2Oxygen = 0,
    this.news2OxygenOption = '',
    this.news2TemperatureMeasured = '',
    this.news2Temperature = 0,
    this.news2TemperatureOption = '',
    this.news2SystolicBpMeasured = '',
    this.news2SystolicBp = 0,
    this.news2SystolicBpOption = '',
    this.news2HeartRateMeasured = '',
    this.news2HeartRate = 0,
    this.news2HeartRateOption = '',
    this.news2ConsciousnessMeasured = '',
    this.news2Consciousness = 0,
    this.news2ConsciousnessOption = '',
    this.news2Total = 0,
    this.qsofaRespiration = false,
    this.qsofaSystolicBp = false,
    this.qsofaConsciousness = false,
    this.qsofaTotal = 0,
    this.lactate = '',
    this.lactateSampleTime = '',
    this.lactateLevel = '',
    this.sofaRespirationMeasured = '',
    this.sofaRespiration = 0,
    this.sofaCoagulationMeasured = '',
    this.sofaCoagulation = 0,
    this.sofaLiverMeasured = '',
    this.sofaLiver = 0,
    this.sofaCardiovascularMeasured = '',
    this.sofaCardiovascular = 0,
    this.sofaNeurologicMeasured = '',
    this.sofaNeurologic = 0,
    this.sofaRenalMeasured = '',
    this.sofaRenal = 0,
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
      news2Spo2Measured: _string(json, 'news2Spo2Measured'),
      news2Spo2Scale2: _bool(json, 'news2Spo2Scale2'),
      news2Spo2: _int(json, 'news2Spo2'),
      news2Spo2Option: _string(json, 'news2Spo2Option'),
      news2OxygenMeasured: _string(json, 'news2OxygenMeasured'),
      news2Oxygen: _int(json, 'news2Oxygen'),
      news2OxygenOption: _string(json, 'news2OxygenOption'),
      news2TemperatureMeasured: _string(json, 'news2TemperatureMeasured'),
      news2Temperature: _int(json, 'news2Temperature'),
      news2TemperatureOption: _string(json, 'news2TemperatureOption'),
      news2SystolicBpMeasured: _string(json, 'news2SystolicBpMeasured'),
      news2SystolicBp: _int(json, 'news2SystolicBp'),
      news2SystolicBpOption: _string(json, 'news2SystolicBpOption'),
      news2HeartRateMeasured: _string(json, 'news2HeartRateMeasured'),
      news2HeartRate: _int(json, 'news2HeartRate'),
      news2HeartRateOption: _string(json, 'news2HeartRateOption'),
      news2ConsciousnessMeasured: _string(json, 'news2ConsciousnessMeasured'),
      news2Consciousness: _int(json, 'news2Consciousness'),
      news2ConsciousnessOption: _string(json, 'news2ConsciousnessOption'),
      news2Total: _int(json, 'news2Total'),
      qsofaRespiration: _bool(json, 'qsofaRespiration'),
      qsofaSystolicBp: _bool(json, 'qsofaSystolicBp'),
      qsofaConsciousness: _bool(json, 'qsofaConsciousness'),
      qsofaTotal: _int(json, 'qsofaTotal'),
      lactate: _string(json, 'lactate'),
      lactateSampleTime: _string(json, 'lactateSampleTime'),
      lactateLevel: _string(json, 'lactateLevel'),
      sofaRespirationMeasured: _string(json, 'sofaRespirationMeasured'),
      sofaRespiration: _int(json, 'sofaRespiration'),
      sofaCoagulationMeasured: _string(json, 'sofaCoagulationMeasured'),
      sofaCoagulation: _int(json, 'sofaCoagulation'),
      sofaLiverMeasured: _string(json, 'sofaLiverMeasured'),
      sofaLiver: _int(json, 'sofaLiver'),
      sofaCardiovascularMeasured: _string(json, 'sofaCardiovascularMeasured'),
      sofaCardiovascular: _int(json, 'sofaCardiovascular'),
      sofaNeurologicMeasured: _string(json, 'sofaNeurologicMeasured'),
      sofaNeurologic: _int(json, 'sofaNeurologic'),
      sofaRenalMeasured: _string(json, 'sofaRenalMeasured'),
      sofaRenal: _int(json, 'sofaRenal'),
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
      'news2Spo2Measured': news2Spo2Measured,
      'news2Spo2Scale2': news2Spo2Scale2,
      'news2Spo2': news2Spo2,
      'news2Spo2Option': news2Spo2Option,
      'news2OxygenMeasured': news2OxygenMeasured,
      'news2Oxygen': news2Oxygen,
      'news2OxygenOption': news2OxygenOption,
      'news2TemperatureMeasured': news2TemperatureMeasured,
      'news2Temperature': news2Temperature,
      'news2TemperatureOption': news2TemperatureOption,
      'news2SystolicBpMeasured': news2SystolicBpMeasured,
      'news2SystolicBp': news2SystolicBp,
      'news2SystolicBpOption': news2SystolicBpOption,
      'news2HeartRateMeasured': news2HeartRateMeasured,
      'news2HeartRate': news2HeartRate,
      'news2HeartRateOption': news2HeartRateOption,
      'news2ConsciousnessMeasured': news2ConsciousnessMeasured,
      'news2Consciousness': news2Consciousness,
      'news2ConsciousnessOption': news2ConsciousnessOption,
      'news2Total': news2Total,
      'qsofaRespiration': qsofaRespiration,
      'qsofaSystolicBp': qsofaSystolicBp,
      'qsofaConsciousness': qsofaConsciousness,
      'qsofaTotal': qsofaTotal,
      'lactate': lactate,
      'lactateSampleTime': lactateSampleTime,
      'lactateLevel': lactateLevel,
      'sofaRespirationMeasured': sofaRespirationMeasured,
      'sofaRespiration': sofaRespiration,
      'sofaCoagulationMeasured': sofaCoagulationMeasured,
      'sofaCoagulation': sofaCoagulation,
      'sofaLiverMeasured': sofaLiverMeasured,
      'sofaLiver': sofaLiver,
      'sofaCardiovascularMeasured': sofaCardiovascularMeasured,
      'sofaCardiovascular': sofaCardiovascular,
      'sofaNeurologicMeasured': sofaNeurologicMeasured,
      'sofaNeurologic': sofaNeurologic,
      'sofaRenalMeasured': sofaRenalMeasured,
      'sofaRenal': sofaRenal,
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

  static String _string(Map<String, dynamic> json, String key) {
    final value = json[key];
    return value == null ? '' : value.toString();
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
