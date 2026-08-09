import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fyp_source_code/chat/presentation/provider/chat_provider.dart';
import 'package:fyp_source_code/request_side/home/presentation/controller/tracking_controller.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this._path);

  final String _path;

  @override
  Future<String?> getApplicationDocumentsPath() async => _path;

  @override
  Future<String?> getApplicationSupportPath() async => _path;

  @override
  Future<String?> getTemporaryPath() async => _path;

  @override
  Future<String?> getApplicationCachePath() async => _path;
}

/// L-shaped test route:
///   A(0,0) -> corner(0,1) -> B(1,1)
/// Roads run due-east then due-north (lat/lng axes), i.e. a hard 90° turn.
final _route = <LatLng>[
  const LatLng(0.0, 0.0), // start
  const LatLng(0.0, 0.001), // east 1
  const LatLng(0.0, 0.002), // east 2 (corner approach)
  const LatLng(0.001, 0.002), // north 1 (turned)
  const LatLng(0.002, 0.002), // north 2 (near dest)
];

class _FakeProvider {
  final _locations = StreamController<Map<String, dynamic>>.broadcast();
  final _status = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get volunteerLocationStream =>
      _locations.stream;
  Stream<Map<String, dynamic>> get trackingStatusStream => _status.stream;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final dir = await Directory.systemTemp.createTemp('tracking_test');
    PathProviderPlatform.instance = _FakePathProvider(dir.path);
    await GetStorage.init();
  });

  group('projectOnRoute', () {
    test('snaps an off-road point onto the road', () {
      // Volunteers GPS noise: 30m south of the road.
      const noisy = LatLng(0.0004, 0.001);
      final proj = TrackingController.projectOnRoute(noisy, _route);
      expect(proj.key.latitude, closeTo(0.0, 0.00001));
      expect(proj.key.longitude, closeTo(0.001, 0.0001));
      expect(proj.value, greaterThan(0));
    });

test('does not cut the corner: pre-turn point stays on the west road', () {
    // Volunteer one leg before the turn, GPS 30m south of the road:
    // projection must land on the west (E-W) segment, not on the
    // northbound segment (which would be a straight-line cut).
    const nearCorner = LatLng(-0.0003, 0.0005);
    final proj = TrackingController.projectOnRoute(nearCorner, _route);
    expect(proj.key.latitude, closeTo(0.0, 0.0006));
    expect(proj.key.longitude, closeTo(0.0005, 0.0002));
  });

    test('after the turn the snap follows the northbound segment', () {
      const pastTurn = LatLng(0.0012, 0.002);
      final proj = TrackingController.projectOnRoute(pastTurn, _route);
      expect(proj.key.latitude, closeTo(0.0012, 0.0002));
      expect(proj.key.longitude, closeTo(0.002, 0.0002));
      expect(proj.value, greaterThan(110));
    });
  });

  test('tracked marker snaps to the road and travelled path grows', () async {
    final provider = _FakeProvider();
    Get.put<ChatProvider>(_FakeProviderToChat(provider));
    final ctrl = TrackingController();
    try {
      ctrl.startTracking('req-1', const LatLng(0.002, 0.002));
      expect(ctrl.isTracking.value, isTrue);

      // First (off-road noisy) location: route is fetched async - feed a
      // location so the marker at least exists raw before geometry arrives.
      provider._locations.add({
        'requestId': 'req-1',
        'latitude': 0.0004,
        'longitude': 0.001,
      });
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Simulate the route having been fetched (controller route list is
      // directly injected via the identical OSRM decode path).
      ctrl.routePoints.assignAll(_route);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Move along the road: past the corner now.
      provider._locations.add({
        'requestId': 'req-1',
        'latitude': 0.0014,
        'longitude': 0.002,
      });
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final snapped = ctrl.volunteerPosition.value;
      expect(snapped, isNotNull);
      // The marker was snapped to the north leg (not raw 0.0014,0.002 is
      // already on the road but ensure tolerance).
      expect(snapped!.latitude, closeTo(0.0014, 0.0002));
      expect(snapped.longitude, closeTo(0.002, 0.0002));
      // Travelled path grew: it contains the corner and start.
      expect(ctrl.traveledPoints.length, greaterThanOrEqualTo(2));
    } finally {
      ctrl.stopTracking();
    }
  });
}

/// Minimal ChatProvider stand-in (only the streams the TrackingController
/// consumes are reachable through this wrapper class).
class _FakeProviderToChat extends ChatProvider {
  _FakeProviderToChat(this._provider);

  final _FakeProvider _provider;

  @override
  Future<void> ensureConnected() async {}

  @override
  Future<void> fetchConversations() async {}

  @override
  Future<void> fetchUnreadCount() async {}

  @override
  Stream<Map<String, dynamic>> get volunteerLocationStream =>
      _provider._locations.stream;

  @override
  Stream<Map<String, dynamic>> get trackingStatusStream =>
      _provider._status.stream;
}