import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class UpdateInfo {
  final String version;
  final String downloadUrl;
  final String releaseUrl;
  final bool prerelease;

  const UpdateInfo({
    required this.version,
    required this.downloadUrl,
    required this.releaseUrl,
    required this.prerelease,
  });
}

class UpdateService {
  static const _channel = MethodChannel('news2_l/android_update');
  static const _releaseApis = [
    'https://api.github.com/repos/salingnh/ProCare/releases',
  ];

  const UpdateService();

  Future<UpdateInfo?> checkForUpdate({bool includePrerelease = false}) async {
    final packageInfo = await PackageInfo.fromPlatform();
    UpdateInfo? newest;
    for (final api in _releaseApis) {
      final updates = await _fetchReleases(
        api,
        includePrerelease: includePrerelease,
      );
      for (final update in updates) {
        if (newest == null || _isNewerVersion(update.version, newest.version)) {
          newest = update;
        }
      }
    }
    if (newest == null) {
      return null;
    }
    return _isNewerVersion(newest.version, packageInfo.version) ? newest : null;
  }

  Future<File> downloadApk(
      UpdateInfo update, void Function(double) onProgress) async {
    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(update.downloadUrl));
      final response = await client.send(request);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const HttpException('Không tải được APK cập nhật.');
      }
      final directory = await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
      final file = File(
        p.join(directory.path, 'NEWS2-L-v${update.version}-signed.apk'),
      );
      final sink = file.openWrite();
      var received = 0;
      final total = response.contentLength ?? 0;
      await for (final chunk in response.stream) {
        received += chunk.length;
        sink.add(chunk);
        if (total > 0) {
          onProgress(received / total);
        }
      }
      await sink.close();
      return file;
    } finally {
      client.close();
    }
  }

  Future<void> openAndroidInstaller(File apkFile) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('Self-update is only supported on Android.');
    }
    await _channel
        .invokeMethod<void>('openApkInstaller', {'path': apkFile.path});
  }

  Future<List<UpdateInfo>> _fetchReleases(
    String apiUrl, {
    required bool includePrerelease,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl?per_page=30'),
        headers: const {
          'Accept': 'application/vnd.github+json',
          'User-Agent': 'NEWS2-L-Flutter',
        },
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const [];
      }
      final releases = jsonDecode(response.body);
      if (releases is! List) {
        return const [];
      }
      final updates = <UpdateInfo>[];
      for (final release in releases) {
        if (release is! Map<String, dynamic>) {
          continue;
        }
        final draft = release['draft'] == true;
        final prerelease = release['prerelease'] == true;
        if (draft || (prerelease && !includePrerelease)) {
          continue;
        }
        final update = _parseRelease(release, prerelease: prerelease);
        if (update != null) {
          updates.add(update);
        }
      }
      return updates;
    } catch (_) {
      return const [];
    }
  }

  UpdateInfo? _parseRelease(
    Map<String, dynamic> json, {
    required bool prerelease,
  }) {
    final version = _extractVersion(
      (json['tag_name'] ?? json['name'] ?? '').toString(),
    );
    if (version.isEmpty) {
      return null;
    }
    final releaseUrl = (json['html_url'] ?? '').toString();
    final downloadUrl = _findApkAssetUrl(json['assets']);
    if (downloadUrl == null) {
      return null;
    }
    return UpdateInfo(
      version: version,
      downloadUrl: downloadUrl,
      releaseUrl: releaseUrl,
      prerelease: prerelease,
    );
  }

  String? _findApkAssetUrl(Object? assets) {
    if (assets is! List || assets.isEmpty) {
      return null;
    }
    for (final asset in assets) {
      if (asset is! Map<String, dynamic>) {
        continue;
      }
      final name = (asset['name'] ?? '').toString().toLowerCase();
      final contentType =
          (asset['content_type'] ?? '').toString().toLowerCase();
      if (name.endsWith('.apk') ||
          contentType == 'application/vnd.android.package-archive') {
        final downloadUrl = (asset['browser_download_url'] ?? '').toString();
        return downloadUrl.isEmpty ? null : downloadUrl;
      }
    }
    return null;
  }

  bool _isNewerVersion(String remoteVersion, String currentVersion) {
    final remoteParts = _extractVersion(remoteVersion).split(RegExp(r'[.-]'));
    final currentParts = _extractVersion(currentVersion).split(RegExp(r'[.-]'));
    final length = remoteParts.length > currentParts.length
        ? remoteParts.length
        : currentParts.length;
    for (var i = 0; i < length; i++) {
      final remoteValue = _versionPart(remoteParts, i);
      final currentValue = _versionPart(currentParts, i);
      if (remoteValue > currentValue) {
        return true;
      }
      if (remoteValue < currentValue) {
        return false;
      }
    }
    return false;
  }

  int _versionPart(List<String> parts, int index) {
    if (index >= parts.length) {
      return 0;
    }
    final match = RegExp(r'\d+').firstMatch(parts[index]);
    return int.tryParse(match?.group(0) ?? '') ?? 0;
  }

  String _extractVersion(String version) {
    final normalized = version.trim().replaceFirst(RegExp(r'^[vV]'), '');
    final match = RegExp(r'(\d+(?:[.-]\d+)+)').firstMatch(normalized);
    return match?.group(1) ?? normalized;
  }
}
