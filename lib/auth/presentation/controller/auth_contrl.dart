import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fyp_source_code/auth/data/models/signin_model.dart';
import 'package:fyp_source_code/auth/data/repo/login-_repo.dart';
import 'package:fyp_source_code/auth/data/repo/signup_repo.dart';
import 'package:fyp_source_code/network/api_service.dart';
import 'package:fyp_source_code/request_side/home/presentation/controller/tracking_controller.dart';
import 'package:fyp_source_code/routing/route_names.dart';
import 'package:fyp_source_code/services/api_names.dart';
import 'package:fyp_source_code/services/auth_service.dart';
import 'package:fyp_source_code/utilities/helpers/toast_helper.dart';
import 'package:fyp_source_code/utilities/reuse_components/storage_helper.dart';
import 'package:fyp_source_code/utilities/validators/validators.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class AuthController extends GetxController {
  final loginFormKey = GlobalKey<FormState>();
  final registerFormKey = GlobalKey<FormState>();

  // Form state observables
  RxString passwordError = ''.obs;
  RxString emailError = ''.obs;
  RxString nameError = ''.obs;
  RxString confirmPasswordError = ''.obs;
  RxString userRole = ''.obs;

  // UI state observables
  RxBool isPasswordVisible = false.obs;
  RxBool isConfirmPasswordVisible = false.obs;
  RxBool isRememberMe = false.obs;
  RxBool isFieldEmpt = true.obs;
  RxBool isLoading = false.obs;

  // Text controllers
  TextEditingController emailController = TextEditingController();
  TextEditingController passController = TextEditingController();
  TextEditingController confirmPassController = TextEditingController();
  TextEditingController usernameController = TextEditingController();

  SignupModel signupModel = SignupModel();
  SignupModel loginModel = SignupModel();
  User user = User();
  Future<void>? _backendWarmup;

  @override
  void onInit() {
    super.onInit();
    GetStorage.init();
    // Monitor form fields for changes
    emailController.addListener(_validateFormState);
    passController.addListener(_validateFormState);
    usernameController.addListener(_validateFormState);
    confirmPassController.addListener(_validateFormState);
    _backendWarmup = DioHelper().warmUpBackend();
  }

  // ============ FORM STATE MANAGEMENT ============
  void _validateFormState() {
    isFieldEmpt.value =
        emailController.text.isEmpty ||
        passController.text.isEmpty ||
        usernameController.text.isEmpty;
  }

  // ============ EMAIL VALIDATION ============
  String? validateEmail(String? value) {
    return AppValidators.validateEmail(value);
  }

  // ============ PASSWORD VALIDATION ============
  String? validatePassword(String? value) {
    return AppValidators.validatePassword(value);
  }

  // ============ NAME VALIDATION ============
  String? validateName(String? value) {
    return AppValidators.validateName(value);
  }

  // ============ CONFIRM PASSWORD VALIDATION ============
  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      confirmPasswordError.value = 'auth.error.confirm_password'.tr;
      return confirmPasswordError.value;
    }

    final result = AppValidators.validateConfirmPassword(
      value,
      passController.text,
    );
    if (result != null) {
      confirmPasswordError.value = result;
      return result;
    }

    confirmPasswordError.value = '';
    return null;
  }

  // ============ TOGGLE PASSWORD VISIBILITY ============
  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  // ============ REMEMBER ME TOGGLE ============
  void toggleRememberMe(bool value) {
    isRememberMe.value = value;
    if (value) {
      StorageHelper().saveData('rememberEmail', emailController.text);
    } else {
      StorageHelper().removeData('rememberEmail');
    }
  }

  // ============ LOGIN ============
  Future<void> onLogin() async {
    if (!loginFormKey.currentState!.validate()) {
      ToastHelper.showError('auth.error.fix_errors'.tr);
      return;
    }

    isLoading.value = true;

    try {
      await _backendWarmup?.timeout(
        const Duration(seconds: 95),
        onTimeout: () {},
      );

      // Create login request
      loginModel.user = User(
        email: emailController.text.trim(),
        password: passController.text,
      );

      // Call API
      final resp = await LoginRepo().loginRepo(loginModel.toJson());

      // Validate response
      if (resp.accessToken == null || resp.accessToken!.isEmpty) {
        throw Exception('Server did not return access token');
      }

      if (resp.user == null) {
        throw Exception('Server did not return user data');
      }

      // Store credentials
      StorageHelper().saveData('token', resp.accessToken);
      StorageHelper().saveData('email', resp.user!.email);
      StorageHelper().saveData('profile_email', resp.user!.email);
      StorageHelper().saveData('userId', resp.user!.id);
      if (resp.user!.role != null && resp.user!.role!.trim().isNotEmpty) {
        StorageHelper().saveData('role', resp.user!.role!.trim());
        userRole.value = resp.user!.role!.trim();
      }
      if (resp.user!.verificationStatus != null &&
          resp.user!.verificationStatus!.trim().isNotEmpty) {
        StorageHelper().saveData(
          'verificationStatus',
          resp.user!.verificationStatus!.trim(),
        );
      }
      if ((resp.user!.fullName ?? resp.user!.username) != null) {
        StorageHelper().saveData(
          'profile_name',
          (resp.user!.fullName ?? resp.user!.username)!.trim(),
        );
      }
      if (resp.user!.location != null) {
        StorageHelper().saveData(
          'profile_location',
          resp.user!.location!.trim(),
        );
      }
      if (resp.user!.profileImage != null &&
          resp.user!.profileImage!.trim().isNotEmpty) {
        StorageHelper().saveData(
          'profile_image',
          resp.user!.profileImage!.trim(),
        );
      }

      // Show success message
      ToastHelper.showSuccess('auth.success.login'.tr);

      // Navigate based on the backend account role, not the chosen app mode.
      Future.delayed(Duration(milliseconds: 500), () async {
        await _navigateAfterLogin(resp.user!);
      });
    } catch (e) {
      ToastHelper.showErrorMessage(e);
    } finally {
      isLoading.value = false;
    }
  }

  // ============ REGISTER ============
  Future<void> onRegisterClick() async {
    if (!registerFormKey.currentState!.validate()) {
      ToastHelper.showError('auth.error.fix_errors'.tr);
      return;
    }

    // Validate confirm password matches
    if (passController.text != confirmPassController.text) {
      ToastHelper.showError('auth.error.passwords_mismatch'.tr);
      return;
    }

    isLoading.value = true;

    try {
      // Create signup request
      signupModel.user = User(
        username: usernameController.text.trim(),
        email: emailController.text.trim(),
        password: passController.text,
      );

      // Call API
      final resp = await RegisterRepo().postData(signupModel);

      // Validate response
      if (resp.accessToken == null || resp.accessToken!.isEmpty) {
        throw Exception('Server did not return access token');
      }

      // Store credentials
      StorageHelper().saveData('token', resp.accessToken);
      StorageHelper().saveData('email', resp.user?.email);
      StorageHelper().saveData('profile_email', resp.user?.email);
      StorageHelper().saveData('userId', resp.user?.id);
      if (resp.user?.role != null && resp.user!.role!.trim().isNotEmpty) {
        StorageHelper().saveData('role', resp.user!.role!.trim());
        userRole.value = resp.user!.role!.trim();
      }
      if (resp.user?.verificationStatus != null &&
          resp.user!.verificationStatus!.trim().isNotEmpty) {
        StorageHelper().saveData(
          'verificationStatus',
          resp.user!.verificationStatus!.trim(),
        );
      }
      if ((resp.user?.fullName ?? resp.user?.username) != null) {
        StorageHelper().saveData(
          'profile_name',
          (resp.user?.fullName ?? resp.user?.username)!.trim(),
        );
      }
      if (resp.user?.location != null) {
        StorageHelper().saveData(
          'profile_location',
          resp.user!.location!.trim(),
        );
      }
      if (resp.user?.profileImage != null &&
          resp.user!.profileImage!.trim().isNotEmpty) {
        StorageHelper().saveData(
          'profile_image',
          resp.user!.profileImage!.trim(),
        );
      }

      // Show success message
      ToastHelper.showSuccess('auth.success.register'.tr);

      // Navigate to role selection
      Future.delayed(Duration(milliseconds: 500), () {
        Get.offAllNamed(RouteNames.roleSelection);
      });
    } catch (e) {
      ToastHelper.showErrorMessage(e);
    } finally {
      isLoading.value = false;
    }
  }

  // ============ GOOGLE SIGN-IN ============
  Future<void> signInWithGoogle() async {
    isLoading.value = true;

    try {
      final result = await AuthService().signInWithGoogle();

      if (result['success'] == true) {
        final model = result['data'] as SignupModel;
        ToastHelper.showSuccess('auth.success.google'.tr);
        Future.delayed(const Duration(milliseconds: 500), () async {
          await _navigateAfterLogin(model.user!);
        });
      } else {
        ToastHelper.showError(
          (result['message'] as String?) ?? 'auth.error.google_failed'.tr,
        );
      }
    } catch (e) {
      ToastHelper.showErrorMessage(e);
    } finally {
      isLoading.value = false;
    }
  }

  // ============ CLEAR FORM ============
  void clearLoginForm() {
    emailController.clear();
    passController.clear();
    isRememberMe.value = false;
    emailError.value = '';
    passwordError.value = '';
  }

  void clearRegisterForm() {
    usernameController.clear();
    emailController.clear();
    passController.clear();
    confirmPassController.clear();
    nameError.value = '';
    emailError.value = '';
    passwordError.value = '';
    confirmPasswordError.value = '';
  }

  // ============ LOGOUT ============
  Future<void> logout() async {
    try {
      if (Get.isRegistered<TrackingController>()) {
        Get.find<TrackingController>().stopTracking();
        Get.delete<TrackingController>(force: true);
      }
      await AuthService().signOut();
      StorageHelper().clearSessionData();
      userRole.value = '';
      clearLoginForm();
      clearRegisterForm();
      Get.offAllNamed(RouteNames.login);
    } catch (_) {
      Get.offAllNamed(RouteNames.login);
    }
  }

  Future<void> _navigateAfterLogin(User signedInUser) async {
    final role = signedInUser.role?.toLowerCase().trim() ?? 'user';

    if (role == 'admin') {
      Get.offAllNamed(RouteNames.adminPanel);
      return;
    }

    if (role == 'volunteer') {
      StorageHelper().saveData('role', 'volunteer');
      StorageHelper().saveData('verificationStatus', 'approved');
      await Get.offAllNamed(RouteNames.startPoint);
      return;
    }

    final status = await _fetchVolunteerStatusSnapshot();
    if (status.hasApplication && status.isPending) {
      StorageHelper().saveData('verificationStatus', 'pending');
      Get.offAllNamed(RouteNames.waitingScreen);
      return;
    }

    if (status.hasApplication && status.isApproved) {
      StorageHelper().saveData('verificationStatus', status.status);
      ToastHelper.showSuccess(
        'auth.volunteer.approved_relogin'.tr,
      );
      await logout();
      return;
    }

    if (status.hasApplication && status.isRejected) {
      StorageHelper().saveData('verificationStatus', status.status);
    } else {
      StorageHelper().removeData('verificationStatus');
    }

    StorageHelper().saveData('role', 'user');
    Get.offAllNamed(RouteNames.requestHome);
  }

  Future<_VolunteerStatusSnapshot> _fetchVolunteerStatusSnapshot() async {
    try {
      final response = await DioHelper().get(
        url: ApiNames.getvolunteerStats,
        isauthorize: true,
      );
      return _VolunteerStatusSnapshot.fromResponse(response);
    } catch (_) {
      return const _VolunteerStatusSnapshot(status: '', hasApplication: false);
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passController.dispose();
    confirmPassController.dispose();
    usernameController.dispose();
    super.onClose();
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
