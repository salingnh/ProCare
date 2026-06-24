part of 'home_screen.dart';

extension _HsFormShell on _HomeScreenState {
  String _formAppBarTitle() {
    final fullName = _assessment.fullName.trim();
    if (fullName.isNotEmpty) {
      return fullName;
    }
    final patientId = _assessment.patientId.trim();
    if (patientId.isNotEmpty) {
      return patientId;
    }
    return _openedSavedAssessmentId == null ? 'Phiếu mới' : 'Chỉnh sửa phiếu';
  }

  List<Widget> _appBarActions(double width) {
    if (_homeMode == _HomeMode.list) {
      return [
        IconButton(
          tooltip: 'Cài đặt app',
          onPressed: _showUpdateSettings,
          icon: const Icon(Icons.settings_outlined),
        ),
        const SizedBox(width: 4),
      ];
    }
    if (width >= 520) {
      return [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Center(child: _saveStatusIndicator()),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: FilledButton.icon(
            onPressed: _saving ? null : _savePatient,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Lưu'),
          ),
        ),
        _formExportMenu(),
        IconButton(
          tooltip: 'Cài đặt app',
          onPressed: _showUpdateSettings,
          icon: const Icon(Icons.settings_outlined),
        ),
        const SizedBox(width: 4),
      ];
    }
    return [
      Center(child: _saveStatusIndicator(compact: true)),
      IconButton.filledTonal(
        tooltip: 'Lưu bệnh nhân',
        onPressed: _saving ? null : _savePatient,
        icon: const Icon(Icons.save_outlined),
      ),
      _formExportMenu(),
      IconButton(
        tooltip: 'Cài đặt app',
        onPressed: _showUpdateSettings,
        icon: const Icon(Icons.settings_outlined),
      ),
      const SizedBox(width: 4),
    ];
  }

  Widget _saveStatusIndicator({bool compact = false}) {
    final label = switch (_saveState) {
      SaveState.clean => _lastSavedAtMillis > 0
          ? 'Đã lưu ${_formatClock(_lastSavedAtMillis)}'
          : 'Đã lưu nháp',
      SaveState.dirty => 'Chưa lưu',
      SaveState.saving => 'Đang lưu...',
      SaveState.error => 'Lỗi lưu',
    };
    final status = switch (_saveState) {
      SaveState.clean => ClinicalStatus.normal,
      SaveState.dirty => ClinicalStatus.watch,
      SaveState.saving => ClinicalStatus.watch,
      SaveState.error => ClinicalStatus.danger,
    };
    return Padding(
      padding: EdgeInsets.only(right: compact ? 4 : 0),
      child: clinical_ui.SaveStatusIndicator(label: label, status: status),
    );
  }

  Widget _formExportMenu() {
    return ExportActionMenu(
      enabled: !_exporting,
      onSelected: (action) => _handleExportAction(_assessment, action),
    );
  }

  Widget _buildUpdateBanner() {
    final update = _updateController.availableUpdate!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: clinical_ui.ClinicalInfoBanner(
        icon: Icons.system_update_alt,
        title: 'Có bản cập nhật NEWS2-L ${update.version}'
            '${update.prerelease ? ' (thử nghiệm)' : ''}',
        message: 'Tải APK mới để cập nhật ứng dụng trên thiết bị này.',
        status: ClinicalStatus.watch,
        progress: _updateController.downloadingUpdate
            ? LinearProgressIndicator(
                value: _updateController.downloadProgress)
            : null,
        trailing: FilledButton.icon(
          onPressed:
              _updateController.downloadingUpdate ? null : _downloadUpdate,
          icon: const Icon(Icons.download),
          label: Text(
              _updateController.downloadingUpdate ? 'Đang tải' : 'Tải'),
        ),
      ),
    );
  }

  Widget _buildAssessmentForm() {
    final assessment = _assessment;
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 720;
        return ListView(
          controller: _formScrollController,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          children: [
            _section(
              'Thông tin bệnh nhân',
              sectionId: AssessmentSections.patient,
              progress: _patientProgress(assessment),
              twoColumns: twoColumns,
              children: [
                _field('Mã bệnh nhân', assessment.patientId, (value) {
                  assessment.patientId = value;
                }, fieldId: AssessmentFields.patientId),
                _field('Họ và tên', assessment.fullName, (value) {
                  assessment.fullName = value;
                }, fieldId: AssessmentFields.fullName),
                _field('Ngày nhập viện', assessment.admissionDate, (value) {
                  assessment.admissionDate = value;
                },
                    fieldId: AssessmentFields.admissionDate,
                    hint: 'yyyy-MM-dd',
                    keyboardType: TextInputType.datetime,
                    inputFormatters: _dateInputFormatters),
                _field('Giờ nhập viện', assessment.admissionTime, (value) {
                  assessment.admissionTime = value;
                },
                    fieldId: AssessmentFields.admissionTime,
                    hint: 'HH:mm',
                    keyboardType: TextInputType.datetime,
                    inputFormatters: _timeInputFormatters),
                _field('Tuổi', assessment.age, (value) {
                  assessment.age = value;
                },
                    unitOptions: const ['năm'],
                    hint: 'VD: 65',
                    keyboardType: TextInputType.number,
                    inputFormatters: _integerInputFormatters),
                _fullWidth(
                  _field('Lý do nhập viện', assessment.admissionReason,
                      (value) {
                    assessment.admissionReason = value;
                  }, maxLines: 3),
                ),
                _fullWidth(
                  _field('Cơ quan nhiễm trùng', assessment.infectionOrgan,
                      (value) {
                    assessment.infectionOrgan = value;
                  }),
                ),
              ],
            ),
            _section(
              '2. Sinh hiệu NEWS2',
              sectionId: AssessmentSections.news2,
              progress: AssessmentDisplay.news2Progress(assessment),
              twoColumns: twoColumns,
              children: [
                _field('Nhịp thở', assessment.news2RespirationMeasured,
                    (value) {
                  assessment.news2RespirationMeasured = value;
                },
                    fieldId: AssessmentFields.respiration,
                    unitOptions: const ['lần/phút'],
                    scoreText: _scoreText(
                      assessment.news2RespirationMeasured,
                      'Điểm NEWS2: ${assessment.news2Respiration}',
                    ),
                    scoreStatus: _scoreStatus(assessment.news2Respiration),
                    warningText: _rangeWarning(
                      assessment.news2RespirationMeasured,
                      min: 4,
                      max: 40,
                      label: 'Nhịp thở',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: _integerInputFormatters),
                _field('Huyết áp tâm thu', assessment.news2SystolicBpMeasured,
                    (value) {
                  assessment.news2SystolicBpMeasured = value;
                },
                    fieldId: AssessmentFields.systolicBp,
                    unitOptions: const ['mmHg'],
                    scoreText: _scoreText(
                      assessment.news2SystolicBpMeasured,
                      'Điểm NEWS2: ${assessment.news2SystolicBp}',
                    ),
                    scoreStatus: _scoreStatus(assessment.news2SystolicBp),
                    warningText: _rangeWarning(
                      assessment.news2SystolicBpMeasured,
                      min: 60,
                      max: 240,
                      label: 'Huyết áp tâm thu',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: _integerInputFormatters),
                DropdownButtonFormField<String>(
                  initialValue: assessment.news2ConsciousnessMeasured.isEmpty
                      ? null
                      : assessment.news2ConsciousnessMeasured,
                  isExpanded: true,
                  decoration:
                      const InputDecoration(labelText: 'Tri giác (AVPU)'),
                  items: const [
                    DropdownMenuItem(value: 'A', child: Text('A - Tỉnh táo')),
                    DropdownMenuItem(value: 'C', child: Text('C - Lú lẫn mới')),
                    DropdownMenuItem(
                        value: 'V', child: Text('V - Đáp ứng lời nói')),
                    DropdownMenuItem(
                        value: 'P', child: Text('P - Đáp ứng đau')),
                    DropdownMenuItem(
                        value: 'U', child: Text('U - Không đáp ứng')),
                  ],
                  onChanged: (value) => _mutate((a) {
                    a.news2ConsciousnessMeasured = value ?? '';
                  }),
                ),
                _fullWidth(
                  Column(
                    children: [
                      _qsofaChecklist(assessment),
                      const SizedBox(height: 8),
                      _readOnlyLine(
                        'Kết luận qSOFA',
                        _qsofaConclusionText(assessment),
                        tone: _qsofaTone(assessment),
                        maxLines: 5,
                      ),
                    ],
                  ),
                ),
                _field('SpO2', assessment.news2Spo2Measured, (value) {
                  assessment.news2Spo2Measured = value;
                },
                    fieldId: AssessmentFields.spo2,
                    unitOptions: const ['%'],
                    scoreText: _scoreText(
                      assessment.news2Spo2Measured,
                      'Điểm NEWS2: ${assessment.news2Spo2}',
                    ),
                    scoreStatus: _scoreStatus(assessment.news2Spo2),
                    warningText: _rangeWarning(
                      assessment.news2Spo2Measured,
                      min: 50,
                      max: 100,
                      label: 'SpO2',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: _integerInputFormatters),
                _toggleTile(
                  'Nguy cơ hô hấp tăng CO2',
                  assessment.news2Spo2Scale2,
                  (value) => _mutate((a) => a.news2Spo2Scale2 = value),
                ),
                _toggleTile(
                  'Đang thở oxy',
                  assessment.news2OxygenMeasured == 'Có',
                  (value) => _mutate((a) {
                    a.news2OxygenMeasured = value ? 'Có' : 'Không';
                  }),
                ),
                _field('Nhiệt độ', assessment.news2TemperatureMeasured,
                    (value) {
                  assessment.news2TemperatureMeasured = value;
                },
                    fieldId: AssessmentFields.temperature,
                    unitOptions: const ['°C'],
                    scoreText: _scoreText(
                      assessment.news2TemperatureMeasured,
                      'Điểm NEWS2: ${assessment.news2Temperature}',
                    ),
                    scoreStatus: _scoreStatus(assessment.news2Temperature),
                    warningText: _rangeWarning(
                      assessment.news2TemperatureMeasured,
                      min: 30,
                      max: 43,
                      label: 'Nhiệt độ',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: _decimalInputFormatters),
                _field('Nhịp tim', assessment.news2HeartRateMeasured, (value) {
                  assessment.news2HeartRateMeasured = value;
                },
                    fieldId: AssessmentFields.heartRate,
                    unitOptions: const ['lần/phút'],
                    scoreText: _scoreText(
                      assessment.news2HeartRateMeasured,
                      'Điểm NEWS2: ${assessment.news2HeartRate}',
                    ),
                    scoreStatus: _scoreStatus(assessment.news2HeartRate),
                    warningText: _rangeWarning(
                      assessment.news2HeartRateMeasured,
                      min: 30,
                      max: 220,
                      label: 'Nhịp tim',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: _integerInputFormatters),
                _fullWidth(
                  _miniScores([
                    _ScoreItem(
                      'Nhịp thở',
                      assessment.news2Respiration,
                      completed: ClinicalValueParser.hasText(
                        assessment.news2RespirationMeasured,
                      ),
                    ),
                    _ScoreItem(
                      'HA',
                      assessment.news2SystolicBp,
                      completed: ClinicalValueParser.hasText(
                        assessment.news2SystolicBpMeasured,
                      ),
                    ),
                    _ScoreItem(
                      'Tri giác',
                      assessment.news2Consciousness,
                      completed: ClinicalValueParser.hasText(
                        assessment.news2ConsciousnessMeasured,
                      ),
                    ),
                    _ScoreItem(
                      'SpO2',
                      assessment.news2Spo2,
                      completed: ClinicalValueParser.hasText(
                        assessment.news2Spo2Measured,
                      ),
                    ),
                    _ScoreItem(
                      'Oxy',
                      assessment.news2Oxygen,
                      completed: ClinicalValueParser.hasText(
                        assessment.news2OxygenMeasured,
                      ),
                    ),
                    _ScoreItem(
                      'Nhiệt',
                      assessment.news2Temperature,
                      completed: ClinicalValueParser.hasText(
                        assessment.news2TemperatureMeasured,
                      ),
                    ),
                    _ScoreItem(
                      'Mạch',
                      assessment.news2HeartRate,
                      completed: ClinicalValueParser.hasText(
                        assessment.news2HeartRateMeasured,
                      ),
                    ),
                  ]),
                ),
                _fullWidth(
                  _readOnlyLine(
                    'Kết luận NEWS2',
                    _news2ConclusionText(assessment),
                    tone: _news2Tone(assessment),
                    maxLines: 9,
                  ),
                ),
              ],
            ),
            _section(
              '3. Lactate & huyết động',
              sectionId: AssessmentSections.lactate,
              progress: AssessmentDisplay.lactateProgress(assessment),
              twoColumns: twoColumns,
              children: [
                _field('Lactate tĩnh mạch', assessment.lactate, (value) {
                  assessment.lactate = value;
                  assessment.lactateLevel = _lactateLevel(value);
                },
                    fieldId: AssessmentFields.lactate,
                    unitOptions: const ['mmol/L'],
                    warningText: _lactateWarning(assessment.lactate),
                    hint: 'VD: 2.1',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: _decimalInputFormatters),
                _field(
                    'Thời gian lấy mẫu lactate', assessment.lactateSampleTime,
                    (value) {
                  assessment.lactateSampleTime = value;
                },
                    fieldId: AssessmentFields.lactateSampleTime,
                    hint: 'HH:mm',
                    keyboardType: TextInputType.datetime,
                    inputFormatters: _timeInputFormatters),
                _readOnlyLine(
                  'Phân mức Lactate',
                  assessment.lactateLevel.isEmpty
                      ? 'Chưa nhập lactate'
                      : assessment.lactateLevel,
                  tone: ClinicalValueParser.hasText(assessment.lactate)
                      ? null
                      : _clinicalTones.muted,
                ),
                _field('Tim mạch - MAP/Vận mạch (mmHg; thuốc/liều)',
                    assessment.sofaCardiovascularMeasured, (value) {
                  assessment.sofaCardiovascularMeasured = value;
                },
                    fieldId: AssessmentFields.cardiovascular,
                    scoreText: _scoreText(
                      assessment.sofaCardiovascularMeasured,
                      'Điểm SOFA tim mạch: ${assessment.sofaCardiovascular}',
                    ),
                    scoreStatus: _scoreStatus(assessment.sofaCardiovascular),
                    hint: 'VD: MAP 65 hoặc norepi 0.2'),
                _toggleTile(
                  'Có dùng vận mạch',
                  assessment.vasopressor,
                  (value) => _mutate((a) => a.vasopressor = value),
                ),
              ],
            ),
            _section(
              '4. SOFA 24 giờ',
              sectionId: AssessmentSections.sofa,
              progress: AssessmentDisplay.sofaProgress(assessment),
              twoColumns: twoColumns,
              children: [
                _fullWidth(
                  _readOnlyLine(
                    'Ngưỡng Sepsis-3',
                    _sofaComplete(assessment)
                        ? sofaThresholdText(assessment)
                        : _missingSentence(
                            AssessmentDisplay.sofaProgress(assessment),
                          ),
                    tone: _sofaThresholdTone(assessment),
                  ),
                ),
                _fullWidth(
                  _readOnlyLine(
                    'Kết luận SOFA',
                    _sofaConclusionText(assessment),
                    tone: _sofaTone(assessment),
                    maxLines: 5,
                  ),
                ),
                _field('Hô hấp - PaO2/FiO2', assessment.sofaRespirationMeasured,
                    (value) {
                  assessment.sofaRespirationMeasured = value;
                },
                    fieldId: AssessmentFields.sofaRespiration,
                    unitOptions: const ['mmHg'],
                    scoreText: _scoreText(
                      assessment.sofaRespirationMeasured,
                      'Điểm SOFA hô hấp: ${assessment.sofaRespiration}',
                    ),
                    scoreStatus: _scoreStatus(assessment.sofaRespiration),
                    hint: 'VD: 180 hoặc 180 thở máy'),
                _field(
                    'Đông máu - Tiểu cầu', assessment.sofaCoagulationMeasured,
                    (value) {
                  assessment.sofaCoagulationMeasured = value;
                },
                    fieldId: AssessmentFields.sofaCoagulation,
                    unitOptions: const ['10³/µL'],
                    scoreText: _scoreText(
                      assessment.sofaCoagulationMeasured,
                      'Điểm SOFA đông máu: ${assessment.sofaCoagulation}',
                    ),
                    scoreStatus: _scoreStatus(assessment.sofaCoagulation),
                    hint: 'VD: 120',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: _decimalInputFormatters),
                _field(
                    'Gan - Bilirubin',
                    assessment.sofaLiverMeasured,
                    (value) {
                      assessment.sofaLiverMeasured = value;
                      final unit = _selectedUnit(
                        value,
                        const ['mg/dL', 'µmol/L'],
                      );
                      if (unit != null) {
                        assessment.sofaLiverUnit = unit;
                      }
                    },
                    fieldId: AssessmentFields.sofaLiver,
                    scoreText: _scoreText(
                      assessment.sofaLiverMeasured,
                      'Điểm SOFA gan: ${assessment.sofaLiver}',
                    ),
                    scoreStatus: _scoreStatus(assessment.sofaLiver),
                    helperText: 'Đơn vị được lưu cùng chỉ số',
                    hint: 'VD: 2.0 hoặc 34 µmol/L',
                    unitOptions: const ['mg/dL', 'µmol/L'],
                    selectedUnit: _selectedFieldUnit(
                      AssessmentFields.sofaLiver,
                      assessment.sofaLiverMeasured,
                      const ['mg/dL', 'µmol/L'],
                      savedUnit: assessment.sofaLiverUnit,
                    ),
                    onUnitChanged: (value) {
                      _fieldUnitSelections[AssessmentFields.sofaLiver] = value;
                      assessment.sofaLiverUnit = value;
                      if (_selectedUnit(
                            assessment.sofaLiverMeasured,
                            const ['mg/dL', 'µmol/L'],
                          ) !=
                          null) {
                        assessment.sofaLiverMeasured = _replaceTrailingUnit(
                          assessment.sofaLiverMeasured,
                          value,
                        );
                      }
                    }),
                _field('Thần kinh - GCS', assessment.sofaNeurologicMeasured,
                    (value) {
                  assessment.sofaNeurologicMeasured = value;
                },
                    fieldId: AssessmentFields.sofaNeurologic,
                    scoreText: _scoreText(
                      assessment.sofaNeurologicMeasured,
                      'Điểm SOFA thần kinh: ${assessment.sofaNeurologic}',
                    ),
                    scoreStatus: _scoreStatus(assessment.sofaNeurologic),
                    unitOptions: const ['điểm'],
                    warningText: _rangeWarning(
                      assessment.sofaNeurologicMeasured,
                      min: 3,
                      max: 15,
                      label: 'GCS',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: _integerInputFormatters),
                _field(
                    'Thận - Creatinin/nước tiểu',
                    assessment.sofaRenalMeasured,
                    (value) {
                      assessment.sofaRenalMeasured = value;
                      final unit = _selectedUnit(
                        value,
                        const ['mg/dL', 'µmol/L'],
                      );
                      if (unit != null) {
                        assessment.sofaRenalUnit = unit;
                      }
                    },
                    fieldId: AssessmentFields.sofaRenal,
                    scoreText: _scoreText(
                      assessment.sofaRenalMeasured,
                      'Điểm SOFA thận: ${assessment.sofaRenal}',
                    ),
                    scoreStatus: _scoreStatus(assessment.sofaRenal),
                    helperText: 'Đơn vị được lưu cùng chỉ số',
                    hint: 'VD: creatinin 2.0 mg/dL, nước tiểu 400 mL',
                    unitOptions: const ['mg/dL', 'µmol/L'],
                    selectedUnit: _selectedFieldUnit(
                      AssessmentFields.sofaRenal,
                      assessment.sofaRenalMeasured,
                      const ['mg/dL', 'µmol/L'],
                      savedUnit: assessment.sofaRenalUnit,
                    ),
                    onUnitChanged: (value) {
                      _fieldUnitSelections[AssessmentFields.sofaRenal] = value;
                      assessment.sofaRenalUnit = value;
                      if (_selectedUnit(
                            assessment.sofaRenalMeasured,
                            const ['mg/dL', 'µmol/L'],
                          ) !=
                          null) {
                        assessment.sofaRenalMeasured = _replaceTrailingUnit(
                          assessment.sofaRenalMeasured,
                          value,
                        );
                      }
                    }),
                _fullWidth(
                  _miniScores([
                    _ScoreItem(
                      'Hô hấp',
                      assessment.sofaRespiration,
                      completed: ClinicalValueParser.hasText(
                        assessment.sofaRespirationMeasured,
                      ),
                    ),
                    _ScoreItem(
                      'Đông máu',
                      assessment.sofaCoagulation,
                      completed: ClinicalValueParser.hasText(
                        assessment.sofaCoagulationMeasured,
                      ),
                    ),
                    _ScoreItem(
                      'Gan',
                      assessment.sofaLiver,
                      completed: ClinicalValueParser.hasText(
                        assessment.sofaLiverMeasured,
                      ),
                    ),
                    _ScoreItem(
                      'Tim mạch',
                      assessment.sofaCardiovascular,
                      completed: _sofaCardiovascularComplete(assessment),
                    ),
                    _ScoreItem(
                      'Thần kinh',
                      assessment.sofaNeurologic,
                      completed: ClinicalValueParser.hasText(
                        assessment.sofaNeurologicMeasured,
                      ),
                    ),
                    _ScoreItem(
                      'Thận',
                      assessment.sofaRenal,
                      completed: ClinicalValueParser.hasText(
                        assessment.sofaRenalMeasured,
                      ),
                    ),
                  ]),
                ),
              ],
            ),
            _diagnosisOutcomeCard(assessment, twoColumns: twoColumns),
          ],
        );
      },
    );
  }

  Widget _buildQuickAssessmentForm() {
    final assessment = _assessment;
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 720;
        return ListView(
          controller: _formScrollController,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          children: [
            _quickSectionCard(
              'Thông tin bệnh nhân',
              sectionId: AssessmentSections.patient,
              progress: _patientProgress(assessment),
              children: [
                _quickFieldGrid(
                  twoColumns: twoColumns,
                  children: [
                    _field('Mã bệnh nhân', assessment.patientId, (value) {
                      assessment.patientId = value;
                    }, fieldId: AssessmentFields.patientId),
                    _field('Họ và tên', assessment.fullName, (value) {
                      assessment.fullName = value;
                    }, fieldId: AssessmentFields.fullName),
                    _field('Ngày nhập viện', assessment.admissionDate, (value) {
                      assessment.admissionDate = value;
                    },
                        fieldId: AssessmentFields.admissionDate,
                        hint: 'yyyy-MM-dd',
                        keyboardType: TextInputType.datetime,
                        inputFormatters: _dateInputFormatters),
                    _field('Giờ nhập viện', assessment.admissionTime, (value) {
                      assessment.admissionTime = value;
                    },
                        fieldId: AssessmentFields.admissionTime,
                        hint: 'HH:mm',
                        keyboardType: TextInputType.datetime,
                        inputFormatters: _timeInputFormatters),
                    _field('Tuổi', assessment.age, (value) {
                      assessment.age = value;
                    },
                        unitOptions: const ['năm'],
                        hint: 'VD: 65',
                        keyboardType: TextInputType.number,
                        inputFormatters: _integerInputFormatters),
                    _field('Cơ quan nhiễm trùng', assessment.infectionOrgan,
                        (value) {
                      assessment.infectionOrgan = value;
                    }),
                    _fullWidth(
                      _field('Lý do nhập viện', assessment.admissionReason,
                          (value) {
                        assessment.admissionReason = value;
                      }, maxLines: 3),
                    ),
                  ],
                ),
              ],
            ),
            _quickNews2Section(assessment),
            _quickHemodynamicsSection(
              assessment,
              twoColumns: twoColumns,
            ),
            _quickSofaSection(assessment),
            _diagnosisOutcomeCard(assessment, twoColumns: twoColumns),
          ],
        );
      },
    );
  }
}
