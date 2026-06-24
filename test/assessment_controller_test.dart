import 'package:flutter_test/flutter_test.dart';
import 'package:news2_l/src/data/assessment_repository.dart';
import 'package:news2_l/src/domain/clinical_assessment.dart';
import 'package:news2_l/src/ui/assessment_controller.dart';

class _FakeRepository extends AssessmentRepository {
  int nextId = 100;
  int saveHistoryCalls = 0;
  int? lastSavedId;
  ClinicalAssessment? lastDraft;

  @override
  Future<void> saveCurrentAssessment(ClinicalAssessment assessment) async {
    lastDraft = assessment;
  }

  @override
  Future<int> saveAssessmentHistory(
    ClinicalAssessment assessment, {
    int? id,
  }) async {
    saveHistoryCalls++;
    final assigned = id ?? nextId++;
    lastSavedId = assigned;
    return assigned;
  }
}

AssessmentController _controller(_FakeRepository repo, {String? mode}) {
  return AssessmentController(
    repository: repo,
    preferredAssessmentMode: mode ?? ClinicalAssessment.assessmentModeDetailed,
    autoSaveDelay: const Duration(hours: 1), // never auto-fires during tests
  );
}

void main() {
  test('mutate marks dirty, persists the draft and notifies', () async {
    final repo = _FakeRepository();
    final controller = _controller(repo);
    var notified = 0;
    controller.addListener(() => notified++);

    controller.mutate((a) => a.patientId = 'P1');

    expect(controller.assessment.patientId, 'P1');
    expect(controller.formDirty, isTrue);
    expect(controller.saveState, SaveState.dirty);
    expect(repo.lastDraft, isNotNull);
    expect(notified, greaterThan(0));
    controller.dispose();
  });

  test('save returns empty when there is nothing meaningful to save', () async {
    final controller = _controller(_FakeRepository());

    final outcome = await controller.save();

    expect(outcome, SaveOutcome.empty);
    expect(controller.saveState, SaveState.clean);
    controller.dispose();
  });

  test('save persists a new record, clears dirty and runs onPersisted',
      () async {
    final repo = _FakeRepository();
    var persisted = 0;
    final controller = _controller(repo)..onPersisted = () async => persisted++;
    controller.mutate((a) => a.patientId = 'P1');

    final outcome = await controller.save();

    expect(outcome, SaveOutcome.saved);
    expect(controller.openedSavedAssessmentId, isNotNull);
    expect(controller.saveState, SaveState.clean);
    expect(controller.formDirty, isFalse);
    expect(persisted, 1);
    controller.dispose();
  });

  test('save reports updated when editing an existing record', () async {
    final controller = _controller(_FakeRepository())
      ..setOpenedSavedAssessmentId(7);
    controller.mutate((a) => a.patientId = 'P1');

    final outcome = await controller.save();

    expect(outcome, SaveOutcome.updated);
    expect(controller.openedSavedAssessmentId, 7);
    controller.dispose();
  });

  test('openSaved adopts the record and applies the preferred mode', () async {
    final controller = _controller(
      _FakeRepository(),
      mode: ClinicalAssessment.assessmentModeQuick,
    );
    final saved = SavedAssessment(
      id: 3,
      assessment: ClinicalAssessment(
        patientId: 'P9',
        assessmentMode: ClinicalAssessment.assessmentModeDetailed,
      ),
    );

    final result = controller.openSaved(saved);

    expect(controller.openedSavedAssessmentId, 3);
    expect(controller.assessment.patientId, 'P9');
    expect(result.assessmentMode, ClinicalAssessment.assessmentModeQuick);
    controller.dispose();
  });

  test('startNew clears the opened record and resets save state', () async {
    final controller = _controller(_FakeRepository())
      ..setOpenedSavedAssessmentId(5);
    controller.mutate((a) => a.patientId = 'X');

    controller.startNew();

    expect(controller.openedSavedAssessmentId, isNull);
    expect(controller.formDirty, isFalse);
    expect(controller.saveState, SaveState.clean);
    controller.dispose();
  });

  test('autoSave does nothing when canAutoSave returns false', () async {
    final repo = _FakeRepository();
    final controller = _controller(repo)..canAutoSave = () => false;
    controller.mutate((a) => a.patientId = 'P1');

    await controller.autoSave();

    expect(repo.saveHistoryCalls, 0);
    controller.dispose();
  });

  test('restoreBaseline reverts unsaved edits to the last saved state',
      () async {
    final controller = _controller(_FakeRepository());
    controller.mutate((a) => a.patientId = 'P1');
    await controller.save();

    controller.mutate((a) => a.patientId = 'CHANGED');
    expect(controller.assessment.patientId, 'CHANGED');

    final restored = await controller.restoreBaseline();

    expect(restored, isNotNull);
    expect(controller.assessment.patientId, 'P1');
    expect(controller.formDirty, isFalse);
    expect(controller.saveState, SaveState.clean);
    controller.dispose();
  });
}
