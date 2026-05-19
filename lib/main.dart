import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

import 'src/data/assessment_repository.dart';
import 'src/domain/clinical_assessment.dart';
import 'src/domain/clinical_value_parser.dart';
import 'src/domain/scoring.dart';
import 'src/export/crf_exporter.dart';
import 'src/services/update_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const News2LApp());
}

class News2LApp extends StatelessWidget {
  const News2LApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NEWS2-L',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00796B)),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          isDense: true,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repository = AssessmentRepository();
  final _exporter = const CrfExporter();
  final _updateService = const UpdateService();

  ClinicalAssessment _assessment = _newAssessment();
  List<SavedAssessment> _history = [];
  PatientSortMode _sortMode = PatientSortMode.newest;
  String _searchQuery = '';
  int _selectedTab = 0;
  int _formVersion = 0;
  bool _loading = true;
  bool _saving = false;
  bool _exporting = false;
  bool _downloadingUpdate = false;
  double _downloadProgress = 0;
  UpdateInfo? _availableUpdate;

  @override
  void initState() {
    super.initState();
    _load();
    _checkUpdate();
  }

  Future<void> _load() async {
    if (kIsWeb) {
      if (!mounted) {
        return;
      }
      setState(() {
        _assessment = _newAssessment();
        _history = [];
        _loading = false;
        _formVersion++;
      });
      return;
    }
    final draft = await _repository.loadCurrentAssessment();
    recalculateClinicalAssessment(draft);
    final history = await _repository.loadAssessmentHistory();
    if (!mounted) {
      return;
    }
    setState(() {
      _assessment = _hasAnyClinicalData(draft) ? draft : _newAssessment();
      _history = history;
      _loading = false;
      _formVersion++;
    });
  }

  Future<void> _refreshHistory() async {
    final history = await _repository.loadAssessmentHistory(
      query: _searchQuery,
      sortMode: _sortMode,
    );
    if (!mounted) {
      return;
    }
    setState(() => _history = history);
  }

  Future<void> _checkUpdate() async {
    if (kIsWeb) {
      return;
    }
    final update = await _updateService.checkForUpdate();
    if (!mounted || update == null) {
      return;
    }
    setState(() => _availableUpdate = update);
  }

  Future<void> _downloadUpdate() async {
    final update = _availableUpdate;
    if (update == null || _downloadingUpdate) {
      return;
    }
    setState(() {
      _downloadingUpdate = true;
      _downloadProgress = 0;
    });
    try {
      final apk = await _updateService.downloadApk(update, (progress) {
        if (mounted) {
          setState(() => _downloadProgress = progress);
        }
      });
      await _updateService.openAndroidInstaller(apk);
    } catch (_) {
      if (mounted) {
        _showMessage('Không tải hoặc mở được bản cập nhật.');
      }
    } finally {
      if (mounted) {
        setState(() => _downloadingUpdate = false);
      }
    }
  }

  void _mutate(void Function(ClinicalAssessment assessment) change) {
    setState(() {
      change(_assessment);
      _assessment.admissionDateTime = _buildAdmissionDateTime(_assessment);
      _assessment.modifiedAtMillis = DateTime.now().millisecondsSinceEpoch;
      recalculateClinicalAssessment(_assessment);
    });
    _repository.saveCurrentAssessment(_assessment);
  }

  Future<void> _savePatient() async {
    if (_saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      recalculateClinicalAssessment(_assessment);
      await _repository.saveCurrentAssessment(_assessment);
      await _repository.appendAssessmentHistory(_assessment.clone());
      await _refreshHistory();
      _showMessage('Đã lưu bệnh nhân.');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _exportAssessment(
    ClinicalAssessment source,
    CrfExportFormat format,
  ) async {
    if (_exporting) {
      return;
    }
    setState(() => _exporting = true);
    try {
      final assessment = source.clone();
      recalculateClinicalAssessment(assessment);
      final file = await _exporter.export(assessment, format);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: format.mimeType)],
        subject: 'NEWS2-L CRF',
        text: file.uri.pathSegments.last,
      );
    } catch (_) {
      if (mounted) {
        _showMessage('Không xuất được file. Vui lòng thử lại.');
      }
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  void _openSaved(SavedAssessment saved) {
    final assessment = saved.assessment.clone();
    recalculateClinicalAssessment(assessment);
    setState(() {
      _assessment = assessment;
      _selectedTab = 0;
      _formVersion++;
    });
    _repository.saveCurrentAssessment(assessment);
  }

  void _startNew() {
    final assessment = _newAssessment();
    setState(() {
      _assessment = assessment;
      _selectedTab = 0;
      _formVersion++;
    });
    _repository.saveCurrentAssessment(assessment);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NEWS2-L'),
        actions: [
          IconButton(
            tooltip: 'Phiếu mới',
            onPressed: _startNew,
            icon: const Icon(Icons.add),
          ),
          IconButton(
            tooltip: 'Lưu bệnh nhân',
            onPressed: _saving ? null : _savePatient,
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_availableUpdate != null) _buildUpdateBanner(),
                Expanded(
                  child: IndexedStack(
                    index: _selectedTab,
                    children: [
                      KeyedSubtree(
                        key: ValueKey(_formVersion),
                        child: _buildAssessmentForm(),
                      ),
                      _buildPatientList(),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) => setState(() => _selectedTab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Phiếu',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Bệnh nhân',
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateBanner() {
    final update = _availableUpdate!;
    return Material(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.system_update_alt),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Có bản cập nhật NEWS2-L ${update.version}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (_downloadingUpdate)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: LinearProgressIndicator(value: _downloadProgress),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _downloadingUpdate ? null : _downloadUpdate,
              icon: const Icon(Icons.download),
              label: Text(_downloadingUpdate ? 'Đang tải' : 'Tải'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentForm() {
    final assessment = _assessment;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _scoreSummary(assessment),
        _section(
          'Thông tin bệnh nhân',
          [
            _field('Mã bệnh nhân', assessment.patientId, (value) {
              assessment.patientId = value;
            }),
            _field('Ngày nhập viện', assessment.admissionDate, (value) {
              assessment.admissionDate = value;
            }, hint: 'yyyy-MM-dd'),
            _field('Giờ nhập viện', assessment.admissionTime, (value) {
              assessment.admissionTime = value;
            }, hint: 'HH:mm'),
            _field('Họ và tên', assessment.fullName, (value) {
              assessment.fullName = value;
            }),
            _field('Tuổi', assessment.age, (value) {
              assessment.age = value;
            }, keyboardType: TextInputType.number),
            _field('Lý do nhập viện', assessment.admissionReason, (value) {
              assessment.admissionReason = value;
            }, maxLines: 3),
            _field('Cơ quan nhiễm trùng', assessment.infectionOrgan, (value) {
              assessment.infectionOrgan = value;
            }),
          ],
        ),
        _section(
          '1. NEWS2 - sàng lọc sinh hiệu ban đầu',
          [
            _field('Nhịp thở (lần/phút)', assessment.news2RespirationMeasured,
                (value) {
              assessment.news2RespirationMeasured = value;
            }, keyboardType: TextInputType.number),
            SwitchListTile(
              value: assessment.news2Spo2Scale2,
              onChanged: (value) => _mutate((a) => a.news2Spo2Scale2 = value),
              title: const Text('Bệnh nhân có nguy cơ hô hấp tăng CO2'),
              contentPadding: EdgeInsets.zero,
            ),
            _field('SpO2 (%)', assessment.news2Spo2Measured, (value) {
              assessment.news2Spo2Measured = value;
            }, keyboardType: TextInputType.number),
            SwitchListTile(
              value: assessment.news2OxygenMeasured == 'Có',
              onChanged: (value) => _mutate((a) {
                a.news2OxygenMeasured = value ? 'Có' : 'Không';
              }),
              title: const Text('Đang thở oxy'),
              contentPadding: EdgeInsets.zero,
            ),
            _field('Nhiệt độ (°C)', assessment.news2TemperatureMeasured,
                (value) {
              assessment.news2TemperatureMeasured = value;
            },
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true)),
            _field(
                'Huyết áp tâm thu (mmHg)', assessment.news2SystolicBpMeasured,
                (value) {
              assessment.news2SystolicBpMeasured = value;
            }, keyboardType: TextInputType.number),
            _field('Nhịp tim (lần/phút)', assessment.news2HeartRateMeasured,
                (value) {
              assessment.news2HeartRateMeasured = value;
            }, keyboardType: TextInputType.number),
            DropdownButtonFormField<String>(
              initialValue: assessment.news2ConsciousnessMeasured.isEmpty
                  ? null
                  : assessment.news2ConsciousnessMeasured,
              decoration: const InputDecoration(labelText: 'Tri giác (AVPU)'),
              items: const [
                DropdownMenuItem(value: 'A', child: Text('A - Tỉnh táo')),
                DropdownMenuItem(value: 'C', child: Text('C - Lú lẫn mới')),
                DropdownMenuItem(
                    value: 'V', child: Text('V - Đáp ứng lời nói')),
                DropdownMenuItem(value: 'P', child: Text('P - Đáp ứng đau')),
                DropdownMenuItem(value: 'U', child: Text('U - Không đáp ứng')),
              ],
              onChanged: (value) => _mutate((a) {
                a.news2ConsciousnessMeasured = value ?? '';
              }),
            ),
            _miniScores([
              'Nhịp thở ${assessment.news2Respiration}',
              'SpO2 ${assessment.news2Spo2}',
              'Oxy ${assessment.news2Oxygen}',
              'Nhiệt ${assessment.news2Temperature}',
              'HA ${assessment.news2SystolicBp}',
              'Mạch ${assessment.news2HeartRate}',
              'Tri giác ${assessment.news2Consciousness}',
            ]),
          ],
        ),
        _section(
          '2. qSOFA và Lactate - xác nhận nguy cơ sepsis',
          [
            _readOnlyLine('qSOFA', '${assessment.qsofaTotal} / 3'),
            _qsofaChecklist(assessment),
            _field('Lactate tĩnh mạch (mmol/L)', assessment.lactate, (value) {
              assessment.lactate = value;
              assessment.lactateLevel = _lactateLevel(value);
            },
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true)),
            _field('Thời gian lấy mẫu', assessment.lactateSampleTime, (value) {
              assessment.lactateSampleTime = value;
            }, hint: 'HH:mm hoặc ghi chú'),
            _readOnlyLine(
                'Phân mức Lactate',
                assessment.lactateLevel.isEmpty
                    ? 'Chưa có'
                    : assessment.lactateLevel),
          ],
        ),
        _section(
          '3. SOFA - xác định rối loạn cơ quan trong 24 giờ',
          [
            _readOnlyLine('Ngưỡng Sepsis-3', sofaThresholdText(assessment)),
            _field('Hô hấp - PaO2/FiO2', assessment.sofaRespirationMeasured,
                (value) {
              assessment.sofaRespirationMeasured = value;
            }),
            _field('Đông máu - Tiểu cầu', assessment.sofaCoagulationMeasured,
                (value) {
              assessment.sofaCoagulationMeasured = value;
            }),
            _field('Gan - Bilirubin', assessment.sofaLiverMeasured, (value) {
              assessment.sofaLiverMeasured = value;
            }),
            _field('Tim mạch - MAP/Vận mạch',
                assessment.sofaCardiovascularMeasured, (value) {
              assessment.sofaCardiovascularMeasured = value;
            }),
            SwitchListTile(
              value: assessment.vasopressor,
              onChanged: (value) => _mutate((a) => a.vasopressor = value),
              title: const Text('Có dùng vận mạch'),
              contentPadding: EdgeInsets.zero,
            ),
            _field('Thần kinh - GCS', assessment.sofaNeurologicMeasured,
                (value) {
              assessment.sofaNeurologicMeasured = value;
            }, keyboardType: TextInputType.number),
            _field('Thận - Creatinin/nước tiểu', assessment.sofaRenalMeasured,
                (value) {
              assessment.sofaRenalMeasured = value;
            }),
            _miniScores([
              'Hô hấp ${assessment.sofaRespiration}',
              'Đông máu ${assessment.sofaCoagulation}',
              'Gan ${assessment.sofaLiver}',
              'Tim mạch ${assessment.sofaCardiovascular}',
              'Thần kinh ${assessment.sofaNeurologic}',
              'Thận ${assessment.sofaRenal}',
            ]),
          ],
        ),
        _section(
          'Kết cục',
          [
            _readOnlyLine('Chẩn đoán Sepsis-3', assessment.sepsisDiagnosis),
            DropdownButtonFormField<String>(
              initialValue: assessment.treatmentOutcome.isEmpty
                  ? null
                  : assessment.treatmentOutcome,
              decoration: const InputDecoration(labelText: 'Kết quả điều trị'),
              items: const [
                DropdownMenuItem(
                    value: 'Khỏi / Đỡ ra viện',
                    child: Text('Khỏi / Đỡ ra viện')),
                DropdownMenuItem(
                    value: 'Chuyển viện', child: Text('Chuyển viện')),
                DropdownMenuItem(
                    value: 'Nặng xin về / Tử vong',
                    child: Text('Nặng xin về / Tử vong')),
              ],
              onChanged: (value) =>
                  _mutate((a) => a.treatmentOutcome = value ?? ''),
            ),
            _field('Số ngày điều trị', assessment.treatmentDays, (value) {
              assessment.treatmentDays = value;
            }, keyboardType: TextInputType.number),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: _saving ? null : _savePatient,
              icon: const Icon(Icons.save),
              label: const Text('Lưu bệnh nhân'),
            ),
            OutlinedButton.icon(
              onPressed: _exporting
                  ? null
                  : () => _exportAssessment(_assessment, CrfExportFormat.pdf),
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Xuất PDF'),
            ),
            OutlinedButton.icon(
              onPressed: _exporting
                  ? null
                  : () => _exportAssessment(_assessment, CrfExportFormat.docx),
              icon: const Icon(Icons.description),
              label: const Text('Xuất DOCX'),
            ),
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildPatientList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Tìm theo mã BN hoặc họ tên',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    _searchQuery = value;
                    _refreshHistory();
                  },
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<PatientSortMode>(
                value: _sortMode,
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() => _sortMode = value);
                  _refreshHistory();
                },
                items: const [
                  DropdownMenuItem(
                      value: PatientSortMode.newest, child: Text('Mới nhất')),
                  DropdownMenuItem(
                      value: PatientSortMode.name, child: Text('Tên')),
                  DropdownMenuItem(
                      value: PatientSortMode.patientId, child: Text('Mã BN')),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _history.isEmpty
              ? const Center(child: Text('Chưa có bệnh nhân đã lưu.'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final saved = _history[index];
                    final assessment = saved.assessment;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        onTap: () => _openSaved(saved),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                assessment.fullName.isEmpty
                                    ? 'Chưa nhập họ tên'
                                    : assessment.fullName,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Mã BN: ${assessment.patientId.isEmpty ? '...' : assessment.patientId} · NEWS2 ${assessment.news2Total} · SOFA ${assessment.sofaTotal}',
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: [
                                  OutlinedButton(
                                    onPressed: () => _exportAssessment(
                                        assessment, CrfExportFormat.pdf),
                                    child: const Text('PDF'),
                                  ),
                                  OutlinedButton(
                                    onPressed: () => _exportAssessment(
                                        assessment, CrfExportFormat.docx),
                                    child: const Text('DOCX'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _scoreSummary(ClinicalAssessment assessment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
                child: _scoreTile('NEWS2', '${assessment.news2Total}',
                    News2Scoring.riskLabel(assessment))),
            Expanded(
                child: _scoreTile('qSOFA', '${assessment.qsofaTotal}', '/ 3')),
            Expanded(
                child: _scoreTile('SOFA', '${assessment.sofaTotal}',
                    sofaThresholdText(assessment))),
          ],
        ),
      ),
    );
  }

  Widget _scoreTile(String label, String value, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        Text(value, style: Theme.of(context).textTheme.headlineSmall),
        Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...children.map(
              (child) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    String value,
    void Function(String value) onChanged, {
    TextInputType? keyboardType,
    int maxLines = 1,
    String? hint,
  }) {
    return TextFormField(
      initialValue: value,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label, hintText: hint),
      onChanged: (newValue) => _mutate((_) => onChanged(newValue)),
    );
  }

  Widget _readOnlyLine(String label, String value) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: Text(value.isEmpty ? 'Chưa có' : value),
    );
  }

  Widget _qsofaChecklist(ClinicalAssessment assessment) {
    return Column(
      children: [
        _readonlyCheck(
          'Nhịp thở ≥ 22 lần/phút',
          assessment.qsofaRespiration,
          ClinicalValueParser.hasText(assessment.news2RespirationMeasured),
        ),
        _readonlyCheck(
          'Huyết áp tâm thu ≤ 100 mmHg',
          assessment.qsofaSystolicBp,
          ClinicalValueParser.hasText(assessment.news2SystolicBpMeasured),
        ),
        _readonlyCheck(
          'Rối loạn ý thức (GCS < 15 / AVPU khác A)',
          assessment.qsofaConsciousness,
          ClinicalValueParser.hasText(assessment.news2ConsciousnessMeasured),
        ),
      ],
    );
  }

  Widget _readonlyCheck(String label, bool checked, bool completed) {
    return CheckboxListTile(
      value: completed ? checked : false,
      onChanged: null,
      dense: true,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(label),
      subtitle:
          completed ? null : const Text('Chưa có dữ liệu NEWS2 tương ứng'),
    );
  }

  Widget _miniScores(List<String> scores) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: scores
          .map(
            (score) => Chip(
              label: Text(score),
              visualDensity: VisualDensity.compact,
            ),
          )
          .toList(),
    );
  }

  static ClinicalAssessment _newAssessment() {
    final now = DateTime.now();
    final assessment = ClinicalAssessment(
      admissionDate: _dateText(now),
      admissionTime: _timeText(now),
      admissionDateTime: '${_timeText(now)}, ngày ${_dateText(now)}',
      createdAtMillis: now.millisecondsSinceEpoch,
      modifiedAtMillis: now.millisecondsSinceEpoch,
    );
    recalculateClinicalAssessment(assessment);
    return assessment;
  }

  static bool _hasAnyClinicalData(ClinicalAssessment assessment) {
    return [
      assessment.patientId,
      assessment.fullName,
      assessment.age,
      assessment.admissionReason,
      assessment.infectionOrgan,
      assessment.news2RespirationMeasured,
      assessment.news2Spo2Measured,
      assessment.sofaRespirationMeasured,
    ].any(ClinicalValueParser.hasText);
  }

  static String _buildAdmissionDateTime(ClinicalAssessment assessment) {
    return '${assessment.admissionTime}, ngày ${assessment.admissionDate}';
  }

  static String _lactateLevel(String value) {
    final lactate = ClinicalValueParser.parseDouble(value);
    if (lactate == null) {
      return '';
    }
    if (lactate < 2) {
      return '< 2 mmol/L';
    }
    if (lactate < 4) {
      return '2 - 3.9 mmol/L';
    }
    return '≥ 4 mmol/L';
  }

  static String _dateText(DateTime value) {
    return '${value.year}-${_two(value.month)}-${_two(value.day)}';
  }

  static String _timeText(DateTime value) {
    return '${_two(value.hour)}:${_two(value.minute)}';
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}
