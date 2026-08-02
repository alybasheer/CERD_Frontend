import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fyp_source_code/network/api_service.dart';
import 'package:fyp_source_code/network/get_dio.dart';
import 'package:fyp_source_code/utilities/helpers/toast_helper.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_colors.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class UpdateInfo {
  final String latestVersion;
  final String apkUrl;
  final String releaseNotes;

  UpdateInfo({
    required this.latestVersion,
    required this.apkUrl,
    required this.releaseNotes,
  });
}

class AppUpdateService {
  static final AppUpdateService _instance = AppUpdateService._();
  factory AppUpdateService() => _instance;
  AppUpdateService._();

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

      if (_compareVersions(latest, currentVersion) <= 0) return null;

      return UpdateInfo(
        latestVersion: latest,
        apkUrl: data['apkUrl']?.toString() ?? '',
        releaseNotes: data['releaseNotes']?.toString() ?? '',
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

  Future<void> promptUpdate(UpdateInfo info) async {
    if (kIsWeb) return;
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Version ${info.latestVersion} is ready'),
              if (info.releaseNotes.isNotEmpty) ...[
                SizedBox(height: 12),
                Text('What\'s new:',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(height: 4),
                Text(info.releaseNotes),
              ],
            ],
          ),
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
    }
  }

  Future<void> _downloadAndInstall(String url) async {
    if (kIsWeb) return;
    if (url.isEmpty) {
      ToastHelper.showError('Download URL not available');
      return;
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

      if (filePath != null) {
        final file = File(filePath);
        if (await file.exists()) {
          await OpenFilex.open(filePath);
        }
      }
    } catch (e) {
      ToastHelper.showError('Download failed. Please try again later.');
    }
  }
}
