import 'package:fyp_source_code/network/api_service.dart';
import 'package:fyp_source_code/routing/route_names.dart';
import 'package:fyp_source_code/services/api_names.dart';
import 'package:fyp_source_code/services/app_update_service.dart';
import 'package:fyp_source_code/utilities/reuse_components/storage_helper.dart';
import 'package:get/get.dart';

enum UserStatus { authenticated, pending, verified, notAuthenticated }

class SplashController extends GetxController {
  final RxBool isLoading = true.obs;
  final Rx<UserStatus> userStatus = UserStatus.notAuthenticated.obs;

  Future<void> _checkForAppUpdate() async {
    final update = await AppUpdateService().checkForUpdate();
    if (update != null && update.required) {
      // Block until a required update completes before entering the app.
      await AppUpdateService().promptUpdate(update, required: true);
    } else if (update != null) {
      AppUpdateService().promptUpdate(update);
    }
  }

  @override
  void onInit() {
    super.onInit();
    _checkUserStatusAndNavigate();
  }

  Future<void> _checkUserStatusAndNavigate() async {
    try {
      await Future.delayed(const Duration(milliseconds: 900));

      _checkForAppUpdate();

      if (!_hasSeenOnboarding()) {
        Get.offAllNamed(RouteNames.onboarding);
        return;
      }

      final token = StorageHelper().readData('token')?.toString() ?? '';
      if (token.isEmpty) {
        userStatus.value = UserStatus.notAuthenticated;
        Get.offAllNamed(RouteNames.login);
        return;
      }

      final role =
          StorageHelper().readData('role')?.toString().toLowerCase() ?? '';

      if (role == 'admin') {
        Get.offAllNamed(RouteNames.adminPanel);
        return;
      }

      if (role == 'volunteer') {
        userStatus.value = UserStatus.verified;
        Get.offAllNamed(RouteNames.startPoint);
        return;
      }

      if (role == 'user' || _isRequesteeRole(role)) {
        await _handleUserRole();
        return;
      }

      await _fetchAndNavigateBasedOnStatus();
    } catch (e) {
      final cachedStatus =
          StorageHelper().readData('verificationStatus')?.toString() ?? '';
      if (cachedStatus.isNotEmpty) {
        _navigateBasedOnStatus(cachedStatus);
        return;
      }

      userStatus.value = UserStatus.notAuthenticated;
      Get.offAllNamed(RouteNames.login);
    } finally {
      isLoading.value = false;
    }
  }

  bool _hasSeenOnboarding() {
    final onboardingData = StorageHelper().readData('hasSeenOnboarding');
    if (onboardingData is bool) {
      return onboardingData;
    }
    if (onboardingData is String) {
      return onboardingData.toLowerCase() == 'true';
    }
    return false;
  }

  bool _isRequesteeRole(String role) {
    return role == 'requestee' ||
        role == 'request_help' ||
        role == 'requesthelp';
  }

  Future<void> _fetchAndNavigateBasedOnStatus() async {
    try {
      final response = await DioHelper()
          .get(
            url: ApiNames.getvolunteerStats,
            isauthorize: true,
          )
          .timeout(const Duration(seconds: 8));

      var verificationStatus = '';
      final snapshot = _VolunteerStatusSnapshot.fromResponse(response);
      verificationStatus = snapshot.status;

      if (snapshot.hasApplication && verificationStatus.isNotEmpty) {
        StorageHelper().saveData('verificationStatus', verificationStatus);
      }

      _navigateBasedOnStatus(
        verificationStatus,
        hasApplication: snapshot.hasApplication,
      );
    } catch (e) {
      final cachedStatus =
          StorageHelper().readData('verificationStatus')?.toString() ?? '';
      _navigateBasedOnStatus(cachedStatus, hasApplication: true);
    }
  }

  Future<void> _handleUserRole() async {
    final snapshot = await _fetchVolunteerStatus();
    if (snapshot.hasApplication && snapshot.isPending) {
      StorageHelper().saveData('verificationStatus', 'pending');
      userStatus.value = UserStatus.pending;
      Get.offAllNamed(RouteNames.waitingScreen);
      return;
    }

    if (snapshot.hasApplication && snapshot.isApproved) {
      StorageHelper().clearSessionData();
      userStatus.value = UserStatus.notAuthenticated;
      Get.offAllNamed(RouteNames.login);
      return;
    }

    if (snapshot.hasApplication && snapshot.isRejected) {
      StorageHelper().saveData('verificationStatus', snapshot.status);
    } else {
      StorageHelper().removeData('verificationStatus');
    }

    StorageHelper().saveData('role', 'user');
    userStatus.value = UserStatus.authenticated;
    Get.offAllNamed(RouteNames.requestHome);
  }

  Future<_VolunteerStatusSnapshot> _fetchVolunteerStatus() async {
    try {
      final response = await DioHelper()
          .get(
            url: ApiNames.getvolunteerStats,
            isauthorize: true,
          )
          .timeout(const Duration(seconds: 8));
      return _VolunteerStatusSnapshot.fromResponse(response);
    } catch (_) {
      return const _VolunteerStatusSnapshot(status: '', hasApplication: false);
    }
  }

  void _navigateBasedOnStatus(
    String verificationStatus, {
    bool hasApplication = true,
  }) {
    final status = verificationStatus.toLowerCase();
    if (!hasApplication) {
      userStatus.value = UserStatus.authenticated;
      Get.offAllNamed(RouteNames.requestHome);
    } else if (status.isEmpty) {
      userStatus.value = UserStatus.authenticated;
      Get.offAllNamed(RouteNames.roleSelection);
    } else if (status == 'pending') {
      userStatus.value = UserStatus.pending;
      Get.offAllNamed(RouteNames.waitingScreen);
    } else if (status == 'verified' || status == 'approved') {
      userStatus.value = UserStatus.verified;
      Get.offAllNamed(RouteNames.startPoint);
    } else if (status == 'rejected' || status == 'disapproved') {
      userStatus.value = UserStatus.authenticated;
      Get.offAllNamed(RouteNames.roleSelection);
    } else {
      userStatus.value = UserStatus.authenticated;
      Get.offAllNamed(RouteNames.startPoint);
    }
  }
}

class _VolunteerStatusSnapshot {
  final String status;
  final bool hasApplication;

  const _VolunteerStatusSnapshot({
    required this.status,
    required this.hasApplication,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved' || status == 'verified';
  bool get isRejected => status == 'rejected' || status == 'disapproved';

  factory _VolunteerStatusSnapshot.fromResponse(dynamic response) {
    Map<String, dynamic> root = {};
    if (response is Map<String, dynamic>) {
      root = response;
    } else if (response is Map) {
      root = Map<String, dynamic>.from(response);
    }

    final data =
        root['data'] is Map
            ? Map<String, dynamic>.from(root['data'] as Map)
            : root;
    final status =
        (data['status'] ??
                data['verificationStatus'] ??
                data['verification_status'] ??
                '')
            .toString()
            .toLowerCase()
            .trim();
    final hasApplication =
        data['_id'] != null ||
        data['id'] != null ||
        data['userId'] != null ||
        data['cnic'] != null;

    return _VolunteerStatusSnapshot(
      status: status,
      hasApplication: hasApplication,
    );
  }
}
