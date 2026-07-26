import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:fyp_source_code/request_side/home/presentation/controller/tracking_controller.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_colors.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_text.dart';
import 'package:fyp_source_code/utilities/reuse_components/spacing.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

class TrackingMapScreen extends StatefulWidget {
  const TrackingMapScreen({super.key});

  @override
  State<TrackingMapScreen> createState() => _TrackingMapScreenState();
}

class _TrackingMapScreenState extends State<TrackingMapScreen> {
  final MapController _mapController = MapController();
  String? _lastCameraKey;

  TrackingController? _ctrl;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<TrackingController>()) {
      _ctrl = Get.find<TrackingController>();
      ever(_ctrl!.volunteerPosition, _onPositionChanged);
      ever(_ctrl!.routePoints, (_) => _fitMap());
    }
  }

  void _onPositionChanged(LatLng? pos) {
    if (pos != null) _fitMap();
  }

  void _fitMap() {
    final ctrl = _ctrl;
    if (ctrl == null) return;
    final vol = ctrl.volunteerPosition.value;
    final dest = ctrl.routePoints.isNotEmpty ? ctrl.routePoints.last : null;
    final all = [vol, dest].whereType<LatLng>().toList();
    if (all.length < 2) {
      if (all.isNotEmpty) {
        _mapController.move(all.first, 15);
      }
      return;
    }
    final key = all
        .map(
          (p) =>
              '${p.latitude.toStringAsFixed(4)},${p.longitude.toStringAsFixed(4)}',
        )
        .join(':');
    if (key == _lastCameraKey) return;
    _lastCameraKey = key;
    try {
      _mapController.fitCamera(
        CameraFit.coordinates(
          coordinates: all,
          padding: const EdgeInsets.fromLTRB(48, 80, 48, 160),
          maxZoom: 17,
        ),
      );
    } catch (_) {
      _lastCameraKey = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl =
        _ctrl ??
        (Get.isRegistered<TrackingController>()
            ? Get.find<TrackingController>()
            : null);
    if (ctrl == null)
      return const Scaffold(
        body: Center(child: Text('No active tracking session')),
      );
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Obx(() {
          final status = ctrl.trackingStatus.value;
          return Text(
            status == 'arrived' ? 'Volunteer Arrived' : 'Live Tracking',
          );
        }),
        centerTitle: true,
        actions: [
          Obx(() {
            if (ctrl.remainingDistanceKm.value == null) return const SizedBox();
            return Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  '${ctrl.remainingDistanceKm.value!.toStringAsFixed(1)} km',
                  style: AppTextStyling.body_14M.copyWith(
                    color: AppColors.steelBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
      body: Obx(() {
        final volPos = ctrl.volunteerPosition.value;
        final dest = ctrl.routePoints.isNotEmpty ? ctrl.routePoints.last : null;
        final route = ctrl.routePoints;
        final traveled = ctrl.traveledPoints;
        final dist = ctrl.remainingDistanceKm.value;
        final eta = ctrl.remainingMinutes.value;
        final status = ctrl.trackingStatus.value;

        return Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: volPos ?? dest ?? const LatLng(31.52, 74.35),
                initialZoom: 14,
                minZoom: 1,
                maxZoom: 19,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.fyp.volunteer_emergency_network',
                ),
                if (route.length >= 2)
                  PolylineLayer(
                    polylines: <Polyline<Object>>[
                      Polyline<Object>(
                        points: route,
                        strokeWidth: 6,
                        color: AppColors.steelBlue.withValues(alpha: 0.7),
                        borderStrokeWidth: 2,
                        borderColor: Colors.white,
                      ),
                    ],
                  ),
                if (traveled.length >= 2)
                  PolylineLayer(
                    polylines: <Polyline<Object>>[
                      Polyline<Object>(
                        points: traveled,
                        strokeWidth: 5,
                        color: AppColors.mediumGray.withValues(alpha: 0.5),
                        borderStrokeWidth: 1,
                        borderColor: Colors.white.withValues(alpha: 0.3),
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    if (volPos != null)
                      Marker(
                        point: volPos,
                        width: 32,
                        height: 32,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.reliefGreen,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.reliefGreen.withValues(
                                  alpha: 0.5,
                                ),
                                blurRadius: 10,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.directions_run,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    if (dest != null)
                      Marker(
                        point: dest,
                        width: 30,
                        height: 30,
                        child: Icon(
                          Icons.location_on,
                          color: AppColors.emergencyRed,
                          size: 32,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            Positioned(
              left: AppSize.m,
              right: AppSize.m,
              bottom: AppSize.mH,
              child: SafeArea(
                top: false,
                child: Container(
                  padding: EdgeInsets.all(AppSize.m),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Theme.of(context).dividerColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.16),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _StatItem(
                        icon: Icons.route_rounded,
                        label: 'Distance',
                        value:
                            dist != null
                                ? '${dist.toStringAsFixed(1)} km'
                                : '--',
                        color: AppColors.steelBlue,
                      ),
                      _StatItem(
                        icon: Icons.access_time_rounded,
                        label: 'ETA',
                        value: eta != null ? '~$eta min' : '--',
                        color: AppColors.amberOrange,
                      ),
                      _StatItem(
                        icon:
                            status == 'arrived'
                                ? Icons.check_circle
                                : Icons.navigation,
                        label: 'Status',
                        value:
                            status == 'arrived'
                                ? 'Arrived'
                                : status == 'en_route'
                                ? 'En Route'
                                : 'Waiting',
                        color:
                            status == 'arrived'
                                ? AppColors.reliefGreen
                                : AppColors.steelBlue,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          SizedBox(height: AppSize.xsH),
          Text(
            value,
            style: AppTextStyling.title_16M.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyling.body_12S.copyWith(
              color: AppColors.mediumGray,
            ),
          ),
        ],
      ),
    );
  }
}
