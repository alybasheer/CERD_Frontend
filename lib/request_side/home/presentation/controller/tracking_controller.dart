import 'dart:async';
import 'dart:convert';

import 'package:fyp_source_code/chat/presentation/provider/chat_provider.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class TrackingController extends GetxController {
  final Rx<LatLng?> volunteerPosition = Rx<LatLng?>(null);
  final RxString trackingStatus = 'idle'.obs;
  final Rx<double?> remainingDistanceKm = Rx<double?>(null);
  final Rx<int?> remainingMinutes = Rx<int?>(null);
  final RxList<LatLng> routePoints = <LatLng>[].obs;
  final RxList<LatLng> traveledPoints = <LatLng>[].obs;
  final RxBool isTracking = false.obs;

  String? _currentRequestId;
  final Rx<LatLng?> destination = Rx<LatLng?>(null);
  StreamSubscription<Map<String, dynamic>>? _locationSub;
  StreamSubscription<Map<String, dynamic>>? _statusSub;
  bool _isFetchingRoute = false;
  DateTime? _lastRouteFetchAt;
  LatLng? _lastRouteRefetchFrom;

  static const double _refetchDistanceMeters = 60;
  static const Duration _refetchInterval = Duration(seconds: 15);

  String? get currentRequestId => _currentRequestId;

  static double? _readDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  void _processLocationEvent(Map<String, dynamic> data, String requestId) {
    if (data['requestId']?.toString() != requestId) return;
    final lat = _readDouble(data['latitude']);
    final lng = _readDouble(data['longitude']);
    if (lat == null || lng == null) return;

    final pos = LatLng(lat, lng);

    final destination = this.destination.value;
    if (destination == null) return;

    if (routePoints.length < 2) {
      volunteerPosition.value = pos;
      _fetchFullRoute(pos, destination);
    } else {
      _updateRouteProgress(pos);
    }
    _updateRemainingDistance(pos);
  }

  @override
  void onClose() {
    _locationSub?.cancel();
    _statusSub?.cancel();
    super.onClose();
  }

  void startTracking(String requestId, LatLng destination) {
    _currentRequestId = requestId;
    this.destination.value = destination;
    isTracking.value = true;
    trackingStatus.value = 'en_route';
    routePoints.clear();
    traveledPoints.clear();
    volunteerPosition.value = null;
    remainingDistanceKm.value = null;
    remainingMinutes.value = null;
    _isFetchingRoute = false;
    _lastRouteFetchAt = null;
    _lastRouteRefetchFrom = null;

    final provider =
        Get.isRegistered<ChatProvider>()
            ? Get.find<ChatProvider>()
            : Get.put(ChatProvider());

    _locationSub?.cancel();
    _locationSub = provider.volunteerLocationStream.listen((data) {
      _processLocationEvent(data, requestId);
    });

    // Replay the most recent buffered location for this request
    // so we don't miss events that arrived before the subscription.
    final buffered = provider.getBufferedVolLocations();
    for (final event in buffered) {
      if (event['requestId']?.toString() == requestId) {
        _processLocationEvent(event, requestId);
      }
    }

    _statusSub?.cancel();
    _statusSub = provider.trackingStatusStream.listen((data) {
      if (data['requestId']?.toString() != requestId) return;
      final status = data['status']?.toString() ?? 'idle';
      print('📍 [TrackingStatus] $status for $requestId');
      trackingStatus.value = status;
    });
  }

  void stopTracking() {
    _locationSub?.cancel();
    _statusSub?.cancel();
    isTracking.value = false;
    trackingStatus.value = 'idle';
    volunteerPosition.value = null;
    remainingDistanceKm.value = null;
    remainingMinutes.value = null;
    routePoints.clear();
    traveledPoints.clear();
    _currentRequestId = null;
    destination.value = null;
  }

  /// Split the current full route at the volunteer's position:
  /// - `traveledPoints` = portion already behind the volunteer
  /// - `routePoints` stays as the full route (volunteer -> destination)
  /// If the volunteer is clearly off the route, re-fetch a new route (throttled).
  void _updateRouteProgress(LatLng pos) {
    final route = List<LatLng>.from(routePoints);
    final destination = this.destination.value;
    if (route.length < 2 || destination == null) return;

    final projected = _projectOnRoute(pos, route);
    final projPoint = projected.key;
    final traveledDist = projected.value;

    // Snap the live marker to the road geometry so the volunteer never
    // drifts off the OSRM route (and follows turns instead of cutting
    // across them). The raw GPS fix is only used until a route exists.
    volunteerPosition.value = projPoint;

    final traveled = <LatLng>[];
    var inserted = false;
    double accumulated = 0;
    for (int i = 0; i < route.length - 1; i++) {
      final segDist = const Distance().as(
        LengthUnit.Meter,
        route[i],
        route[i + 1],
      );
      if (accumulated + segDist >= traveledDist) {
        traveled.add(projPoint);
        inserted = true;
        break;
      }
      traveled.add(route[i]);
      accumulated += segDist;
    }
    if (!inserted) traveled.add(route.last);
    if (traveled.length < 2) traveled.clear();
    traveledPoints.assignAll(traveled);

    final offRouteMeters = const Distance().as(
      LengthUnit.Meter,
      pos,
      projPoint,
    );
    final now = DateTime.now();
    final intervalElapsed =
        _lastRouteFetchAt == null ||
        now.difference(_lastRouteFetchAt!) >= _refetchInterval;
    final movedEnough =
        _lastRouteRefetchFrom == null ||
        const Distance().as(
              LengthUnit.Meter,
              _lastRouteRefetchFrom!,
              pos,
            ) >=
            _refetchDistanceMeters;
    if (offRouteMeters > 40 && intervalElapsed && movedEnough) {
      _lastRouteRefetchFrom = pos;
      _fetchFullRoute(pos, destination);
    }
  }

  /// Distance/ETA along the route (fallback: straight line).
  void _updateRemainingDistance(LatLng current) {
    final destination = this.destination.value;
    if (destination == null) return;

    double remainingMeters;
    final route = routePoints;
    if (route.length >= 2) {
      double total = 0;
      for (int i = 0; i < route.length - 1; i++) {
        total += const Distance().as(
          LengthUnit.Meter,
          route[i],
          route[i + 1],
        );
      }
      final traveled = _projectOnRoute(current, route).value;
      remainingMeters = (total - traveled).clamp(0.0, double.infinity);
    } else {
      remainingMeters = const Distance().as(
        LengthUnit.Meter,
        current,
        destination,
      );
    }

    remainingDistanceKm.value = double.parse(
      (remainingMeters / 1000).toStringAsFixed(1),
    );
    remainingMinutes.value = (remainingMeters / 1000 / 30 * 60).round().clamp(
      1,
      999,
    );
  }

  Future<void> _fetchFullRoute(LatLng from, LatLng to) async {
    if (_isFetchingRoute) return;
    _isFetchingRoute = true;
    try {
      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
        '?overview=full&geometries=geojson',
      );
      final response = await http
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'WeHelpApp/1.0 tracking',
            },
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return;

      final decoded = _decodeRoute(response.body);
      if (decoded.length < 2) return;

      routePoints.assignAll(decoded);
      traveledPoints.clear();
      _lastRouteFetchAt = DateTime.now();

      // Re-split immediately so the traveled line starts at the right place.
      final pos = volunteerPosition.value;
      if (pos != null) _updateRouteProgress(pos);
    } catch (_) {
      if (routePoints.length < 2) {
        routePoints.assignAll([from, to]);
      }
    } finally {
      _isFetchingRoute = false;
    }
  }

  List<LatLng> _decodeRoute(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map) return [];
      final routes = decoded['routes'];
      if (routes is! List || routes.isEmpty) return [];
      final route = routes.first;
      if (route is! Map) return [];
      final geometry = route['geometry'];
      if (geometry is! Map) return [];
      final coords = geometry['coordinates'];
      if (coords is! List) return [];
      return coords
          .whereType<List>()
          .where((c) => c.length >= 2)
          .map((c) => LatLng(_readDouble(c[1]) ?? 0, _readDouble(c[0]) ?? 0))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static MapEntry<LatLng, double> _projectOnRoute(
    LatLng point,
    List<LatLng> polyline,
  ) {
    return projectOnRoute(point, polyline);
  }

  /// Pure projection of [point] onto [polyline] (public for unit tests).
  /// Returns the closest on-road point and the distance travelled along the
  /// route up to it. The marker snaps to this point so it rides the OSRM
  /// geometry instead of cutting across corners.
  static MapEntry<LatLng, double> projectOnRoute(
    LatLng point,
    List<LatLng> polyline,
  ) {
    if (polyline.length < 2) return MapEntry(point, 0);
    int segIdx = 0;
    double segT = 0;
    double minDistSq = double.infinity;
    for (int i = 0; i < polyline.length - 1; i++) {
      final a = polyline[i];
      final b = polyline[i + 1];
      final dx = b.longitude - a.longitude;
      final dy = b.latitude - a.latitude;
      final lenSq = dx * dx + dy * dy;
      double t = 0;
      if (lenSq != 0) {
        t =
            ((point.longitude - a.longitude) * dx +
                (point.latitude - a.latitude) * dy) /
            lenSq;
        t = t.clamp(0.0, 1.0);
      }
      final projLng = a.longitude + t * dx;
      final projLat = a.latitude + t * dy;
      final distSq =
          (point.longitude - projLng) * (point.longitude - projLng) +
          (point.latitude - projLat) * (point.latitude - projLat);
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
}
