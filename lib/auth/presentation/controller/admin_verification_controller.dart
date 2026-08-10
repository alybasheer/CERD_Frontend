import 'package:flutter/material.dart';
import 'package:fyp_source_code/volunteer_side/volunteer_verification/data/model/admin_verification_request.dart';
import 'package:fyp_source_code/volunteer_side/volunteer_verification/data/repo/volunteer_verification_repo.dart';
import 'package:fyp_source_code/utilities/helpers/toast_helper.dart';
import 'package:fyp_source_code/utilities/reuse_components/storage_helper.dart';
import 'package:fyp_source_code/utilities/validators/validators.dart';
import 'package:fyp_source_code/utilities/validators/verification_validators.dart';
import 'package:get/get.dart';

class AdminVerificationController extends GetxController {
  final fullNameController = TextEditingController();
  final expertiseController = TextEditingController();
  final cnicController = TextEditingController();
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();
  final cityController = TextEditingController();

  // Form state observables for error messages
  final RxString fullNameError = ''.obs;
  final RxString expertiseError = ''.obs;
  final RxString cnicError = ''.obs;
  final RxString descriptionError = ''.obs;
  final RxString locationError = ''.obs;
  final RxString cityError = ''.obs;
  final RxString emailError = ''.obs;

  // UI state observables
  final Rx<String?> selectedImagePath = Rx<String?>(null);
  final RxBool isSubmitting = false.obs;
  final RxList<VolunteerVerification> submissions = RxList();

  final verificationFormKey = GlobalKey<FormState>();
  final VolunteerVerificationRepo _repo = VolunteerVerificationRepo();

  @override
  void onInit() {
    super.onInit();
    loadSubmissions();
  }

  // ============ VALIDATION METHODS ============
  String? validateFullName(String? value) {
    final result = VerificationValidators.validateFullName(value);
    fullNameError.value = result ?? '';
    return result;
  }

  String? validateExpertise(String? value) {
    final result = VerificationValidators.validateExpertise(value);
    expertiseError.value = result ?? '';
    return result;
  }

  String? validateEmail(String? value) {
    final result = AppValidators.validateEmail(value);
    emailError.value = result ?? '';
    return result;
  }

  String? validateCNIC(String? value) {
    final result = VerificationValidators.validateCNIC(value);
    cnicError.value = result ?? '';
    return result;
  }

  String? validateDescription(String? value) {
    final result = VerificationValidators.validateDescription(value);
    descriptionError.value = result ?? '';
    return result;
  }

  String? validateCity(String? value) {
    final result = VerificationValidators.validateCity(value);
    cityError.value = result ?? '';
    return result;
  }

  String? validateLocation(String? value) {
    final result = VerificationValidators.validateLocation(value);
    locationError.value = result ?? '';
    return result;
  }

  /// Update status of a submission (pending -> approved/disapproved)
  void updateSubmissionStatus(String id, String newStatus) {
    final idx = submissions.indexWhere((s) => s.sId == id);
    if (idx >= 0) {
      final current = submissions[idx];
      current.status = newStatus;
      submissions[idx] = current;
    }
  }

  void setImagePath(String path) {
    selectedImagePath.value = path;
  }

  // ============ SUBMIT VERIFICATION ============
  Future<void> submitVerification() async {
    // Validate form
    if (!verificationFormKey.currentState!.validate()) {
      ToastHelper.showError('Please fix the errors above');
      return;
    }

    // // Validate image is selected
    // if (selectedImagePath.value == null || selectedImagePath.value!.isEmpty) {
    //   ToastHelper.showError('Please upload a profile photo');
    //   return;
    // }

    isSubmitting.value = true;

    try {
      final token = StorageHelper().readData('token');
      if (token == null || token.isEmpty) {
        throw Exception('User not authenticated. Please login again');
      }

      final reqBody = {
        'name': fullNameController.text.trim(),
        'expertise': expertiseController.text.trim(),
        'cnic': cnicController.text.trim(),
        'reason': descriptionController.text.trim(),
        'location': locationController.text.trim(),
        'city': cityController.text.trim(),
        'imagePath': selectedImagePath.value,
      };

      print('📤 Verification payload: $reqBody');

      // Submit returns a single VolunteerVerification object
      final submission = await _repo.submit(reqBody);

      print(' Verification submitted successfully');
      print(' Submission ID: ${submission.sId}');
      print(' Submission Status: ${submission.status}');

      // Save verification status to storage
      StorageHelper().saveData(
        'verificationStatus',
        submission.status ?? 'pending',
      );

      ToastHelper.showSuccess('Verification request submitted!');
      clearForm();

      Future.delayed(Duration(milliseconds: 500), () {
        Get.toNamed('/waitingScreen');
         StorageHelper().saveData('verificationStatus', submission.status ?? 'pending');
      });
    } catch (e) {
      ToastHelper.showErrorMessage(e);
    } finally {
      isSubmitting.value = false;
    }
  }

  // ============ FORM VALIDATION ============
  bool validateForm() {
    return fullNameController.text.isNotEmpty &&
        expertiseController.text.isNotEmpty &&
        cnicController.text.isNotEmpty &&
        descriptionController.text.isNotEmpty &&
        locationController.text.isNotEmpty &&
        cityController.text.isNotEmpty &&
        selectedImagePath.value != null;
  }

  // ============ CLEAR FORM ============
  void clearForm() {
    fullNameController.clear();
    expertiseController.clear();
    cnicController.clear();
    descriptionController.clear();
    locationController.clear();
    cityController.clear();
    selectedImagePath.value = null;

    fullNameError.value = '';
    expertiseError.value = '';
    cnicError.value = '';
    descriptionError.value = '';
    locationError.value = '';
    cityError.value = '';
  }

  // ============ LOAD SUBMISSIONS ============
  void loadSubmissions() {
    _repo
        .fetchAll()
        .then((list) {
          submissions.assignAll(list);
          print('✅ Loaded ${list.length} submissions');
        })
        .catchError((e) {
          print('❌ Failed to load verifications: $e');
        });
  }

  @override
  void onClose() {
    fullNameController.dispose();
    expertiseController.dispose();
    cnicController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    cityController.dispose();
    super.onClose();
  }
}
