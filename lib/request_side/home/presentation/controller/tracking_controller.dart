import 'dart:async';
import 'dart:convert';

import 'package:fyp_source_code/chat/presentation/provider/chat_provider.dart';
import 'package:fyp_source_code/request_side/create_help_request/data/repo/help_request_repo.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class TrackingController extends GetxController {
  final HelpRequestRepo _repo = HelpRequestRepo();

  final Rx<LatLng?> volunteerPosition = Rx<LatLng?>(null);
  final RxString trackingStatus = 'idle'.obs;
  final Rx<double?> remainingDistanceKm = Rx<double?>(null);
  final Rx<int?> remainingMinutes = Rx<int?>(null);
  final RxList<LatLng> routePoints = <LatLng>[].obs;
  final RxList<LatLng> traveledPoints = <LatLng>[].obs;
  final RxBool isTracking = false.obs;

  String? _currentRequestId;
  LatLng? _destination;
  StreamSubscription<Map<String, dynamic>>? _locationSub;
  StreamSubscription<Map<String, dynamic>>? _statusSub;

  static double? _readDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  @override
  void onClose() {
    _locationSub?.cancel();
    _statusSub?.cancel();
    super.onClose();
  }

  void startTracking(String requestId, LatLng destination) {
    _currentRequestId = requestId;
    _destination = destination;
    isTracking.value = true;
    trackingStatus.value = 'en_route';

    final provider =
        Get.isRegistered<ChatProvider>()
            ? Get.find<ChatProvider>()
            : Get.put(ChatProvider());

    _locationSub?.cancel();
    _locationSub = provider.volunteerLocationStream.listen((data) {
      if (data['requestId']?.toString() != requestId) return;
      final lat = _readDouble(data['latitude']);
      final lng = _readDouble(data['longitude']);
      if (lat == null || lng == null) return;

      final pos = LatLng(lat, lng);
      volunteerPosition.value = pos;
      _updateRemainingDistance(pos);

      if (_destination != null) {
        _updateRouteFromApi(pos, _destination!);
      }
    });

    _statusSub?.cancel();
    _statusSub = provider.trackingStatusStream.listen((data) {
      if (data['requestId']?.toString() != requestId) return;
      final status = data['status']?.toString() ?? 'idle';
      trackingStatus.value = status;
      if (status == 'arrived') {
        isTracking.value = false;
      }
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
    _destination = null;
  }

  void _updateRemainingDistance(LatLng current) {
    if (_destination == null) return;
    final dist = const Distance().as(
      LengthUnit.Kilometer,
      current,
      _destination!,
    );
    remainingDistanceKm.value = double.parse(dist.toStringAsFixed(1));
    remainingMinutes.value = (dist / 30 * 60).round().clamp(1, 999);
  }

  Future<void> _updateRouteFromApi(LatLng from, LatLng to) async {
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

      final projected = _projectOnRoute(from, decoded);
      final traveledDist = projected.value;
      if (traveledDist > 0) {
        final truncated = _truncatePolylineFromDist(decoded, traveledDist);
        traveledPoints.assignAll(
          decoded.sublist(0, decoded.length - truncated.length),
        );
        if (traveledPoints.length < 2) traveledPoints.clear();
      } else {
        traveledPoints.clear();
      }
    } catch (_) {}
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

  static List<LatLng> _truncatePolylineFromDist(
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
      if (added) result.add(polyline[i + 1]);
      accumulated += segDist;
    }
    if (result.isEmpty && polyline.isNotEmpty) result.add(polyline.last);
    return result;
  }
}
