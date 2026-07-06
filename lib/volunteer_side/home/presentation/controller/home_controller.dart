import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fyp_source_code/chat/presentation/provider/chat_provider.dart';
import 'package:fyp_source_code/request_side/create_help_request/data/model/help_request.dart';
import 'package:fyp_source_code/request_side/create_help_request/data/repo/help_request_repo.dart';
import 'package:fyp_source_code/network/api_service.dart';
import 'package:fyp_source_code/routing/route_names.dart';
import 'package:fyp_source_code/services/api_names.dart';
import 'package:fyp_source_code/services/location_services.dart';
import 'package:fyp_source_code/utilities/helpers/toast_helper.dart';
import 'package:fyp_source_code/utilities/reuse_components/storage_helper.dart';
import 'package:get/get.dart';

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
    }
  }

  Future<void> fetchRequests() async {
    isLoading.value = true;
    try {
      final position = await getCurrentLocation();
      _resolveHeaderLocation(position.latitude, position.longitude);
      final list = await _repo.getOpenRequests(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      final visibleRequests = list.where(_isNotOwnRequest).toList();
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
      ToastHelper.showError('Request is not available right now.');
      return;
    }
    if (acceptingRequestIds.contains(id)) {
      return;
    }
    if (!_isNotOwnRequest(request)) {
      ToastHelper.showWarning('You cannot accept your own request.');
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
  }

  @override
  void onClose() {
    _flowSubscription?.cancel();
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
      fullName.value = 'Volunteer User';
    }

    final storedLocation =
        _storage.readData('profile_location') ??
        _storage.readData('city') ??
        _storage.readData('location');
    if (storedLocation is String && storedLocation.trim().isNotEmpty) {
      final location = storedLocation.trim();
      locationName.value =
          isGenericLocationLabel(location)
              ? 'Resolving nearby area...'
              : location;
      if (isGenericLocationLabel(location)) {
        unawaited(_resolveStoredLocation(location));
      }
    } else {
      locationName.value = 'Resolving nearby area...';
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
