import 'dart:async';

import 'package:fyp_source_code/network/api_service.dart';
import 'package:fyp_source_code/routing/route_names.dart';
import 'package:fyp_source_code/services/api_names.dart';
import 'package:fyp_source_code/utilities/helpers/toast_helper.dart';
import 'package:fyp_source_code/utilities/reuse_components/storage_helper.dart';
import 'package:get/get.dart';

class WaitingScreenController extends GetxController {
  final RxString verificationStatus = 'pending'.obs;
  final RxBool isApproved = false.obs;
  final RxBool isRejected = false.obs;
  final RxBool isChecking = true.obs;

  late Timer? _pollTimer;
  final _dioHelper = DioHelper();

  @override
  void onInit() {
    super.onInit();
    // Start polling for verification status updates
    _startPolling();
  }

  /// Start polling for verification status every 5 seconds
  void _startPolling() {
    _pollTimer = Timer.periodic(Duration(seconds: 5), (_) async {
      await _checkVerificationStatus();
    });
  }

  /// Check verification status from backend
  Future<void> _checkVerificationStatus() async {
    try {
      print('🔍 Fetching verification status from backend...');

      // Fetch status from backend API
      final response = await _dioHelper.get(
        url: ApiNames.getvolunteerStats,
        isauthorize: true,
      );

      print('📦 Backend Response: $response');
      print('📦 Response Type: ${response.runtimeType}');

      // Extract status from response
      String currentStatus = 'pending';
      if (response is Map) {
        final responseMap = Map<String, dynamic>.from(response);

        // Check for nested 'data' object with status
        if (responseMap.containsKey('data') && responseMap['data'] is Map) {
          final data = Map<String, dynamic>.from(responseMap['data']);
          if (data.containsKey('status')) {
            currentStatus = data['status'].toString().toLowerCase();
            print('✅ Found status in nested data: $currentStatus');
          }
        }
        // Check for direct status field
        else if (responseMap.containsKey('status')) {
          currentStatus = responseMap['status'].toString().toLowerCase();
          print('✅ Found direct status field: $currentStatus');
        }
        // Check for verificationStatus field
        else if (responseMap.containsKey('verificationStatus')) {
          currentStatus =
              responseMap['verificationStatus'].toString().toLowerCase();
          print('✅ Found verificationStatus field: $currentStatus');
        }
      }

      print('📊 Current Status from Backend: $currentStatus');
      verificationStatus.value = currentStatus;

      // Update storage with latest status from backend
      StorageHelper().saveData('verificationStatus', currentStatus);

      // Update observable based on status
      if (currentStatus == 'verified' ||
          currentStatus == 'approved' ||
          currentStatus == 'success') {
        isApproved.value = true;
        isRejected.value = false;
        _handleApproved();
      } else if (currentStatus == 'rejected' ||
          currentStatus == 'disapproved' ||
          currentStatus == 'failed') {
        isApproved.value = false;
        isRejected.value = true;
        _handleRejected();
      } else {
        isApproved.value = false;
        isRejected.value = false;
        print('⏳ Status still pending... ($currentStatus)');
      }

      isChecking.value = false;
    } catch (e) {
      print('❌ Error checking verification status: $e');
      isChecking.value = false;
      // On error, keep polling - don't stop
    }
  }

  /// Handle approved status
  void _handleApproved() {
    print('✅ Verification approved!');
    ToastHelper.showSuccess(
      'Your application has been approved. Please log in again to refresh your volunteer access.',
    );

    // Stop polling
    _stopPolling();

    // A new login refreshes the JWT role from user to volunteer.
    Future.delayed(Duration(milliseconds: 500), () {
      StorageHelper().clearSessionData();
      Get.offAllNamed(RouteNames.login);
    });
  }

  /// Handle rejected status
  void _handleRejected() {
    print('❌ Verification rejected!');
    ToastHelper.showError(
      'Your application was not approved. Please try again later or contact support.',
    );

    // Stop polling
    _stopPolling();

    // Keep the account as a normal requester account.
    Future.delayed(Duration(milliseconds: 500), () {
      StorageHelper().saveData('role', 'user');
      StorageHelper().saveData('verificationStatus', 'rejected');
      Get.offAllNamed(RouteNames.requestHome);
    });
  }

  /// Stop polling
  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    print('🛑 Polling stopped');
  }

  @override
  void onClose() {
    _stopPolling();
    super.onClose();
  }
}
