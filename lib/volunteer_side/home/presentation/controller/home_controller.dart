import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fyp_source_code/chat/presentation/provider/chat_provider.dart';
import 'package:fyp_source_code/request_side/create_help_request/data/model/help_request.dart';
import 'package:fyp_source_code/request_side/create_help_request/data/repo/help_request_repo.dart';
import 'package:fyp_source_code/network/api_service.dart';
import 'package:fyp_source_code/routing/route_names.dart';
import 'package:fyp_source_code/services/api_names.dart';
import 'package:fyp_source_code/services/location_services.dart';
import 'package:fyp_source_code/utilities/helpers/toast_helper.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_colors.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_text.dart';
import 'package:fyp_source_code/utilities/reuse_components/spacing.dart';
import 'package:fyp_source_code/utilities/reuse_components/storage_helper.dart';
import 'package:fyp_source_code/volunteer_side/map/data/map_repo.dart';
import 'package:get/get.dart';
import 'package:vibration/vibration.dart';

class HomeController extends GetxController with WidgetsBindingObserver {
  final HelpRequestRepo _repo = HelpRequestRepo();
  final StorageHelper _storage = StorageHelper();

  final RxBool isLoading = false.obs;
  final RxList<HelpRequest> requests = RxList();
  final RxSet<String> acceptingRequestIds = <String>{}.obs;
  final RxInt completedCount = 0.obs;
  final RxDouble volunteerRating = 1.0.obs;
  final RxInt volunteerRatingCount = 0.obs;
  final RxString fullName = ''.obs;
  final RxString locationName = ''.obs;
  StreamSubscription<Map<String, dynamic>>? _flowSubscription;
  StreamSubscription<bool>? _connectionSubscription;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _loadUserSummary();
    _connectFlowEvents();
    fetchRequests();
    fetchVolunteerStats();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      fetchVolunteerStats();
      _refreshLocationOnResume();
    }
  }

  /// Keeps the server-side volunteer location fresh so real-time "nearby"
  /// delivery works even when the volunteer never opens the Map tab.
  /// Without this the geo query in the backend excludes the volunteer.
  void _refreshDbLocation(double latitude, double longitude) {
    try {
      MapRepo()
          .updateCurrentLocation(lat: latitude, long: longitude)
          .catchError((_) {});
    } catch (_) {}
  }

  void _refreshLocationOnResume() {
    getQuickPosition().then((position) {
      _refreshDbLocation(position.latitude, position.longitude);
      fetchRequests();
    }).catchError((_) {});
  }

  Future<void> fetchRequests() async {
    isLoading.value = true;
    try {
      final position = await getQuickPosition();
      _resolveHeaderLocation(position.latitude, position.longitude);
      _refreshDbLocation(position.latitude, position.longitude);
      final list = await _repo.getOpenRequests(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      final visibleRequests = list.where(_isNotOwnRequest).toList()
        ..sort((a, b) {
          if (a.isSos != b.isSos) return a.isSos ? -1 : 1;
          return (b.createdAt ?? '').compareTo(a.createdAt ?? '');
        });
      requests.assignAll(visibleRequests);
      unawaited(_resolveRequestLocations(visibleRequests));
    } catch (e) {
      ToastHelper.showErrorMessage(e);
      requests.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> acceptRequest(HelpRequest request) async {
    final id = request.sId;
    if (id == null || id.isEmpty) {
      ToastHelper.showError('volunteer.home.request_unavailable'.tr);
      return;
    }
    if (acceptingRequestIds.contains(id)) {
      return;
    }
    if (!_isNotOwnRequest(request)) {
      ToastHelper.showWarning('volunteer.home.cannot_accept_own'.tr);
      await fetchRequests();
      return;
    }

    acceptingRequestIds.add(id);
    try {
      final accepted = await _repo.acceptRequest(id);
      final activeRequest = _mergeAcceptedRequest(request, accepted);
      Get.toNamed(
        RouteNames.map,
        arguments: {'request': activeRequest.toJson()},
      );
      await fetchRequests();
      await fetchVolunteerStats();
    } catch (e) {
      ToastHelper.showErrorMessage(e);
    } finally {
      acceptingRequestIds.remove(id);
    }
  }

  HelpRequest _mergeAcceptedRequest(
    HelpRequest original,
    HelpRequest accepted,
  ) {
    accepted.sId ??= original.sId;
    accepted.userId ??= original.userId;
    accepted.userName ??= original.userName;
    accepted.title ??= original.title;
    accepted.category ??= original.category;
    accepted.subCategory ??= original.subCategory;
    accepted.description ??= original.description;
    accepted.image ??= original.image;
    if (accepted.mediaUrls.isEmpty) {
      accepted.mediaUrls = original.mediaUrls;
    }
    accepted.requesterImage ??= original.requesterImage;
    accepted.locationName ??= original.locationName;
    accepted.location ??= original.location;
    accepted.status ??= original.status;
    accepted.isSos = accepted.isSos || original.isSos;
    return accepted;
  }

  Future<void> fetchVolunteerStats() async {
    try {
      final statusResponse = await DioHelper().get(
        url: ApiNames.getvolunteerStats,
        isauthorize: true,
      );

      final stats = _extractStatsMap(statusResponse);
      if (stats != null) {
        final completed = _readInt(
          stats['completedRequests'] ??
              stats['completedCount'] ??
              stats['totalHelped'] ??
              stats['resolvedRequests'] ??
              stats['helpRequestsCompleted'],
        );
        if (completed != null) {
          completedCount.value = completed;
        }

        final rating = _readDouble(
          stats['ratingAverage'] ??
              stats['averageRating'] ??
              stats['avgRating'] ??
              stats['rating'],
        );
        if (rating != null) {
          volunteerRating.value = rating;
        }

        final ratingCount = _readInt(
          stats['ratingCount'] ??
              stats['ratingsCount'] ??
              stats['totalRatings'],
        );
        if (ratingCount != null) {
          volunteerRatingCount.value = ratingCount;
        }
      }

      _storage.saveData('volunteer_rating_average', volunteerRating.value);
      _storage.saveData('volunteer_rating_count', volunteerRatingCount.value);
      _storage.saveData('volunteer_completed_count', completedCount.value);
    } catch (e) {
      // Leave the last known stats in place if the endpoint fails.
    }
  }

  void _connectFlowEvents() {
    final provider =
        Get.isRegistered<ChatProvider>()
            ? Get.find<ChatProvider>()
            : Get.put(ChatProvider());

    _flowSubscription = provider.flowEventStream.listen((event) {
      final eventName = event['event']?.toString();
      if (eventName == 'new_help_request') {
        final data = event['data'];
        final isSos =
            data is Map &&
            (data['isSos'] == true || data['escalated'] == true);
        if (isSos) {
          Vibration.vibrate(pattern: [0, 400, 200, 400, 200, 800]);
          SystemSound.play(SystemSoundType.alert);
          _showSosAlertDialog(Map<String, dynamic>.from(data));
        }
        fetchRequests();
        return;
      }
      if (eventName == 'help_request_cancelled') {
        fetchRequests();
        return;
      }
      if (eventName == 'help_request_accepted' ||
          eventName == 'help_request_resolved' ||
          eventName == 'new_alert') {
        fetchRequests();
        if (eventName == 'help_request_accepted' ||
            eventName == 'help_request_resolved') {
          fetchVolunteerStats();
        }
      }
    });

    // Socket came back (first connect or reconnect): recover any request/SOS
    // broadcast that was missed while the channel was down. The location
    // refresh also keeps this volunteer inside the server-side geo query.
    _connectionSubscription = provider.connectionStream.listen((connected) {
      if (connected) {
        _refreshLocationOnResume();
      }
    });
  }

  void _showSosAlertDialog(Map<String, dynamic> data) {
    if (Get.isDialogOpen ?? false) return;
    final request = HelpRequest.fromJson(data);

    Get.dialog(
      PopScope(
        canPop: false,
        child: AlertDialog(
          title: Row(
            children: [
              Icon(Icons.sos, color: AppColors.emergencyRed),
              SizedBox(width: 8),
              Text('request.home.sos'.tr),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                request.displayTitle,
                style: AppTextStyling.title_16M.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: AppSize.sH),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppColors.emergencyRed,
                  ),
                  SizedBox(width: AppSize.xs),
                  Expanded(
                    child: Text(
                      request.displayLocation,
                      style: AppTextStyling.body_12S.copyWith(
                        color: AppColors.mediumGray,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSize.sH),
              Text(
                'volunteer.home.sos_intro'.tr,
                style: AppTextStyling.body_14M.copyWith(
                  color: AppColors.emergencyRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('common.later'.tr),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Get.back();
                acceptRequest(request);
              },
              icon: const Icon(Icons.navigation_rounded, size: 18),
              label: Text('volunteer.home.accept_navigate'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emergencyRed,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
      barrierColor: AppColors.darkGray.withValues(alpha: 0.5),
    );
  }

  @override
  void onClose() {
    _flowSubscription?.cancel();
    _connectionSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  Map<String, dynamic>? _extractStatsMap(dynamic response) {
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
      return response;
    }
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    return null;
  }

  bool _isNotOwnRequest(HelpRequest request) {
    final currentUserId = _storage.readData('userId')?.toString().trim() ?? '';
    final requestUserId = request.userId?.trim() ?? '';
    if (currentUserId.isEmpty || requestUserId.isEmpty) {
      return true;
    }
    return currentUserId != requestUserId;
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

  double? _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  void _loadUserSummary() {
    final storedName =
        _storage.readData('profile_name') ?? _storage.readData('name');

    if (storedName is String && storedName.trim().isNotEmpty) {
      fullName.value = storedName.trim();
    } else {
      fullName.value = 'volunteer.home.default_name'.tr;
    }

    final storedLocation =
        _storage.readData('profile_location') ??
        _storage.readData('city') ??
        _storage.readData('location');
    if (storedLocation is String && storedLocation.trim().isNotEmpty) {
      final location = storedLocation.trim();
      locationName.value =
          isGenericLocationLabel(location)
              ? 'volunteer.home.resolving_area'.tr
              : location;
      if (isGenericLocationLabel(location)) {
        unawaited(_resolveStoredLocation(location));
      }
    } else {
      locationName.value = 'volunteer.home.resolving_area'.tr;
    }

    volunteerRating.value =
        _readDouble(_storage.readData('volunteer_rating_average')) ?? 0;
    volunteerRatingCount.value =
        _readInt(_storage.readData('volunteer_rating_count')) ?? 0;
    completedCount.value =
        _readInt(_storage.readData('volunteer_completed_count')) ??
        completedCount.value;
  }

  void _resolveHeaderLocation(double latitude, double longitude) {
    unawaited(_loadReadableLocationName(latitude, longitude));
  }

  Future<void> _loadReadableLocationName(
    double latitude,
    double longitude,
  ) async {
    final resolvedName = await getLocationNameFromCoordinates(
      latitude: latitude,
      longitude: longitude,
    );
    if (resolvedName.trim().isEmpty || resolvedName == 'Location unavailable') {
      return;
    }
    locationName.value = resolvedName;
    _storage.saveData('profile_location', resolvedName);
  }

  Future<void> _resolveStoredLocation(String value) async {
    final resolvedName = await resolveLocationLabel(value);
    if (resolvedName == 'Location unavailable' || resolvedName.trim().isEmpty) {
      return;
    }
    locationName.value = resolvedName;
    _storage.saveData('profile_location', resolvedName);
    _storage.saveData('locationName', resolvedName);
  }

  Future<void> _resolveRequestLocations(List<HelpRequest> list) async {
    var changed = false;

    for (final request in list) {
      if (request.locationName != null &&
          request.locationName!.trim().isNotEmpty &&
          !isGenericLocationLabel(request.locationName!)) {
        continue;
      }

      final lat = request.location?.latitude;
      final lng = request.location?.longitude;
      if (lat == null || lng == null) {
        continue;
      }

      final resolvedName = await getLocationNameFromCoordinates(
        latitude: lat,
        longitude: lng,
      );
      if (resolvedName.trim().isEmpty ||
          resolvedName == 'Location unavailable') {
        continue;
      }

      request.locationName = resolvedName;
      changed = true;
    }

    if (changed) {
      requests.refresh();
    }
  }
}
