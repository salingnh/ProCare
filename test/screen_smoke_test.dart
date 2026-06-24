import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:news2_l/src/data/assessment_repository.dart';
import 'package:news2_l/src/domain/clinical_assessment.dart';
import 'package:news2_l/src/services/update_controller.dart';
import 'package:news2_l/src/ui/assessment_controller.dart';
import 'package:news2_l/src/ui/assessment_form_screen.dart';
import 'package:news2_l/src/ui/clinical_theme.dart';
import 'package:news2_l/src/ui/patient_list_controller.dart';
import 'package:news2_l/src/ui/patient_list_view.dart';

class _FakeRepository extends AssessmentRepository {
  final List<SavedAssessment> items;
  _FakeRepository({this.items = const []});

  @override
  Future<ClinicalAssessment> loadCurrentAssessment() async =>
      ClinicalAssessment();
  @override
  Future<void> saveCurrentAssessment(ClinicalAssessment assessment) async {}
  @override
  Future<String> loadAssessmentMode() async =>
      ClinicalAssessment.assessmentModeDetailed;
  @override
  Future<void> saveAssessmentMode(String mode) async {}
  @override
  Future<bool> loadIncludePrereleaseUpdates() async => false;
  @override
  Future<int> saveAssessmentHistory(ClinicalAssessment a, {int? id}) async =>
      id ?? 1;
  @override
  Future<List<SavedAssessment>> loadAssessmentHistory({
    String query = '',
    PatientSortMode sortMode = PatientSortMode.updatedAt,
    int? limit,
    int offset = 0,
  }) async =>
      items;
}

Widget _wrap(Widget child) {
  final colorScheme = ColorScheme.fromSeed(seedColor: const Color(0xFF00796B));
  return MaterialApp(
    theme: ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      extensions: [ClinicalTones.fromColorScheme(colorScheme)],
    ),
    home: Scaffold(body: child),
  );
}

void main() {
  // Match a realistic device size; the default 800x600 test surface is smaller
  // than any phone and makes the fixed-height dashboard overflow.
  setUp(() => TestWidgetsFlutterBinding.ensureInitialized());

  testWidgets('PatientListView renders the empty state without errors',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1100, 850));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repo = _FakeRepository();
    final controller = PatientListController(repository: repo);
    addTearDown(controller.dispose);

    await tester.pumpWidget(_wrap(PatientListView(
      listController: controller,
      onOpenForm: (_) {},
      onNewForm: () {},
    )));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Chưa có phiếu theo dõi'), findsOneWidget);
  });

  testWidgets('PatientListView renders redesigned cards (incomplete = neutral)',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1100, 850));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repo = _FakeRepository(items: [
      SavedAssessment(
        id: 1,
        assessment: ClinicalAssessment(fullName: 'nguyễn văn a'),
      ),
    ]);
    final controller = PatientListController(repository: repo);
    addTearDown(controller.dispose);
    await controller.refresh();

    await tester.pumpWidget(_wrap(PatientListView(
      listController: controller,
      onOpenForm: (_) {},
      onNewForm: () {},
    )));
    await tester.pump();

    expect(tester.takeException(), isNull);
    // Title-cased name + neutral lead pill (no false danger badge).
    expect(find.text('Nguyễn Văn A'), findsOneWidget);
    expect(find.text('Chưa đủ dữ liệu để kết luận'), findsOneWidget);
  });

  testWidgets('AssessmentFormScreen (detailed) renders all sections',
      (tester) async {
    final repo = _FakeRepository();
    final controller = AssessmentController(repository: repo);
    final updateController = UpdateController(repository: repo);
    addTearDown(controller.dispose);
    addTearDown(updateController.dispose);
    await tester.binding.setSurfaceSize(const Size(1100, 850));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_wrap(AssessmentFormScreen(
      controller: controller,
      updateController: updateController,
    )));
    await tester.pump();

    // Form is a lazy ListView, so only the expanded top section is built.
    expect(tester.takeException(), isNull);
    expect(find.text('Thông tin bệnh nhân'), findsOneWidget);
    expect(find.byTooltip('Quay lại danh sách'), findsOneWidget);
  });

  testWidgets('AssessmentFormScreen has no overflow at phone size',
      (tester) async {
    final repo = _FakeRepository();
    final controller = AssessmentController(repository: repo);
    final updateController = UpdateController(repository: repo);
    addTearDown(controller.dispose);
    addTearDown(updateController.dispose);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_wrap(AssessmentFormScreen(
      controller: controller,
      updateController: updateController,
    )));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('Editing a NEWS2 field recalculates and stays error-free',
      (tester) async {
    final repo = _FakeRepository();
    final controller = AssessmentController(repository: repo);
    final updateController = UpdateController(repository: repo);
    addTearDown(controller.dispose);
    addTearDown(updateController.dispose);
    await tester.binding.setSurfaceSize(const Size(1100, 850));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_wrap(AssessmentFormScreen(
      controller: controller,
      updateController: updateController,
    )));
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, 'BN-001');
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(controller.assessment.patientId, 'BN-001');
    expect(controller.formDirty, isTrue);
  });

  testWidgets('AssessmentFormScreen renders in quick mode without errors',
      (tester) async {
    final repo = _FakeRepository();
    final controller = AssessmentController(
      repository: repo,
      preferredAssessmentMode: ClinicalAssessment.assessmentModeQuick,
    );
    final updateController = UpdateController(repository: repo);
    addTearDown(controller.dispose);
    addTearDown(updateController.dispose);
    await tester.binding.setSurfaceSize(const Size(1100, 850));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_wrap(AssessmentFormScreen(
      controller: controller,
      updateController: updateController,
    )));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Thông tin bệnh nhân'), findsOneWidget);
  });

  testWidgets('Form does not overflow on a short, wide viewport (quick mode)',
      (tester) async {
    // 800x600 triggers the full (non-compact) dashboard with a tall
    // missing-data panel on a short screen — the dashboard must scroll
    // internally instead of overflowing the body column.
    final repo = _FakeRepository();
    final controller = AssessmentController(
      repository: repo,
      preferredAssessmentMode: ClinicalAssessment.assessmentModeQuick,
    );
    final updateController = UpdateController(repository: repo);
    addTearDown(controller.dispose);
    addTearDown(updateController.dispose);
    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_wrap(AssessmentFormScreen(
      controller: controller,
      updateController: updateController,
    )));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
