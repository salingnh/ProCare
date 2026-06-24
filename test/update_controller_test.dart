import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:news2_l/src/data/assessment_repository.dart';
import 'package:news2_l/src/services/update_controller.dart';
import 'package:news2_l/src/services/update_service.dart';

class _FakeRepository extends AssessmentRepository {
  bool includePrerelease = false;

  @override
  Future<bool> loadIncludePrereleaseUpdates() async => includePrerelease;

  @override
  Future<void> saveIncludePrereleaseUpdates(bool enabled) async {
    includePrerelease = enabled;
  }
}

class _FakeUpdateService implements UpdateService {
  _FakeUpdateService({this.update, this.installSucceeds = true});

  UpdateInfo? update;
  bool installSucceeds;
  int checkCalls = 0;
  bool installed = false;

  @override
  Future<UpdateInfo?> checkForUpdate({bool includePrerelease = false}) async {
    checkCalls++;
    return update;
  }

  @override
  Future<File> downloadApk(
    UpdateInfo update,
    void Function(double) onProgress,
  ) async {
    onProgress(0.5);
    onProgress(1.0);
    if (!installSucceeds) {
      throw const SocketException('download failed');
    }
    return File('dummy.apk');
  }

  @override
  Future<void> openAndroidInstaller(File apkFile) async {
    installed = true;
  }
}

const _sampleUpdate = UpdateInfo(
  version: '9.9.9',
  downloadUrl: 'https://example.com/app.apk',
  releaseUrl: 'https://example.com/release',
  prerelease: false,
);

void main() {
  test('checkForUpdate exposes an available update and notifies listeners',
      () async {
    final service = _FakeUpdateService(update: _sampleUpdate);
    final controller = UpdateController(
      repository: _FakeRepository(),
      updateService: service,
    );
    var notified = 0;
    controller.addListener(() => notified++);

    expect(controller.availableUpdate, isNull);
    await controller.checkForUpdate();

    expect(controller.availableUpdate, same(_sampleUpdate));
    expect(notified, greaterThan(0));
    controller.dispose();
  });

  test('setIncludePrerelease persists the flag and re-checks', () async {
    final repository = _FakeRepository();
    final service = _FakeUpdateService(update: _sampleUpdate);
    final controller = UpdateController(
      repository: repository,
      updateService: service,
    );

    await controller.setIncludePrerelease(true);

    expect(controller.includePrereleaseUpdates, isTrue);
    expect(repository.includePrerelease, isTrue);
    expect(service.checkCalls, 1);
    controller.dispose();
  });

  test('downloadAndInstall reports progress and succeeds', () async {
    final service = _FakeUpdateService(update: _sampleUpdate);
    final controller = UpdateController(
      repository: _FakeRepository(),
      updateService: service,
    );
    await controller.checkForUpdate();

    final ok = await controller.downloadAndInstall();

    expect(ok, isTrue);
    expect(service.installed, isTrue);
    expect(controller.downloadProgress, 1.0);
    expect(controller.downloadingUpdate, isFalse);
    controller.dispose();
  });

  test('downloadAndInstall returns false when the install fails', () async {
    final service = _FakeUpdateService(
      update: _sampleUpdate,
      installSucceeds: false,
    );
    final controller = UpdateController(
      repository: _FakeRepository(),
      updateService: service,
    );
    await controller.checkForUpdate();

    final ok = await controller.downloadAndInstall();

    expect(ok, isFalse);
    expect(controller.downloadingUpdate, isFalse);
    controller.dispose();
  });
}
