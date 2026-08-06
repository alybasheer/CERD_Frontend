import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fyp_source_code/network/api_service.dart';
import 'package:fyp_source_code/network/get_dio.dart';
import 'package:fyp_source_code/utilities/helpers/toast_helper.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_colors.dart';
import 'package:fyp_source_code/utilities/reuse_components/storage_helper.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class UpdateInfo {
  final String latestVersion;
  final String apkUrl;
  final String releaseNotes;

  /// When true the update cannot be skipped (hard requirement).
  final bool required;

  UpdateInfo({
    required this.latestVersion,
    required this.apkUrl,
    required this.releaseNotes,
    this.required = false,
  });
}

class AppUpdateService {
  static final AppUpdateService _instance = AppUpdateService._();
  factory AppUpdateService() => _instance;
  AppUpdateService._();

  static const _dismissedKey = 'dismissed_update_version';

  final StorageHelper _storage = StorageHelper();

  bool _isChecking = false;

  Future<UpdateInfo?> checkForUpdate() async {
    if (kIsWeb) return null;
    if (_isChecking) return null;
    _isChecking = true;
    try {
      final info = await PackageInfo.fromPlatform();
      final currentVersion = info.version;

      final response = await DioHelper().get(url: 'app-version');
      if (response is! Map || response['success'] != true) return null;
      final data = response['data'];
      if (data is! Map) return null;

      final latest = data['latestVersion']?.toString() ?? '';
      if (latest.isEmpty) return null;

      final minRequired = data['minRequiredVersion']?.toString() ?? '';

      debugPrint('📍 Update check: installed=$currentVersion, latest=$latest');

      if (_compareVersions(latest, currentVersion) <= 0) return null;

      final required = _isUpdateRequired(
        currentVersion: currentVersion,
        minRequired: minRequired,
      );

      if (!required &&
          _storage.readData(_dismissedKey)?.toString() == latest) {
        debugPrint('📍 Update dismissed for v$latest, skipping');
        return null;
      }

      return UpdateInfo(
        latestVersion: latest,
        apkUrl: data['apkUrl']?.toString() ?? '',
        releaseNotes: data['releaseNotes']?.toString() ?? '',
        required: required,
      );
    } catch (_) {
      return null;
    } finally {
      _isChecking = false;
    }
  }

  int _compareVersions(String a, String b) {
    final partsA = a.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final partsB = b.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    for (int i = 0; i < partsA.length || i < partsB.length; i++) {
      final va = i < partsA.length ? partsA[i] : 0;
      final vb = i < partsB.length ? partsB[i] : 0;
      if (va != vb) return va - vb;
    }
    return 0;
  }

  bool _isUpdateRequired({required String currentVersion, required String minRequired}) {
    if (minRequired.isEmpty) return false;
    return _compareVersions(minRequired, currentVersion) > 0;
  }

  /// Shows the update dialog and returns whether the user made a choice
  /// (i.e. the prompt was actually presented). Returns `false` if nothing was
  /// shown and a retry should be allowed later.
  ///
  /// When [required] is true the dialog cannot be dismissed until the update
  /// is downloaded, so a user stuck on an old build is always brought current.
  Future<bool> promptUpdate(UpdateInfo info, {bool required = false}) async {
    if (kIsWeb) return false;
    if (required) {
      await _showRequiredUpdate(info);
    } else {
      final confirmed = await Get.dialog<bool>(
        PopScope(
          canPop: false,
          child: AlertDialog(
            title: Row(
              children: [
                Icon(Icons.system_update, color: AppColors.steelBlue),
                SizedBox(width: 8),
                Text('Update Available'),
              ],
            ),
            content: _UpdateContent(info: info),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: Text('Later'),
              ),
              ElevatedButton(
                onPressed: () => Get.back(result: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.steelBlue,
                  foregroundColor: Colors.white,
                ),
                child: Text('Update Now'),
              ),
            ],
          ),
        ),
      );

      if (confirmed == true) {
        await _downloadAndInstall(info.apkUrl);
      } else {
        _storage.writeData(_dismissedKey, info.latestVersion);
        debugPrint('📍 Update v${info.latestVersion} dismissed');
      }
    }
    return true;
  }

  /// Blocks until the required update is downloaded; no "Later" escape.
  Future<void> _showRequiredUpdate(UpdateInfo info) async {
    while (true) {
      final decision = await Get.dialog<_RequiredUpdateDecision>(
        PopScope(
          canPop: false,
          child: AlertDialog(
            icon: Icon(Icons.system_update_alt, color: AppColors.emergencyRed),
            title: const Text('Update required'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A newer version of the app is available. '
                  'Please update to continue.',
                ),
                SizedBox(height: 12),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: _RequiredUpdateDecision.retry),
                child: const Text('Retry'),
              ),
              ElevatedButton(
                onPressed: () =>
                    Get.back(result: _RequiredUpdateDecision.update),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emergencyRed,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Update Now'),
              ),
            ],
          ),
        ),
      );

      final votesUpdate =
          decision == null || decision == _RequiredUpdateDecision.update;
      if (votesUpdate) {
        final ok = await _downloadAndInstall(info.apkUrl);
        if (!ok) {
          ToastHelper.showError(
            'Update download failed. Please try again.',
          );
          continue; // Loop back so the user can retry.
        }
        return;
      }
    }
  }

  /// Downloads the APK
  /// Returns `true` when the download completed and the installer opened.
  Future<bool> _downloadAndInstall(String url) async {
    if (kIsWeb) return false;
    if (url.isEmpty) {
      ToastHelper.showError('Download URL not available');
      return false;
    }

    String? filePath;
    try {
      final dir = await getTemporaryDirectory();
      filePath = '${dir.path}/app-release.apk';

      final dio = getDio();
      await Get.showOverlay(
        asyncFunction: () async {
          await dio.download(
            url,
            filePath,
            options: Options(
              responseType: ResponseType.bytes,
              followRedirects: true,
            ),
          );
        },
        loadingWidget: Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.steelBlue),
                  SizedBox(height: 16),
                  Text('Downloading update...'),
                ],
              ),
            ),
          ),
        ),
      );

      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('📍 Update file does not exist after download');
        return false;
      }

      final size = await file.length();
      debugPrint('📍 Update APK downloaded: $size bytes');

      if (size < 1024 * 1024 * 5) {
        ToastHelper.showError(
            'Download looks incomplete. Please try again later.');
        return false;
      }

      final result = await OpenFilex.open(
        filePath,
        type: 'application/vnd.android.package-archive',
      );

      if (result.type != ResultType.done) {
        debugPrint('📍 OpenFilex: ${result.type} - ${result.message}');
        ToastHelper.showError(
            'Installer could not open (${result.message}). '
            'Please install the APK manually.');
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('📍 Update download failed: $e');
      ToastHelper.showError('Download failed. Please try again later.');
      return false;
    }
  }
}

/// Shared release-notes block used inside the update dialogs.
class _UpdateContent extends StatelessWidget {
  final UpdateInfo info;

  const _UpdateContent({required this.info});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Version ${info.latestVersion} is ready'),
        if (info.releaseNotes.isNotEmpty) ...[
          SizedBox(height: 12),
          Text('What\'s new:', style: TextStyle(fontWeight: FontWeight.w600)),
          SizedBox(height: 4),
          Text(info.releaseNotes),
        ],
      ],
    );
  }
}

enum _RequiredUpdateDecision { retry, update }
