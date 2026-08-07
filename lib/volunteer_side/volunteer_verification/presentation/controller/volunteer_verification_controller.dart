import 'package:flutter/material.dart';
import 'package:fyp_source_code/services/location_services.dart';
import 'package:fyp_source_code/volunteer_side/volunteer_verification/data/model/admin_verification_request.dart';
import 'package:fyp_source_code/volunteer_side/volunteer_verification/data/repo/volunteer_verification_repo.dart';
import 'package:fyp_source_code/utilities/helpers/toast_helper.dart';
import 'package:fyp_source_code/utilities/reuse_components/storage_helper.dart';
import 'package:fyp_source_code/utilities/validators/validators.dart';
import 'package:fyp_source_code/utilities/validators/verification_validators.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

class VolunteerVerificationPhoto {
  final XFile file;
  final Uint8List bytes;

  const VolunteerVerificationPhoto({required this.file, required this.bytes});

  String get name {
    final pathName = file.path.split(RegExp(r'[\\/]')).last.trim();
    return pathName.isNotEmpty ? pathName : file.name;
  }

  String? get mimeType => file.mimeType;
}

class VolunteerVerificationController extends GetxController {
  static const int maxPhotoBytes = 5 * 1024 * 1024;

  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
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
  final Rxn<VolunteerVerificationPhoto> cnicFrontPhoto =
      Rxn<VolunteerVerificationPhoto>();
  final Rxn<VolunteerVerificationPhoto> cnicBackPhoto =
      Rxn<VolunteerVerificationPhoto>();
  final Rxn<VolunteerVerificationPhoto> profilePhoto =
      Rxn<VolunteerVerificationPhoto>();
  final RxBool isSubmitting = false.obs;
  final RxBool isResolvingLocation = false.obs;
  final RxnDouble latitude = RxnDouble();
  final RxnDouble longitude = RxnDouble();
  final RxList<VolunteerVerification> submissions = RxList();

  final verificationFormKey = GlobalKey<FormState>();
  final VolunteerVerificationRepo _repo = VolunteerVerificationRepo();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    _prefillStoredProfile();
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

  Future<void> pickCnicFrontPhoto() async {
    cnicFrontPhoto.value = await _pickSinglePhoto();
  }

  Future<void> pickCnicBackPhoto() async {
    cnicBackPhoto.value = await _pickSinglePhoto();
  }

  Future<void> pickProfilePhoto() async {
    profilePhoto.value = await _pickSinglePhoto();
  }

  Future<void> useCurrentLocation() async {
    isResolvingLocation.value = true;
    try {
      final position = await getCurrentLocation();
      latitude.value = position.latitude;
      longitude.value = position.longitude;

      final locationName = await getLocationNameFromCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      final readableLocation =
          locationName == 'Location unavailable'
              ? 'Near ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}'
              : locationName;

      locationController.text = readableLocation;
      if (cityController.text.trim().isEmpty) {
        cityController.text = _cityFromLocation(readableLocation);
      }

      ToastHelper.showSuccess('Current location added.');
    } catch (e) {
      ToastHelper.showErrorMessage(e);
    } finally {
      isResolvingLocation.value = false;
    }
  }

  // ============ SUBMIT VERIFICATION ============
  Future<void> submitVerification() async {
    // Validate form
    if (!verificationFormKey.currentState!.validate()) {
      ToastHelper.showError('Please fix the errors above');
      return;
    }

    if (cnicFrontPhoto.value == null || cnicBackPhoto.value == null) {
      ToastHelper.showError('Please upload CNIC front and back images.');
      return;
    }

    isSubmitting.value = true;

    try {
      final token = StorageHelper().readData('token');
      if (token == null || token.isEmpty) {
        throw Exception('User not authenticated. Please login again');
      }

      final uploadedUrls = await _uploadVerificationMedia();
      if (uploadedUrls['cnicFrontImage'] == null ||
          uploadedUrls['cnicBackImage'] == null) {
        throw Exception('Could not upload CNIC images.');
      }

      final reqBody = {
        'name': fullNameController.text.trim(),
        'expertise': expertiseController.text.trim(),
        'cnic': cnicController.text.trim(),
        'reason': descriptionController.text.trim(),
        'location': locationController.text.trim(),
        'city': cityController.text.trim(),
        if (latitude.value != null && longitude.value != null) ...{
          'latitude': latitude.value,
          'longitude': longitude.value,
        },
        'cnicFrontImage': uploadedUrls['cnicFrontImage'],
        'cnicBackImage': uploadedUrls['cnicBackImage'],
        if (uploadedUrls['profileImage'] != null)
          'profileImage': uploadedUrls['profileImage'],
      };

      debugPrint('Verification payload: $reqBody');

      // Submit returns a single VolunteerVerification object
      final submission = await _repo.submit(reqBody);

      debugPrint('Verification submitted successfully');
      debugPrint('Submission ID: ${submission.sId}');
      debugPrint('Submission Status: ${submission.status}');

      // Save verification status to storage
      StorageHelper().saveData(
        'verificationStatus',
        submission.status ?? 'pending',
      );
      final savedProfileImage = uploadedUrls['profileImage'];
      if (savedProfileImage != null && savedProfileImage.isNotEmpty) {
        StorageHelper().saveData('profile_image', savedProfileImage);
      }

      ToastHelper.showSuccess('Verification request submitted!');
      clearForm();

      Future.delayed(Duration(milliseconds: 500), () {
        Get.toNamed('/waitingScreen');
        StorageHelper().saveData(
          'verificationStatus',
          submission.status ?? 'pending',
        );
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
        cnicFrontPhoto.value != null &&
        cnicBackPhoto.value != null;
  }

  // ============ CLEAR FORM ============
  void clearForm() {
    final savedName =
        StorageHelper().readData('profile_name')?.toString().trim();
    final savedEmail = StorageHelper().readData('email')?.toString().trim();
    final savedLocation =
        StorageHelper().readData('profile_location')?.toString().trim();

    fullNameController.text = savedName?.isNotEmpty == true ? savedName! : '';
    emailController.text = savedEmail?.isNotEmpty == true ? savedEmail! : '';
    expertiseController.clear();
    cnicController.clear();
    descriptionController.clear();
    cityController.clear();
    locationController.text =
        savedLocation?.isNotEmpty == true ? savedLocation! : '';
    cnicFrontPhoto.value = null;
    cnicBackPhoto.value = null;
    profilePhoto.value = null;
    latitude.value = null;
    longitude.value = null;

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
          debugPrint('Loaded ${list.length} submissions');
        })
        .catchError((e) {
          debugPrint('Failed to load verifications: $e');
        });
  }

  @override
  void onClose() {
    fullNameController.dispose();
    emailController.dispose();
    expertiseController.dispose();
    cnicController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    cityController.dispose();
    super.onClose();
  }

  Future<VolunteerVerificationPhoto?> _pickSinglePhoto() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
      );
      if (picked == null) {
        return null;
      }

      final bytes = await picked.readAsBytes();
      if (bytes.length > maxPhotoBytes) {
        ToastHelper.showWarning('Each image must be 5MB or less.');
        return null;
      }

      return VolunteerVerificationPhoto(file: picked, bytes: bytes);
    } catch (e) {
      ToastHelper.showErrorMessage(e);
      return null;
    }
  }

  Future<Map<String, String?>> _uploadVerificationMedia() async {
    final uploads = <VolunteerMediaUpload>[];
    final keys = <String>[];

    if (cnicFrontPhoto.value != null) {
      uploads.add(
        VolunteerMediaUpload(
          filename: cnicFrontPhoto.value!.name,
          bytes: cnicFrontPhoto.value!.bytes,
          mimeType: cnicFrontPhoto.value!.mimeType,
        ),
      );
      keys.add('cnicFrontImage');
    }

    if (cnicBackPhoto.value != null) {
      uploads.add(
        VolunteerMediaUpload(
          filename: cnicBackPhoto.value!.name,
          bytes: cnicBackPhoto.value!.bytes,
          mimeType: cnicBackPhoto.value!.mimeType,
        ),
      );
      keys.add('cnicBackImage');
    }

    if (profilePhoto.value != null) {
      uploads.add(
        VolunteerMediaUpload(
          filename: profilePhoto.value!.name,
          bytes: profilePhoto.value!.bytes,
          mimeType: profilePhoto.value!.mimeType,
        ),
      );
      keys.add('profileImage');
    }

    final urls = await _repo.uploadVolunteerMedia(uploads);
    final mapped = <String, String?>{};
    for (var i = 0; i < keys.length; i++) {
      mapped[keys[i]] = i < urls.length ? urls[i] : null;
    }
    return mapped;
  }

  void _prefillStoredProfile() {
    final storage = StorageHelper();
    final savedName = storage.readData('profile_name')?.toString().trim() ?? '';
    final savedEmail = storage.readData('email')?.toString().trim() ?? '';
    final savedLocation =
        storage.readData('profile_location')?.toString().trim() ?? '';

    if (savedName.isNotEmpty) {
      fullNameController.text = savedName;
    }
    if (savedEmail.isNotEmpty) {
      emailController.text = savedEmail;
    }
    if (savedLocation.isNotEmpty) {
      locationController.text = savedLocation;
    }
  }

  String _cityFromLocation(String value) {
    final parts =
        value
            .split(',')
            .map((part) => part.trim())
            .where((part) => part.isNotEmpty)
            .toList();
    if (parts.isEmpty) {
      return '';
    }
    if (parts.length >= 2) {
      return parts[parts.length - 2];
    }
    return parts.first;
  }
}
