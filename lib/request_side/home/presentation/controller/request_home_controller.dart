import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fyp_source_code/chat/presentation/provider/chat_provider.dart';
import 'package:fyp_source_code/request_side/create_help_request/data/model/help_request.dart';
import 'package:fyp_source_code/request_side/create_help_request/data/repo/help_request_repo.dart';
import 'package:fyp_source_code/request_side/create_help_request/presentation/controller/request_help_controller.dart';
import 'package:fyp_source_code/request_side/create_help_request/presentation/view/request_help_sheet.dart';
import 'package:fyp_source_code/request_side/home/presentation/controller/tracking_controller.dart';
import 'package:fyp_source_code/routing/route_names.dart';
import 'package:fyp_source_code/services/location_services.dart';
import 'package:fyp_source_code/utilities/helpers/toast_helper.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_colors.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

class RequestHomeController extends GetxController {
  final HelpRequestRepo _repo = HelpRequestRepo();
  final TrackingController trackingController = TrackingController();

  final activeRequests = <HelpRequest>[].obs;
  final nearbyVolunteers = <NearbyVolunteer>[].obs;
  final isLoading = false.obs;
  final isSendingSos = false.obs;
  final ratingScore = 5.obs;
  final ratingCommentController = TextEditingController();

  StreamSubscription<Map<String, dynamic>>? _flowSubscription;
  final Set<String> _ratingPrompted = {};

  @override
  void onInit() {
    super.onInit();
    _connectFlowEvents();
    refreshDashboard();
  }

  Future<void> openRequestHelpSheet() async {
    if (!Get.isRegistered<RequestHelpController>()) {
      Get.put(RequestHelpController());
    }

    await Get.bottomSheet(
      const RequestHelpSheet(),
      isScrollControlled: true,
      barrierColor: const Color(0x99000000),
    );

    if (Get.isRegistered<RequestHelpController>()) {
      Get.delete<RequestHelpController>();
    }
    await refreshDashboard();
  }

  Future<void> refreshDashboard() async {
    isLoading.value = true;
    try {
      final position = await getCurrentLocation();
      final active = await _repo.getMyActiveRequests();
      final volunteers = await _repo.getNearbyVolunteers(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      activeRequests.assignAll(active.where(_isRealActiveRequest));
      unawaited(_resolveRequestLocations(activeRequests));
      nearbyVolunteers.assignAll(volunteers);
    } catch (e) {
      ToastHelper.showErrorMessage(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> sendSos() async {
    isSendingSos.value = true;
    try {
      final position = await getCurrentLocation();
      final locationName = await getLocationNameFromCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      await _repo.createSos({
        'title': 'SOS Emergency',
        'latitude': position.latitude,
        'longitude': position.longitude,
        if (locationName != 'Location unavailable')
          'locationName': locationName,
      });
      ToastHelper.showSuccess('SOS sent.');
      await refreshDashboard();
    } catch (e) {
      ToastHelper.showErrorMessage(e);
    } finally {
      isSendingSos.value = false;
    }
  }

  void openCoordination() {
    Get.toNamed(RouteNames.coordination, arguments: {'mode': 'requester'});
  }

  void openRequestChat(HelpRequest request) {
    final volunteerId = request.acceptedBy?.trim() ?? '';
    if (volunteerId.isEmpty) {
      ToastHelper.showWarning('A volunteer has not accepted this request yet.');
      return;
    }

    final provider =
        Get.isRegistered<ChatProvider>()
            ? Get.find<ChatProvider>()
            : Get.put(ChatProvider());
    provider.openConversation(volunteerId);

    final volunteerName = request.acceptedByName?.trim();
    Get.toNamed(
      RouteNames.chatDetail,
      arguments: {
        'userId': volunteerId,
        'userName':
            volunteerName == null || volunteerName.isEmpty
                ? 'Volunteer'
                : volunteerName,
      },
    );
  }

  void openAlerts() {
    Get.toNamed(RouteNames.alerts);
  }

  void openProfile() {
    Get.toNamed(RouteNames.profile);
  }

  void showCommunityBlocked() {
    ToastHelper.showWarning(
      'You are not eligible because you are not a volunteer.',
    );
  }

  bool _isRealActiveRequest(HelpRequest request) {
    final id = request.sId?.trim() ?? '';
    final status = request.status?.toLowerCase().trim() ?? 'active';
    final title = request.displayTitle.toLowerCase();

    if (id.isEmpty) {
      return false;
    }
    if (title.contains('demo') || title.contains('sample')) {
      return false;
    }
    return status == 'active' ||
        status == 'open' ||
        status == 'pending' ||
        status == 'accepted' ||
        status == 'in_progress';
  }

  Future<void> _resolveRequestLocations(List<HelpRequest> requests) async {
    var changed = false;
    for (final request in requests) {
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
      if (resolvedName == 'Location unavailable' ||
          resolvedName.trim().isEmpty) {
        continue;
      }

      request.locationName = resolvedName;
      changed = true;
    }

    if (changed) {
      activeRequests.refresh();
    }
  }

  void _connectFlowEvents() {
    final provider =
        Get.isRegistered<ChatProvider>()
            ? Get.find<ChatProvider>()
            : Get.put(ChatProvider());
    _flowSubscription = provider.flowEventStream.listen((event) {
      final eventName = event['event']?.toString();
      if (eventName == 'help_request_accepted' || eventName == 'new_alert') {
        refreshDashboard();
      }
      if (eventName == 'help_request_accepted') {
        _startTrackingAcceptedRequest(event['data']);
      }
      if (eventName == 'help_request_resolved') {
        refreshDashboard();
        trackingController.stopTracking();
        final requestId = _extractRequestId(event['data']);
        if (requestId != null && !_ratingPrompted.contains(requestId)) {
          _ratingPrompted.add(requestId);
          _showRatingDialog(requestId);
        }
      }
    });
  }

  String? _extractRequestId(dynamic data) {
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final request = map['request'];
      if (request is Map) {
        return request['_id']?.toString() ?? request['id']?.toString();
      }
      return map['_id']?.toString() ??
          map['id']?.toString() ??
          map['requestId']?.toString() ??
          map['helpRequestId']?.toString();
    }
    return null;
  }

  void _showRatingDialog(String requestId) {
    ratingScore.value = 5;
    ratingCommentController.clear();
    Get.defaultDialog(
      title: 'Rate volunteer',
      content: Obx(
        () => Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (index) => IconButton(
                  onPressed: () => ratingScore.value = index + 1,
                  icon: Icon(
                    index < ratingScore.value ? Icons.star : Icons.star_border,
                    color: AppColors.amberOrange,
                  ),
                ),
              ),
            ),
            TextField(
              controller: ratingCommentController,
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'Comment optional'),
            ),
          ],
        ),
      ),
      textConfirm: 'Submit',
      textCancel: 'Later',
      confirmTextColor: Colors.white,
      onConfirm: () => submitRating(requestId),
    );
  }

  void _startTrackingAcceptedRequest(dynamic data) {
    final requestId = _extractRequestId(data);
    if (requestId == null) return;
    final accepted = activeRequests.firstWhereOrNull((r) => r.sId == requestId);
    if (accepted == null) return;
    final loc = accepted.location;
    if (loc?.latitude == null || loc?.longitude == null) return;
    trackingController.startTracking(
      requestId,
      LatLng(loc!.latitude!, loc.longitude!),
    );
  }

  Future<void> submitRating(String requestId) async {
    try {
      await _repo.rateRequest(
        requestId,
        score: ratingScore.value,
        comment:
            ratingCommentController.text.trim().isEmpty
                ? null
                : ratingCommentController.text.trim(),
      );
      Get.back();
      ToastHelper.showSuccess('Rating submitted.');
    } catch (e) {
      ToastHelper.showErrorMessage(e);
    }
  }

  @override
  void onClose() {
    _flowSubscription?.cancel();
    ratingCommentController.dispose();
    super.onClose();
  }
}
