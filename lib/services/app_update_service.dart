import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:device_info_plus/device_info_plus.dart';
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

  /// Per-CPU APK download links so we always install the APK that matches
  /// this device.
  final String arm64Url;
  final String v7Url;
  final String x86Url;
  final String releaseNotes;

  /// When true the update cannot be skipped (hard requirement).
  final bool required;

  const UpdateInfo({
    required this.latestVersion,
    required this.apkUrl,
    this.arm64Url = '',
    this.v7Url = '',
    this.x86Url = '',
    this.releaseNotes = '',
    this.required = false,
  });
}

class AppUpdateService {
  static final AppUpdateService _instance = AppUpdateService._();
  factory AppUpdateService() => _instance;
  AppUpdateService._();

  static const _dismissedAtKey = 'dismissed_update_at';

  /// How long a "Later" tap suppresses the prompt before it appears again.
  static const remindLaterDelay = Duration(hours: 12);

  final StorageHelper _storage = StorageHelper();

  bool _isChecking = false;
  List<String> _cachedAbis = const <String>[];

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

      // "Later" is only a short snooze: once remindLaterDelay passes we ask
      // again. Required updates are never suppressed by the snooze.
      if (!required) {
        final dismissedAt = _storage.readData(_dismissedAtKey);
        if (dismissedAt != null) {
          final at = DateTime.tryParse(dismissedAt.toString());
          if (at != null &&
              DateTime.now().isBefore(at.add(remindLaterDelay))) {
            final remaining = at
                .add(remindLaterDelay)
                .difference(DateTime.now())
                .inMinutes;
            debugPrint('📍 Update snoozed for v$latest, re-prompt in '
                '~$remaining min');
            return null;
          }
        }
      }

      return UpdateInfo(
        latestVersion: latest,
        apkUrl: data['apkUrl']?.toString() ?? '',
        arm64Url: data['arm64Url']?.toString() ?? '',
        v7Url: data['v7Url']?.toString() ?? '',
        x86Url: data['x86Url']?.toString() ?? '',
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

  Future<List<String>> _getAbis() async {
    if (_cachedAbis.isNotEmpty) return _cachedAbis;
    try {
      if (!kIsWeb && Platform.isAndroid) {
        final info = await DeviceInfoPlugin().androidInfo;
        _cachedAbis = List<String>.from(info.supportedAbis);
      }
    } catch (_) {}
    return _cachedAbis;
  }

  /// Resolves the URL that will actually install on this phone: arm64 APK on
  /// arm64 phones, v7 APK on 32-bit phones, x86 on emulators, and a
  /// universal package for anything unexpected.
  Future<String> resolveDownloadUrl(UpdateInfo info) async {
    if (info.apkUrl.isEmpty && info.arm64Url.isEmpty) return '';
    try {
      final abis = await _getAbis();
      if (abis.contains('arm64-v8a') && info.arm64Url.isNotEmpty) {
        return info.arm64Url;
      }
      if ((abis.contains('x86_64') || abis.contains('x86')) &&
          info.x86Url.isNotEmpty) {
        return info.x86Url;
      }
      if ((abis.contains('armeabi-v7a') || abis.contains('armeabi')) &&
          info.v7Url.isNotEmpty) {
        return info.v7Url;
      }
    } catch (_) {}
    return info.apkUrl;
  }

  /// Shows the update prompt.
  Future<bool> promptUpdate(UpdateInfo info, {bool required = false}) async {
    if (kIsWeb) return false;
    final url = await resolveDownloadUrl(info);
    if (url.isEmpty) {
      ToastHelper.showError('update.missing_link'.tr);
      return false;
    }
    final withUrl = UpdateInfo(
      latestVersion: info.latestVersion,
      apkUrl: url,
      releaseNotes: info.releaseNotes,
      required: info.required,
    );

    if (required) {
      await _showRequiredUpdate(withUrl);
    } else {
      final confirmed = await Get.dialog<bool>(
        PopScope(
          canPop: false,
          child: AlertDialog(
            icon: Icon(Icons.system_update, color: AppColors.steelBlue),
            title: Text('update.available'.tr),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: SingleChildScrollView(
                child: _UpdateContent(info: withUrl),
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: Text('common.later'.tr),
              ),
              ElevatedButton(
                onPressed: () => Get.back(result: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.steelBlue,
                  foregroundColor: Colors.white,
                ),
                child: Text('update.now'.tr),
              ),
            ],
          ),
        ),
      );

      if (confirmed == true) {
        await _downloadAndInstall(withUrl);
      } else {
        _storage.writeData(_dismissedAtKey, DateTime.now().toIso8601String());
        debugPrint('📍 Update v${info.latestVersion} snoozed '
            '(${remindLaterDelay.inHours}h)');
      }
    }
    return true;
  }

  /// Required flow: no permanent escape, but "Later" snoozes for 12h and
  /// re-prompts; progress is shown and download can be cancelled.
  Future<void> _showRequiredUpdate(UpdateInfo info) async {
    while (true) {
      final votesLater = await Get.dialog<bool>(
        PopScope(
          canPop: false,
          child: AlertDialog(
            icon: Icon(Icons.update, color: AppColors.emergencyRed),
            title: Text('update.required'.tr),
            content: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('update.required_message'.tr),
                    SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: true),
                child: Text('common.later'.tr),
              ),
              ElevatedButton(
                onPressed: () => Get.back(result: false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emergencyRed,
                  foregroundColor: Colors.white,
                ),
                child: Text('update.now'.tr),
              ),
            ],
          ),
        ),
      );

      if (votesLater == true) {
        // Temporary exit — the prompt will re-appear after 12h.
        _storage.writeData(_dismissedAtKey, DateTime.now().toIso8601String());
        return;
      }

      _storage.removeData(_dismissedAtKey);

      final ok = await _downloadAndInstall(info);
      if (ok) return;
      // Download failed/cancelled — loop back to the dialog so the user can
      // either retry or pick "Later".
    }
  }

  /// Downloads the APK with a real progress %. Returns `true` when the
  /// download completed and handed off to the installer.
  Future<bool> _downloadAndInstall(UpdateInfo info) async {
    final url = info.apkUrl;
    if (kIsWeb || url.isEmpty) return false;

    String? filePath;
    try {
      final dir = await getTemporaryDirectory();
      filePath = '${dir.path}/app-update.apk';

      final dio = getDio();
      var aborted = false;
      final progress = ValueNotifier<double>(-1);

      Get.dialog(
        PopScope(
          canPop: false,
          child: ValueListenableBuilder<double>(
            valueListenable: progress,
            builder: (context, value, _) {
              final pct = value < 0 ? 0.0 : value.clamp(0.0, 1.0);
              return AlertDialog(
                title: Text('update.downloading'.tr),
                content: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value < 0
                            ? 'update.connecting'.tr
                            : '${(value * 100).toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 10,
                          backgroundColor:
                              AppColors.steelBlue.withValues(alpha: 0.12),
                          valueColor:
                              AlwaysStoppedAnimation(AppColors.steelBlue),
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'update.downloading_hint'.tr,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                actions: [
                  TextButton(
                    onPressed: () {
                      aborted = true;
                      dio.cancel();
                    },
                    child: Text('common.cancel'.tr),
                  ),
                ],
              );
            },
          ),
        ),
        barrierDismissible: false,
      );

      try {
        await dio.download(
          url,
          filePath,
          onReceiveProgress: (received, total) {
            if (total > 0) progress.value = received / total;
          },
          options: Options(
            responseType: ResponseType.bytes,
            followRedirects: true,
          ),
        );
      } finally {
        if (Get.isDialogOpen ?? false) Get.back();
      }

      if (aborted) {
        // Cancelled → treat as "Later": snooze and re-prompt later.
        _storage.writeData(_dismissedAtKey, DateTime.now().toIso8601String());
        ToastHelper.showInfo('update.cancelled'.tr);
        return false;
      }

      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('📍 Update file does not exist after download');
        return false;
      }

      final size = await file.length();
      debugPrint('📍 Update APK downloaded: $size bytes');

      if (size < 1024 * 1024 * 5) {
        ToastHelper.showError(
            'update.incomplete'.tr);
        return false;
      }

      final result = await OpenFilex.open(
        filePath,
        type: 'application/vnd.android.package-archive',
      );

      if (result.type != ResultType.done) {
        debugPrint('📍 OpenFilex: ${result.type} - ${result.message}');
        ToastHelper.showError(
            result.message.trim().isEmpty
                ? 'update.installer_failed_plain'.tr
                : 'update.installer_failed'.trParams(
                    {'message': result.message.trim()}));
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('📍 Update download failed: $e');
      if (Get.isDialogOpen ?? false) Get.back();
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
        Text(info.latestVersion.trim().isEmpty
            ? 'update.available'.tr
            : 'update.version_ready'.trParams(
                {'version': info.latestVersion.trim()})),
        if (info.releaseNotes.isNotEmpty) ...[
          SizedBox(height: 12),
          Text(
            'update.whats_new'.tr,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 4),
          Text(info.releaseNotes),
        ],
      ],
    );
  }
}