import 'dart:async';
import 'dart:convert';

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
  StreamSubscription<Position>? positionStream;
  DateTime? _lastRouteFetchAt;
  LatLng? _lastRouteFetchFrom;
  bool _isFetchingRoute = false;

  @override
  void onInit() {
    super.onInit();
    _restoreActiveRequest();
    startLocationStream();
  }

  @override
  void onClose() {
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
        timeLimit: Duration(seconds: 10),
      ),
    ).listen(
      (Position pos) async {
        // Filter out inaccurate readings
        if (pos.accuracy > 50) {
          print('⚠️ Low accuracy (${pos.accuracy}m) - skipping');
          return;
        }

        print(
          '📍 Stream device location: ${pos.latitude}, ${pos.longitude}, Accuracy: ${pos.accuracy}m',
        );
        currentLatLng.value = LatLng(pos.latitude, pos.longitude);
        await _scheduleRouteRefresh();

        Future.microtask(() async {
          try {
            await mapRepo.updateCurrentLocation(
              lat: pos.latitude,
              long: pos.longitude,
            );
            await fetchMapUsers();
            print(
              "✅ Location sent to backend: ${pos.latitude}, ${pos.longitude}",
            );
          } catch (e) {
            print(" Error sending location: $e");
          }
        });
      },
      onError: (e) {
        print("❌ GPS Stream Error: $e");
      },
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
          now.difference(_lastRouteFetchAt!) < const Duration(seconds: 12);
      final movedEnough =
          _lastRouteFetchFrom != null &&
          const Distance().as(LengthUnit.Meter, _lastRouteFetchFrom!, from) > 35;
      if (recentFetch && !movedEnough) {
        return;
      }
    }

    _isFetchingRoute = true;
    try {
      final route = await _fetchShortestPath(from: from, to: to);
      if (route.length >= 2) {
        shortestPathPoints.assignAll(route);
      } else {
        shortestPathPoints.assignAll([from, to]);
      }
      _lastRouteFetchAt = DateTime.now();
      _lastRouteFetchFrom = from;
    } catch (_) {
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
