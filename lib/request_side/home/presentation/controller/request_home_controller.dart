import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fyp_source_code/chat/presentation/provider/chat_provider.dart';
import 'package:fyp_source_code/network/exceptions.dart';
import 'package:fyp_source_code/request_side/create_help_request/data/model/help_request.dart';
import 'package:fyp_source_code/request_side/create_help_request/data/repo/help_request_repo.dart';
import 'package:fyp_source_code/request_side/create_help_request/presentation/controller/request_help_controller.dart';
import 'package:fyp_source_code/request_side/create_help_request/presentation/view/request_help_sheet.dart';
import 'package:fyp_source_code/request_side/home/presentation/controller/tracking_controller.dart';
import 'package:fyp_source_code/routing/route_names.dart';
import 'package:fyp_source_code/services/helpline_service.dart';
import 'package:fyp_source_code/services/location_services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:fyp_source_code/utilities/helpers/toast_helper.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_colors.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_text.dart';
import 'package:fyp_source_code/utilities/reuse_components/helplines.dart';
import 'package:fyp_source_code/utilities/reuse_components/spacing.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:vibration/vibration.dart';

class RequestHomeController extends GetxController
    with WidgetsBindingObserver {
  final HelpRequestRepo _repo = HelpRequestRepo();

  /// Single shared tracking instance (registered permanent so it survives
  /// screen navigation and is reused across controllers/screens).
  TrackingController get trackingController {
    if (!Get.isRegistered<TrackingController>()) {
      Get.put(TrackingController(), permanent: true);
    }
    return Get.find<TrackingController>();
  }

  final activeRequests = <HelpRequest>[].obs;
  final nearbyVolunteers = <NearbyVolunteer>[].obs;
  final isLoading = false.obs;
  final isSendingSos = false.obs;
  final ratingScore = 5.obs;
  final ratingCommentController = TextEditingController();

  StreamSubscription<Map<String, dynamic>>? _flowSubscription;
  final Set<String> _ratingPrompted = {};

  // ── Sender-side SOS alerting ────────────────────────────────────────
  /// Repeat tone cadence while an SOS is open (every 60s).
  static const sosReminderInterval = Duration(seconds: 60);

  /// When not null, ringing is paused until this instant (snooze).
  DateTime? _snoozeUntil;
  Timer? _sosReminderTimer;
  Timer? _snoozeResumeTimer;

  /// Per-send confirmation guard so an accepted-SOS alert only fires once
  /// per request (a repeated convenience so every new escalation rings).
  final Set<String> _ringingRequestIds = {};

  bool get isSosSnoozed => _snoozeUntil != null && DateTime.now().isBefore(_snoozeUntil!);

  int get snoozeRemainingSeconds {
    if (_snoozeUntil == null) return 0;
    final diff = _snoozeUntil!.difference(DateTime.now());
    return diff.isNegative ? 0 : diff.inSeconds;
  }

  static const int maxLocationResolutionsPerRefresh = 4;
  final Set<String> _resolvedLocationIds = {};

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _connectFlowEvents();
    refreshDashboard();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refreshDashboard();
    }
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
    // Only the first load needs a full shimmer; later refreshes (pull-to-
    // refresh, flow events) keep the existing data visible while updating.
    if (activeRequests.isEmpty && nearbyVolunteers.isEmpty) {
      isLoading.value = true;
    }
    try {
      final activeFuture = _repo.getMyActiveRequests();

      Position position;
      try {
        position = await getQuickPosition();
      } catch (_) {
        final last = getCachedKnownPosition();
        position = last ?? await getCurrentLocation(useCacheFirst: true);
      }

      final active = await activeFuture;
      final volunteers = await _repo.getNearbyVolunteers(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      activeRequests.assignAll(active.where(_isRealActiveRequest));
      _reconcileAcceptedTracking();
      unawaited(_resolveRequestLocations(activeRequests));
      nearbyVolunteers.assignAll(volunteers);
    } catch (e) {
      ToastHelper.showErrorMessage(e);
    } finally {
      isLoading.value = false;
      _syncSosReminder();
    }
  }

  Future<void> sendSos() async {
    if (activeRequests.any(_isActiveSos)) {
      ToastHelper.showWarning('sos.already_active'.tr);
      return;
    }

    isSendingSos.value = true;
    try {
      // Strict budget: SOS must fire within ~2s. Fall back to any recent
      // cached position rather than waiting for a fresh GPS fix.
      Position? position;
      try {
        position = await getQuickPosition().timeout(
          const Duration(seconds: 2),
        );
      } catch (_) {
        position = getCachedKnownPosition();
      }
      position ??= await Future<Position?>.value(
        getCurrentLocation(useCacheFirst: true),
      ).timeout(
        const Duration(seconds: 2),
        onTimeout: () => getCachedKnownPosition(),
      );
      if (position == null) {
        throw FetchDataExceptions('Unable to determine your location.');
      }

      // Resolve a readable place name best-effort within a tiny budget so the
      // SOS fires immediately even if geocoding is slow.
      final locationName = await getLocationNameFromCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
      ).timeout(
        const Duration(milliseconds: 1500),
        onTimeout: () => 'Location unavailable',
      );

      final body = {
        'title': 'SOS Emergency',
        'latitude': position.latitude,
        'longitude': position.longitude,
        if (locationName != 'Location unavailable') 'locationName': locationName,
      };

      SosResult result;
      try {
        result = await _repo.createSos(body);
      } on DioException catch (e) {
        // One automatic retry on transient network issues.
        if (_isRetryable(e)) {
          await Future.delayed(const Duration(seconds: 1));
          result = await _repo.createSos(body);
        } else {
          rethrow;
        }
      }

      if (result.alreadyActive) {
        ToastHelper.showWarning('sos.already_active'.tr);
        await refreshDashboard();
        return;
      }
      // Ring immediately: the SOS is now live on your phone.
      ringSosAlarm();
      await _showSosSentDialog(notified: result.notified);
      await refreshDashboard();
    } catch (e) {
      ToastHelper.showErrorMessage(e);
    } finally {
      isSendingSos.value = false;
    }
  }

  bool _isRetryable(Object error) {
    if (error is! DioException) return false;
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError;
  }

  bool _isActiveSos(HelpRequest request) {
    if (!request.isSos) return false;
    final status = request.status?.toLowerCase().trim() ?? '';
    return status == 'open' ||
        status == 'active' ||
        status == 'pending' ||
        status == 'accepted' ||
        status == 'in_progress';
  }

  Future<void> cancelActiveSos(HelpRequest request) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.sos, color: AppColors.emergencyRed),
            SizedBox(width: 8),
            Text('sos.cancel.title'.tr),
          ],
        ),
        content: Text('sos.cancel.message'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('sos.cancel.keep'.tr),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emergencyRed,
              foregroundColor: Colors.white,
            ),
            child: Text('sos.cancel.confirm'.tr),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _repo.cancelSos();
      ToastHelper.showSuccess('sos.cancel'.tr);
      await refreshDashboard();
    } catch (e) {
      ToastHelper.showErrorMessage(e);
    }
  }

  Future<void> _showSosSentDialog({int notified = 0}) async {
    final confirmed = await Get.dialog<bool>(
      PopScope(
        canPop: false,
        child: AlertDialog(
          title: Row(
            children: [
              Icon(Icons.sos, color: AppColors.emergencyRed),
              SizedBox(width: 8),
              Text('sos.sent.title'.tr),
            ],
          ),
          content: Text(
            notified > 0
                ? 'sos.sent.message_count'.trParams({'count': '$notified'})
                : 'sos.sent.message'.tr,
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text('common.done'.tr),
            ),
            ElevatedButton.icon(
              onPressed: () => Get.back(result: true),
              icon: const Icon(Icons.phone_in_talk_rounded, size: 18),
              label: Text('sos.call_helpline'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emergencyRed,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      openHelplineSheet();
    }
  }

  void openHelplineSheet() {
    final theme = Get.context?.theme;
    Get.bottomSheet(
      Material(
        color: theme?.colorScheme.surface ?? Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSize.m),
                  child: Center(
                    child: Text(
                      'sos.helplines.title'.tr,
                      style: AppTextStyling.title_16M.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1),
                ...kHelplines.map(
                  (helpline) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.emergencyRed.withValues(
                        alpha: 0.10,
                      ),
                      child: Icon(
                        Icons.call,
                        color: AppColors.emergencyRed,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      helpline.label,
                      style: AppTextStyling.body_14M.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      helpline.number,
                      style: AppTextStyling.body_12S.copyWith(
                        color: AppColors.mediumGray,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.dialpad_rounded,
                      color: AppColors.steelBlue,
                    ),
                    onTap: () {
                      Get.back();
                      HelplineService.call(helpline.number);
                    },
                  ),
                ),
                SizedBox(height: AppSize.mH),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
      barrierColor: const Color(0x99000000),
    );
  }

  void openCoordination() {
    Get.toNamed(RouteNames.coordination, arguments: {'mode': 'requester'});
  }

  void openRequestChat(HelpRequest request) {
    final volunteerId = request.acceptedBy?.trim() ?? '';
    if (volunteerId.isEmpty) {
      ToastHelper.showWarning('sos.chat_not_accepted'.tr);
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
      'sos.not_volunteer'.tr,
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
    var resolvedCount = 0;
    for (final request in requests) {
      final id = request.sId;
      if (id == null || id.trim().isEmpty) {
        continue;
      }

      // Cached result for this request id → skip entirely.
      if (_resolvedLocationIds.contains(id)) {
        continue;
      }
      if (request.locationName != null &&
          request.locationName!.trim().isNotEmpty &&
          !isGenericLocationLabel(request.locationName!)) {
        _resolvedLocationIds.add(id);
        continue;
      }

      // Cap the work per refresh so a bus of coordinate-only requests cannot
      // pin the UI thread for seconds.
      if (resolvedCount >= maxLocationResolutionsPerRefresh) {
        break;
      }

      final lat = request.location?.latitude;
      final lng = request.location?.longitude;
      if (lat == null || lng == null) {
        _resolvedLocationIds.add(id);
        continue;
      }

      final resolvedName = await getLocationNameFromCoordinates(
        latitude: lat,
        longitude: lng,
      ).timeout(
        const Duration(seconds: 4),
        onTimeout: () => 'Location unavailable',
      );
      if (resolvedName == 'Location unavailable' ||
          resolvedName.trim().isEmpty) {
        _resolvedLocationIds.add(id);
        continue;
      }

      request.locationName = resolvedName;
      _resolvedLocationIds.add(id);
      resolvedCount += 1;
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
    _flowSubscription = provider.flowEventStream.listen((event) async {
      final eventName = event['event']?.toString();
      if (eventName == 'help_request_accepted' ||
          eventName == 'new_alert' ||
          eventName == 'help_request_cancelled' ||
          eventName == 'sos_escalated') {
        await refreshDashboard();
      }
      if (eventName == 'help_request_accepted') {
        // A volunteer is on the way — ring so the user notices immediately
        // (once per request; escalation events ring on every level).
        final requestId = _extractRequestId(event['data']);
        if (requestId != null && !_ringingRequestIds.contains(requestId)) {
          _ringingRequestIds.add(requestId);
          ringSosAlarm();
        }
        await _startTrackingAcceptedRequest(event['data']);
      }
      if (eventName == 'sos_escalated') {
        ringSosAlarm();
        final data = event['data'];
        if (data is Map && Get.context != null) {
          final radiusKm = data['radiusKm']?.toString();
          final minutes = data['minutes']?.toString();
          final msg = radiusKm != null && minutes != null
              ? 'sos.escalated_radius'.trParams({
                  'radius': radiusKm,
                  'minutes': minutes,
                })
              : 'sos.escalated'.tr;
          ToastHelper.showWarning(msg);
        }
      }
      if (eventName == 'help_request_resolved') {
        await refreshDashboard();
        trackingController.stopTracking();
        final requestId = _extractRequestId(event['data']);
        _ringingRequestIds.remove(requestId);
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
      title: 'sos.rating.title'.tr,
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
              decoration: InputDecoration(
                hintText: 'sos.rating_comment'.tr,
              ),
            ),
          ],
        ),
      ),
      textConfirm: 'common.submit'.tr,
      textCancel: 'common.later'.tr,
      confirmTextColor: Colors.white,
      onConfirm: () => submitRating(requestId),
    );
  }

  Future<void> _startTrackingAcceptedRequest(dynamic data) async {
    final requestId = _extractRequestId(data);
    if (requestId == null || requestId.isEmpty) return;

    // Already tracking this request - don't restart.
    if (trackingController.isTracking.value &&
        trackingController.currentRequestId == requestId) {
      return;
    }

    _startTrackingForRequest(requestId);
    if (trackingController.currentRequestId != requestId) {
      // The dashboard refresh may not have completed yet - retry once.
      await refreshDashboard();
      _startTrackingForRequest(requestId);
    }
  }

  /// Start tracking a request that is already present in the dashboard list.
  /// No-op when the request is unknown or already being tracked.
  void _startTrackingForRequest(String requestId) {
    if (requestId.isEmpty) return;
    if (trackingController.isTracking.value &&
        trackingController.currentRequestId == requestId) {
      return;
    }
    final accepted = activeRequests.firstWhereOrNull((r) => r.sId == requestId);
    if (accepted == null) return;
    final loc = accepted.location;
    if (loc?.latitude == null || loc?.longitude == null) return;
    trackingController.startTracking(
      requestId,
      LatLng(loc!.latitude!, loc.longitude!),
    );
  }

  /// Reconcile the dashboard list with the live tracking session so an
  /// accepted request recovers tracking even when the accept event was
  /// missed (socket gap, app opened/resumed after acceptance).
  ///
  /// The list is newest-first, so the most recent accepted request wins.
  /// An already-running session is kept as long as its request is still
  /// accepted; a stale session (request resolved) is replaced.
  void _reconcileAcceptedTracking() {
    final acceptedIds = <String>[];
    for (final request in activeRequests) {
      final status = request.status?.toLowerCase().trim() ?? '';
      if (status != 'accepted') continue;
      final requestId = request.sId;
      if (requestId == null || requestId.trim().isEmpty) continue;
      acceptedIds.add(requestId);
    }
    if (acceptedIds.isEmpty) return;

    final current = trackingController.currentRequestId;
    if (trackingController.isTracking.value &&
        current != null &&
        acceptedIds.contains(current)) {
      // The active session still covers an accepted request - keep it.
      return;
    }
    unawaited(_startTrackingAcceptedRequest({'requestId': acceptedIds.first}));
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
      ToastHelper.showSuccess('sos.rating_submitted'.tr);
    } catch (e) {
      ToastHelper.showErrorMessage(e);
    }
  }

  // ── Sender-side SOS ringing / snooze ────────────────────────────────

  /// Vibrate + play the alert sound.
  void ringSosAlarm() {
    Vibration.vibrate(pattern: [0, 400, 200, 400, 200, 800]);
    SystemSound.play(SystemSoundType.alert);
  }

  /// Start/stop the periodic reminder while an SOS is open. Called after
  /// every dashboard refresh so the cadence tracks the current state.
  void _syncSosReminder() {
    final hasOpenSos = activeRequests.any((r) => r.isSos && _isActiveSos(r));
    final shouldRing = hasOpenSos && !isSosSnoozed;

    if (shouldRing) {
      _sosReminderTimer ??= Timer.periodic(
        sosReminderInterval,
        (_) => ringSosAlarm(),
      );
    } else {
      _sosReminderTimer?.cancel();
      _sosReminderTimer = null;
    }
  }

  /// Human-readable remaining snooze, e.g. "12 min".
  String get snoozeLabel {
    final secs = snoozeRemainingSeconds;
    if (secs <= 0) return '0 min';
    final m = secs ~/ 60;
    final s = secs % 60;
    return s == 0 ? '$m min' : '${m}m ${s}s';
  }

  /// Pause ringing for the given duration.
  void snoozeSos(Duration duration) {
    _snoozeUntil = DateTime.now().add(duration);
    _syncSosReminder();
    _snoozeResumeTimer?.cancel();
    _snoozeResumeTimer = Timer(duration, () {
      _snoozeUntil = null;
      // Re-arm the cadence immediately so the user knows ringing resumed.
      ringSosAlarm();
      _syncSosReminder();
    });
  }

  /// Cancel the snooze and resume ringing now.
  void clearSnooze() {
    _snoozeResumeTimer?.cancel();
    _snoozeUntil = null;
    _syncSosReminder();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _flowSubscription?.cancel();
    _sosReminderTimer?.cancel();
    _snoozeResumeTimer?.cancel();
    ratingCommentController.dispose();
    super.onClose();
  }
}

