import 'dart:async';
import 'dart:convert';

import 'package:fyp_source_code/chat/presentation/provider/chat_provider.dart';
import 'package:fyp_source_code/request_side/create_help_request/data/model/help_request.dart';
import 'package:fyp_source_code/request_side/create_help_request/data/repo/help_request_repo.dart';
import 'package:fyp_source_code/routing/route_names.dart';
import 'package:fyp_source_code/services/location_services.dart';
import 'package:fyp_source_code/utilities/helpers/toast_helper.dart';
import 'package:fyp_source_code/utilities/reuse_components/storage_helper.dart';
import 'package:fyp_source_code/volunteer_side/home/presentation/controller/home_controller.dart';
import 'package:fyp_source_code/volunteer_side/map/data/map_repo.dart';
import 'package:fyp_source_code/volunteer_side/map/data/map_user_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class MapCntrl extends GetxController {
  static const String _activeRequestStorageKey = 'volunteer_active_request';

  final MapRepo mapRepo = MapRepo();
  final HelpRequestRepo _helpRequestRepo = HelpRequestRepo();
  final StorageHelper _storage = StorageHelper();

  Rx<LatLng?> currentLatLng = Rx<LatLng?>(null);
  final Rx<HelpRequest?> activeRequest = Rx<HelpRequest?>(null);
  final RxList<MapUserModel> mapUsers = <MapUserModel>[].obs;
  final RxBool isCompleting = false.obs;
  final RxBool isCancelling = false.obs;
  final RxString selectedRoleFilter = 'all'.obs;
  final RxList<LatLng> shortestPathPoints = <LatLng>[].obs;
  final RxBool isTracking = false.obs;
  StreamSubscription<Position>? positionStream;
  DateTime? _lastRouteFetchAt;
  LatLng? _lastRouteFetchFrom;
  bool _isFetchingRoute = false;
  bool _isDisposed = false;

  @override
  void onInit() {
    super.onInit();
    _restoreActiveRequest();
    startLocationStream();
  }

  @override
  void onClose() {
    _isDisposed = true;
    positionStream?.cancel();
    super.onClose();
  }

  void startLocationStream() {
    _requestLocationPermission();
  }

  LatLng? get activeRequestLatLng {
    final request = activeRequest.value;
    final lat = request?.location?.latitude;
    final lng = request?.location?.longitude;
    if (lat == null || lng == null) {
      return null;
    }
    return LatLng(lat, lng);
  }

  List<LatLng> get activeRoutePoints {
    if (shortestPathPoints.length >= 2) {
      return shortestPathPoints;
    }
    final current = currentLatLng.value;
    final target = activeRequestLatLng;
    if (current == null || target == null) {
      return <LatLng>[];
    }
    return [current, target];
  }

  double? get activeDistanceKm {
    final current = currentLatLng.value;
    final target = activeRequestLatLng;
    if (current == null || target == null) {
      return null;
    }
    return const Distance().as(LengthUnit.Kilometer, current, target);
  }

  void setActiveRequestFromArguments(dynamic arguments) {
    final request = _readRequestArgument(arguments);
    if (request == null) {
      return;
    }
    setActiveRequest(request);
  }

  void setActiveRequest(HelpRequest request) {
    activeRequest.value = request;
    _storage.saveData(_activeRequestStorageKey, request.toJson());
    _scheduleRouteRefresh(force: true);
  }

  void startLiveTracking() {
    final requestId = activeRequest.value?.sId?.trim();
    if (requestId == null || requestId.isEmpty) return;
    isTracking.value = true;
    try {
      final provider =
          Get.isRegistered<ChatProvider>()
              ? Get.find<ChatProvider>()
              : Get.put(ChatProvider());
      provider.emitStartTracking(requestId);
      ToastHelper.showSuccess('Live tracking started');
    } catch (_) {}
  }

  void stopLiveTracking() {
    final requestId = activeRequest.value?.sId?.trim();
    if (requestId == null || requestId.isEmpty) return;
    isTracking.value = false;
    try {
      final provider =
          Get.isRegistered<ChatProvider>()
              ? Get.find<ChatProvider>()
              : Get.put(ChatProvider());
      provider.emitStopTracking(requestId);
      ToastHelper.showSuccess('Tracking ended');
    } catch (_) {}
  }

  Future<void> completeActiveRequest() async {
    final request = activeRequest.value;
    final id = request?.sId?.trim();
    if (id == null || id.isEmpty) {
      ToastHelper.showError('No active request to complete.');
      return;
    }

    isCompleting.value = true;
    try {
      await _helpRequestRepo.resolveRequest(id);
      _clearActiveRequest();
      _refreshVolunteerDashboard(completed: true);
      ToastHelper.showSuccess('Request completed.');
    } catch (e) {
      ToastHelper.showErrorMessage(e);
    } finally {
      isCompleting.value = false;
    }
  }

  Future<void> cancelActiveRequest() async {
    final request = activeRequest.value;
    final id = request?.sId?.trim();
    if (id == null || id.isEmpty) {
      ToastHelper.showError('No active request to cancel.');
      return;
    }

    isCancelling.value = true;
    try {
      await _helpRequestRepo.releaseRequest(id);
      _clearActiveRequest();
      _refreshVolunteerDashboard();
      ToastHelper.showSuccess('Request cancelled.');
    } catch (e) {
      ToastHelper.showErrorMessage(e);
    } finally {
      isCancelling.value = false;
    }
  }

  void openActiveRequestChat() {
    final request = activeRequest.value;
    final userId = request?.userId?.trim();
    if (userId == null || userId.isEmpty) {
      ToastHelper.showError('Chat is not available for this request.');
      return;
    }

    Get.toNamed(
      RouteNames.chatDetail,
      arguments: {
        'userId': userId,
        'userName': request?.userName ?? 'Requestee',
      },
    );
  }

  /// Request location permission from user
  Future<void> _requestLocationPermission() async {
    try {
      // Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        // Request permission
        permission = await Geolocator.requestPermission();
        print('Location permission requested: $permission');
      }

      if (permission == LocationPermission.deniedForever) {
        print(' Location permission denied forever! Opening app settings...');
        ToastHelper.showWarning(
          'Location permission is required to refresh the map.',
        );
        await Geolocator.openLocationSettings();
        return;
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        print('Location permission granted! Fetching fresh location...');

        Position pos = await getCurrentLocation();
        currentLatLng.value = LatLng(pos.latitude, pos.longitude);
        await mapRepo.updateCurrentLocation(
          lat: pos.latitude,
          long: pos.longitude,
        );
        await _scheduleRouteRefresh(force: true);
        await fetchMapUsers();
        _startPositionStream();
      }
    } catch (e) {
      print('Error requesting location permission: $e');
      ToastHelper.showErrorMessage(e);
    }
  }

  /// Start receiving continuous position updates
  void _startPositionStream() {
    positionStream?.cancel();
    positionStream = Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5,
        forceLocationManager: false,
      ),
    ).listen(
      (Position pos) async {
        if (_isDisposed) {
          return;
        }
        // Filter out inaccurate readings
        if (pos.accuracy > 50) {
          print('⚠️ Low accuracy (${pos.accuracy}m) - skipping');
          return;
        }

        print(
          '📍 Stream device location: ${pos.latitude}, ${pos.longitude}, Accuracy: ${pos.accuracy}m',
        );

        // Project GPS onto the existing route so icon follows the road path
        final rawPos = LatLng(pos.latitude, pos.longitude);
        if (activeRequest.value != null && shortestPathPoints.length >= 2) {
          final projected = projectOnRoute(rawPos, shortestPathPoints);
          currentLatLng.value = projected.key;
        } else {
          currentLatLng.value = rawPos;
        }

        if (activeRequest.value != null) {
          await _scheduleRouteRefresh();
        }

        if (!_isDisposed) {
          final currentPosition = LatLng(pos.latitude, pos.longitude);
          Future.microtask(() async {
            try {
              await mapRepo.updateCurrentLocation(
                lat: pos.latitude,
                long: pos.longitude,
              );
              await fetchMapUsers();
            } catch (e) {
              print(" Error sending location: $e");
            }
          });

          if (isTracking.value &&
              activeRequest.value?.sId != null &&
              activeRequest.value!.sId!.trim().isNotEmpty) {
            try {
              final provider =
                  Get.isRegistered<ChatProvider>()
                      ? Get.find<ChatProvider>()
                      : Get.put(ChatProvider());
              provider.emitLocationUpdate(
                latitude: pos.latitude,
                longitude: pos.longitude,
                requestId: activeRequest.value!.sId!.trim(),
              );
            } catch (_) {}
          }
        }
      },
      onError: (e) {
        print("❌ GPS Stream Error: $e, restarting in 3s...");
        if (!_isDisposed) {
          Future.delayed(const Duration(seconds: 3), _startPositionStream);
        }
      },
      cancelOnError: false,
    );
  }

  Future<void> fetchMapUsers() async {
    final latLng = currentLatLng.value;
    if (latLng == null) {
      return;
    }
    try {
      final users = await mapRepo.getMapUsers(
        lat: latLng.latitude,
        lng: latLng.longitude,
        role:
            selectedRoleFilter.value == 'all' ? null : selectedRoleFilter.value,
      );
      mapUsers.assignAll(users);
    } catch (e) {
      print('Error fetching map users: $e');
    }
  }

  Future<void> setRoleFilter(String role) async {
    selectedRoleFilter.value = role;
    await fetchMapUsers();
  }

  void _restoreActiveRequest() {
    final request = _readRequestArgument(
      _storage.readData(_activeRequestStorageKey),
    );
    if (request == null) {
      return;
    }
    activeRequest.value = request;
    _scheduleRouteRefresh(force: true);
  }

  HelpRequest? _readRequestArgument(dynamic value) {
    dynamic raw = value;
    if (value is Map) {
      raw = value['request'] ?? value['helpRequest'] ?? value;
    }

    if (raw is HelpRequest) {
      return raw;
    }

    if (raw is Map) {
      return HelpRequest.fromJson(Map<String, dynamic>.from(raw));
    }

    return null;
  }

  void _clearActiveRequest() {
    activeRequest.value = null;
    shortestPathPoints.clear();
    _storage.removeData(_activeRequestStorageKey);
  }

  //Fetch dobra karna chaiye ya nahi

  Future<void> _scheduleRouteRefresh({bool force = false}) async {
    final from = currentLatLng.value;
    final to = activeRequestLatLng;
    if (from == null || to == null) {
      shortestPathPoints.clear();
      return;
    }
    if (_isFetchingRoute) {
      return;
    }

    if (!force) {
      final now = DateTime.now();
      final recentFetch =
          _lastRouteFetchAt != null &&
          now.difference(_lastRouteFetchAt!) < const Duration(seconds: 8);
      final movedEnough =
          _lastRouteFetchFrom != null &&
          const Distance().as(LengthUnit.Meter, _lastRouteFetchFrom!, from) >
              20;
      if (recentFetch && !movedEnough) {
        return;
      }
    }

    _isFetchingRoute = true;
    try {
      final route = await _fetchShortestPath(from: from, to: to);
      // Guard: if request was cancelled during fetch, discard result
      if (activeRequest.value == null || currentLatLng.value == null) {
        shortestPathPoints.clear();
        return;
      }
      if (route.length >= 2) {
        shortestPathPoints.assignAll(route);
      } else {
        shortestPathPoints.assignAll([from, to]);
      }
      _lastRouteFetchAt = DateTime.now();
      _lastRouteFetchFrom = from;
    } catch (_) {
      if (activeRequest.value == null) {
        shortestPathPoints.clear();
        return;
      }
      shortestPathPoints.assignAll([from, to]);
    } finally {
      _isFetchingRoute = false;
    }
  }

  //Shortest driving path api through osm

  Future<List<LatLng>> _fetchShortestPath({
    required LatLng from,
    required LatLng to,
  }) async {
    final uri = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
      '?overview=full&geometries=geojson',
    );
    final response = await http
        .get(
          uri,
          headers: const {
            'Accept': 'application/json',
            'User-Agent': 'WeHelpApp/1.0 route-path',
          },
        )
        .timeout(const Duration(seconds: 8));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to fetch route');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected route response');
    }

    final routes = decoded['routes'];
    if (routes is! List || routes.isEmpty) {
      throw Exception('No routes found');
    }

    final route = routes.first;
    if (route is! Map<String, dynamic>) {
      throw Exception('Invalid route');
    }

    final geometry = route['geometry'];
    if (geometry is! Map<String, dynamic>) {
      throw Exception('Invalid route geometry');
    }

    final coordinates = geometry['coordinates'];
    if (coordinates is! List) {
      throw Exception('Invalid route coordinates');
    }

    final points = <LatLng>[];
    for (final coordinate in coordinates) {
      if (coordinate is! List || coordinate.length < 2) {
        continue;
      }
      final lng = _readDouble(coordinate[0]);
      final lat = _readDouble(coordinate[1]);
      if (lat == null || lng == null) {
        continue;
      }
      points.add(LatLng(lat, lng));
    }

    return points;
  }
  // ---- Route path helpers ----

  /// Project a point onto a polyline and return the interpolated position
  /// along with the cumulative distance (in meters) from the start.
  static MapEntry<LatLng, double> projectOnRoute(
    LatLng point,
    List<LatLng> polyline,
  ) {
    if (polyline.length < 2) return MapEntry(point, 0);

    int segIdx = 0;
    double segT = 0.0;
    double minDistSq = double.infinity;

    for (int i = 0; i < polyline.length - 1; i++) {
      final a = polyline[i];
      final b = polyline[i + 1];
      final dx = b.longitude - a.longitude;
      final dy = b.latitude - a.latitude;
      final lenSq = dx * dx + dy * dy;

      double t;
      if (lenSq == 0) {
        t = 0;
      } else {
        t =
            ((point.longitude - a.longitude) * dx +
                (point.latitude - a.latitude) * dy) /
            lenSq;
        t = t.clamp(0.0, 1.0);
      }

      final projLng = a.longitude + t * dx;
      final projLat = a.latitude + t * dy;
      final dLng = point.longitude - projLng;
      final dLat = point.latitude - projLat;
      final distSq = dLng * dLng + dLat * dLat;

      if (distSq < minDistSq) {
        minDistSq = distSq;
        segIdx = i;
        segT = t;
      }
    }

    double dist = 0;
    for (int i = 0; i < segIdx; i++) {
      dist += const Distance().as(
        LengthUnit.Meter,
        polyline[i],
        polyline[i + 1],
      );
    }
    final segDist = const Distance().as(
      LengthUnit.Meter,
      polyline[segIdx],
      polyline[segIdx + 1],
    );
    dist += segDist * segT;

    final projLng2 =
        polyline[segIdx].longitude +
        (polyline[segIdx + 1].longitude - polyline[segIdx].longitude) * segT;
    final projLat2 =
        polyline[segIdx].latitude +
        (polyline[segIdx + 1].latitude - polyline[segIdx].latitude) * segT;

    return MapEntry(LatLng(projLat2, projLng2), dist);
  }

  /// Get a point along a polyline at a given cumulative distance from start.
  static LatLng pointAtDistOnRoute(List<LatLng> polyline, double targetDist) {
    if (polyline.length < 2) {
      return polyline.isNotEmpty ? polyline.first : LatLng(0, 0);
    }
    if (targetDist <= 0) return polyline.first;

    double accumulated = 0;
    for (int i = 0; i < polyline.length - 1; i++) {
      final segDist = const Distance().as(
        LengthUnit.Meter,
        polyline[i],
        polyline[i + 1],
      );
      if (accumulated + segDist >= targetDist) {
        final t = segDist > 0 ? (targetDist - accumulated) / segDist : 0;
        return LatLng(
          polyline[i].latitude +
              (polyline[i + 1].latitude - polyline[i].latitude) * t,
          polyline[i].longitude +
              (polyline[i + 1].longitude - polyline[i].longitude) * t,
        );
      }
      accumulated += segDist;
    }
    return polyline.last;
  }

  /// Truncate a polyline to only keep points from the given distance onward.
  static List<LatLng> truncatePolylineFromDist(
    List<LatLng> polyline,
    double fromDist,
  ) {
    if (polyline.length < 2 || fromDist <= 0) return List.from(polyline);

    final result = <LatLng>[];
    double accumulated = 0;
    bool added = false;

    for (int i = 0; i < polyline.length - 1; i++) {
      final segDist = const Distance().as(
        LengthUnit.Meter,
        polyline[i],
        polyline[i + 1],
      );
      if (accumulated + segDist >= fromDist && !added) {
        final t = segDist > 0 ? (fromDist - accumulated) / segDist : 0;
        result.add(
          LatLng(
            polyline[i].latitude +
                (polyline[i + 1].latitude - polyline[i].latitude) * t,
            polyline[i].longitude +
                (polyline[i + 1].longitude - polyline[i].longitude) * t,
          ),
        );
        added = true;
      }
      if (added) {
        result.add(polyline[i + 1]);
      }
      accumulated += segDist;
    }

    if (result.isEmpty && polyline.isNotEmpty) result.add(polyline.last);
    return result;
  }

  //completion pay count++ karta hai
  void _refreshVolunteerDashboard({bool completed = false}) {
    if (!Get.isRegistered<HomeController>()) {
      return;
    }

    final homeController = Get.find<HomeController>();
    if (completed) {
      homeController.completedCount.value++;
    }
    unawaited(homeController.fetchRequests());
    unawaited(homeController.fetchVolunteerStats());
  }
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
