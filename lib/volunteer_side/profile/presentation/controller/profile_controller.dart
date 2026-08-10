import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fyp_source_code/network/api_service.dart';
import 'package:fyp_source_code/routing/route_names.dart';
import 'package:fyp_source_code/services/api_names.dart';
import 'package:fyp_source_code/services/location_services.dart';
import 'package:fyp_source_code/utilities/helpers/toast_helper.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_colors.dart';
import 'package:fyp_source_code/utilities/reuse_components/storage_helper.dart';
import 'package:fyp_source_code/utilities/validators/validators.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ProfileController extends GetxController with WidgetsBindingObserver {
  final storage = GetStorage();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final locationController = TextEditingController();

  final isSwitching = false.obs;
  final isSaving = false.obs;
  final isResolvingLocation = false.obs;
  final role = ''.obs;
  final verificationStatus = ''.obs;
  final profileName = ''.obs;
  final profileEmail = ''.obs;
  final profileLocation = ''.obs;
  final profileImage = ''.obs;
  final volunteerRating = 0.0.obs;
  final volunteerRatingCount = 0.obs;
  final completedCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    refreshFromStorage();
    themeLoad();
    unawaited(fetchVolunteerStats());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refreshFromStorage();
      unawaited(themeLoad());
      unawaited(fetchVolunteerStats());
    }
  }

  void refreshFromStorage() {
    final savedName = _readFirstString([
      'profile_name',
      'name',
      'username',
    ], fallback: 'profile.fallback_name'.tr);
    final savedEmail = _readFirstString([
      'profile_email',
      'email',
    ], fallback: 'user@example.com');
    final savedLocation = _readFirstString([
      'profile_location',
      'locationName',
      'city',
      'location',
    ], fallback: 'profile.fallback_location'.tr);
    final savedProfileImage = _readFirstString([
      'profile_image',
      'profileImage',
      'avatar',
      'image',
    ]);

    nameController.text = savedName;
    emailController.text = savedEmail;
    locationController.text =
        isGenericLocationLabel(savedLocation)
            ? 'volunteer.home.resolving_area'.tr
            : savedLocation;
    role.value = _normalizeRole(_readFirstString(['role']));
    verificationStatus.value = _readFirstString(['verificationStatus']);
    profileImage.value = savedProfileImage;
    isSwitching.value =
        storage.read('theme') == true || storage.read('dark_mode') == true;
    volunteerRating.value =
        _readDouble(storage.read('volunteer_rating_average')) ?? 0;
    volunteerRatingCount.value =
        _readInt(storage.read('volunteer_rating_count')) ?? 0;
    completedCount.value = _readInt(storage.read('volunteer_completed_count')) ?? 0;
    _syncPreviewFields();
    unawaited(_resolveSavedLocation(savedLocation));
  }

  Future<void> fetchVolunteerStats() async {
    if (!isVolunteer) {
      return;
    }

    try {
      final statusResponse = await DioHelper().get(
        url: ApiNames.getvolunteerStats,
        isauthorize: true,
      );

      if (statusResponse is Map) {
        final responseMap = Map<String, dynamic>.from(statusResponse);
        final data = responseMap['data'] is Map
            ? Map<String, dynamic>.from(responseMap['data'])
            : responseMap;

        final completed = _readInt(
          data['completedRequests'] ??
              data['completedCount'] ??
              data['totalHelped'] ??
              data['resolvedRequests'] ??
              data['helpRequestsCompleted'],
        );
        if (completed != null) {
          completedCount.value = completed;
        }

        final rating = _readDouble(
          data['ratingAverage'] ??
              data['averageRating'] ??
              data['avgRating'] ??
              data['rating'],
        );
        if (rating != null) {
          volunteerRating.value = rating;
        }

        final ratingCount = _readInt(
          data['ratingCount'] ??
              data['ratingsCount'] ??
              data['totalRatings'],
        );
        if (ratingCount != null) {
          volunteerRatingCount.value = ratingCount;
        }
      }

      storage.write('volunteer_rating_average', volunteerRating.value);
      storage.write('volunteer_rating_count', volunteerRatingCount.value);
      storage.write('volunteer_completed_count', completedCount.value);
    } catch (_) {
      // Keep the cached values when the rating stats endpoint is unavailable.
    }
  }

  Future<void> saveProfile() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final location = locationController.text.trim();

    if (name.isEmpty) {
      ToastHelper.showError('profile.name_required'.tr);
      return;
    }

    final emailError = AppValidators.validateEmail(email);
    if (emailError != null) {
      ToastHelper.showError(emailError);
      return;
    }

    isSaving.value = true;
    try {
      storage.write('profile_name', name);
      storage.write('profile_email', email);
      storage.write('email', email);
      if (location.isNotEmpty) {
        storage.write('profile_location', location);
      }
      storage.write('profile_image', profileImage.value.trim());
      _syncPreviewFields();
      ToastHelper.showSuccess('profile.updated'.tr);
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> useCurrentLocation() async {
    isResolvingLocation.value = true;
    try {
      final position = await getCurrentLocation();
      final locationName = await getLocationNameFromCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (locationName == 'Location unavailable') {
        ToastHelper.showError('profile.location_failed'.tr);
        return;
      }
      _setResolvedLocation(locationName);
      ToastHelper.showSuccess('profile.location_updated'.tr);
    } catch (e) {
      ToastHelper.showErrorMessage(e);
    } finally {
      isResolvingLocation.value = false;
    }
  }

  void onSwitch([bool? value]) {
    isSwitching.value = value ?? !isSwitching.value;
    storage.write('theme', isSwitching.value);
    storage.write('dark_mode', isSwitching.value);
    Get.changeThemeMode(isSwitching.value ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> themeLoad() async {
    isSwitching.value =
        storage.read('theme') == true || storage.read('dark_mode') == true;
    Get.changeThemeMode(isSwitching.value ? ThemeMode.dark : ThemeMode.light);
  }

  bool get isVolunteer => role.value == 'volunteer';

  bool get isAdmin => role.value == 'admin';

  bool get isRequestee {
    return role.value == 'requestee' ||
        role.value == 'request_help' ||
        role.value == 'requesthelp';
  }

  String get displayRole {
    if (isVolunteer) {
      return 'profile.role.volunteer'.tr;
    }
    if (isRequestee) {
      return 'profile.role.requestee'.tr;
    }
    return 'profile.role.member'.tr;
  }

  String get statusLabel {
    if (isVolunteer) {
      final status = verificationStatus.value.trim();
      if (status.isEmpty) {
        return 'profile.status_not_submitted'.tr;
      }
      return status[0].toUpperCase() + status.substring(1).toLowerCase();
    }
    return 'common.active'.tr;
  }

  String get ratingSummary {
    return '${volunteerRating.value.toStringAsFixed(1)} • '
        '${volunteerRatingCount.value} '
        '${volunteerRatingCount.value == 1 ? 'common.rating'.tr : 'common.ratings'.tr}';
  }

  Color get roleColor {
    if (isVolunteer) {
      return AppColors.reliefGreen;
    }
    if (isRequestee) {
      return AppColors.steelBlue;
    }
    return AppColors.mediumGray;
  }

  IconData get roleIcon {
    if (isVolunteer) {
      return Icons.volunteer_activism_rounded;
    }
    if (isRequestee) {
      return Icons.support_agent_rounded;
    }
    return Icons.person_rounded;
  }

  String get initials {
    final name = profileName.value.trim();
    if (name.isEmpty) {
      return 'U';
    }
    final words = name.split(RegExp(r'\s+'));
    if (words.length == 1) {
      return words.first.substring(0, 1).toUpperCase();
    }
    return '${words.first.substring(0, 1)}${words.last.substring(0, 1)}'
        .toUpperCase();
  }

  void openPrimaryWorkspace() {
    if (isAdmin) {
      Get.offAllNamed(RouteNames.adminPanel);
      return;
    }
    if (isVolunteer) {
      Get.offAllNamed(RouteNames.startPoint);
      return;
    }
    Get.offAllNamed(RouteNames.requestHome);
  }

  void goHome() {
    openPrimaryWorkspace();
  }

  void goBackOrHome() {
    final navigator = Get.key.currentState;
    if (navigator?.canPop() == true) {
      Get.back();
      return;
    }
    goHome();
  }

  void openAlerts() {
    Get.toNamed(RouteNames.alerts);
  }

  void openCoordination() {
    Get.toNamed(RouteNames.coordination);
  }

  void openCommunities() {
    if (!isVolunteer) {
      ToastHelper.showWarning('profile.warning_communities'.tr);
      return;
    }
    Get.toNamed(RouteNames.communities);
  }

  void signOut() {
    final keepTheme = isSwitching.value;
    StorageHelper().clearSessionData();
    storage.write('theme', keepTheme);
    storage.write('dark_mode', keepTheme);
    _resetLocalProfile();
    Get.offAllNamed(RouteNames.login);
  }

  String _readFirstString(List<String> keys, {String fallback = ''}) {
    for (final key in keys) {
      final value = storage.read(key);
      if (value == null) {
        continue;
      }
      final text = value.toString().trim();
      if (text.isNotEmpty && text != 'null') {
        return text;
      }
    }
    return fallback;
  }

  String _normalizeRole(String value) {
    return value.trim().toLowerCase().replaceAll(' ', '_');
  }

  double? _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  int? _readInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  void _syncPreviewFields() {
    profileName.value = nameController.text.trim();
    profileEmail.value = emailController.text.trim();
    profileLocation.value = locationController.text.trim();
  }

  Future<void> _resolveSavedLocation(String savedLocation) async {
    if (!isGenericLocationLabel(savedLocation)) {
      return;
    }

    try {
      final resolvedName = await resolveLocationLabel(savedLocation);
      if (resolvedName == 'Location unavailable' ||
          resolvedName.trim().isEmpty) {
        return;
      }
      _setResolvedLocation(resolvedName);
    } catch (_) {
      // Keep the resolving label until the user taps Use Current.
    }
  }

  void _setResolvedLocation(String locationName) {
    locationController.text = locationName;
    storage.write('profile_location', locationName);
    storage.write('locationName', locationName);
    _syncPreviewFields();
  }

  void _resetLocalProfile() {
    nameController.text = 'profile.fallback_name'.tr;
    emailController.text = 'user@example.com';
    locationController.text = 'profile.fallback_location'.tr;
    role.value = '';
    verificationStatus.value = '';
    profileImage.value = '';
    _syncPreviewFields();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    nameController.dispose();
    emailController.dispose();
    locationController.dispose();
    super.onClose();
  }
}
