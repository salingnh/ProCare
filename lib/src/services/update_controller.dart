import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/assessment_repository.dart';
import 'update_service.dart';

/// Owns app-update state and orchestration, fully decoupled from any widget.
///
/// This is plain `ChangeNotifier` (no `BuildContext`), so it can be unit
/// tested by injecting fake [UpdateService]/[AssessmentRepository]. Checks and
/// the periodic timer are no-ops on web, where updates are not supported.
class UpdateController extends ChangeNotifier {
  UpdateController({
    required AssessmentRepository repository,
    UpdateService updateService = const UpdateService(),
    Duration periodicInterval = const Duration(hours: 6),
    Duration resumeCooldown = const Duration(minutes: 15),
  })  : _repository = repository,
        _updateService = updateService,
        _periodicInterval = periodicInterval,
        _resumeCooldown = resumeCooldown;

  final AssessmentRepository _repository;
  final UpdateService _updateService;
  final Duration _periodicInterval;
  final Duration _resumeCooldown;

  UpdateInfo? _availableUpdate;
  bool _includePrereleaseUpdates = false;
  bool _downloadingUpdate = false;
  double _downloadProgress = 0;
  bool _checkingUpdate = false;
  bool _pendingUpdateCheck = false;
  int _lastCheckAtMillis = 0;
  Timer? _timer;
  bool _disposed = false;

  UpdateInfo? get availableUpdate => _availableUpdate;
  bool get includePrereleaseUpdates => _includePrereleaseUpdates;
  bool get downloadingUpdate => _downloadingUpdate;
  double get downloadProgress => _downloadProgress;

  /// Loads persisted settings, runs an initial check and starts the periodic
  /// timer. Intended to be called once, after startup data is ready.
  Future<void> start() async {
    _includePrereleaseUpdates =
        await _repository.loadIncludePrereleaseUpdates();
    if (_disposed) {
      return;
    }
    _notify();
    unawaited(checkForUpdate());
    _startPeriodicCheck();
  }

  void _startPeriodicCheck() {
    if (kIsWeb) {
      return;
    }
    _timer?.cancel();
    _timer = Timer.periodic(_periodicInterval, (_) => checkForUpdate());
  }

  /// Re-checks when the app returns to foreground, honouring a cooldown so a
  /// quick background/foreground bounce does not spam the network.
  void checkAfterResume() {
    if (kIsWeb) {
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_lastCheckAtMillis == 0 ||
        now - _lastCheckAtMillis >= _resumeCooldown.inMilliseconds) {
      checkForUpdate();
    }
  }

  Future<void> checkForUpdate({bool force = false}) async {
    if (kIsWeb) {
      return;
    }
    if (_checkingUpdate) {
      if (force) {
        _pendingUpdateCheck = true;
      }
      return;
    }
    _checkingUpdate = true;
    _lastCheckAtMillis = DateTime.now().millisecondsSinceEpoch;
    try {
      final update = await _updateService.checkForUpdate(
        includePrerelease: _includePrereleaseUpdates,
      );
      if (_disposed || update == null) {
        return;
      }
      _availableUpdate = update;
      _notify();
    } finally {
      _checkingUpdate = false;
      if (_pendingUpdateCheck && !_disposed) {
        _pendingUpdateCheck = false;
        checkForUpdate(force: true);
      }
    }
  }

  Future<void> setIncludePrerelease(bool enabled) async {
    _includePrereleaseUpdates = enabled;
    _availableUpdate = null;
    _notify();
    await _repository.saveIncludePrereleaseUpdates(enabled);
    await checkForUpdate(force: true);
  }

  /// Downloads and launches the Android installer for the available update.
  /// Returns `false` only when an actual download/install attempt failed.
  Future<bool> downloadAndInstall() async {
    final update = _availableUpdate;
    if (update == null || _downloadingUpdate) {
      return false;
    }
    _downloadingUpdate = true;
    _downloadProgress = 0;
    _notify();
    try {
      final apk = await _updateService.downloadApk(update, (progress) {
        if (_disposed) {
          return;
        }
        _downloadProgress = progress;
        _notify();
      });
      await _updateService.openAndroidInstaller(apk);
      return true;
    } catch (_) {
      return false;
    } finally {
      if (!_disposed) {
        _downloadingUpdate = false;
        _notify();
      }
    }
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
