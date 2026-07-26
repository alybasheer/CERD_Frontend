import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:fyp_source_code/request_side/create_help_request/data/model/help_request.dart';
import 'package:fyp_source_code/routing/route_names.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_colors.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_text.dart';
import 'package:fyp_source_code/utilities/reuse_components/spacing.dart';
import 'package:fyp_source_code/utilities/reuse_widgets/request_media_gallery.dart';
import 'package:fyp_source_code/utilities/reuse_widgets/app_bar.dart';

import 'package:fyp_source_code/volunteer_side/map/presentation/controller/map_controller.dart';
import 'package:fyp_source_code/volunteer_side/map/presentation/view/widgets/build_getlocation.dart';
import 'package:fyp_source_code/volunteer_side/map/presentation/view/widgets/build_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  late final MapCntrl mapCntrl;
  final flutterMapController = MapController();
  String? _lastCameraTarget;

  late final AnimationController _animController;
  LatLng? _smoothLatLng;
  LatLng? _smoothTarget;

  // Route-following animation state
  List<LatLng>? _animRoute;
  double _animFromDist = 0;
  double _animToDist = 0;

  @override
  void initState() {
    super.initState();
    mapCntrl =
        Get.isRegistered<MapCntrl>()
            ? Get.find<MapCntrl>()
            : Get.put(MapCntrl(), permanent: true);
    mapCntrl.setActiveRequestFromArguments(Get.arguments);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animController.addListener(_onAnimate);
    _animController.addStatusListener(_onAnimComplete);

    ever(mapCntrl.currentLatLng, _onNewLocation);
  }

  void _onAnimComplete(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      // Truncate the route behind the icon after animation finishes
      final route = mapCntrl.shortestPathPoints;
      if (route.length >= 2 && _smoothLatLng != null) {
        final projected = MapCntrl.projectOnRoute(_smoothLatLng!, route);
        if (projected.value > 0) {
          final truncated = MapCntrl.truncatePolylineFromDist(
            route,
            projected.value,
          );
          if (truncated.length >= 2) {
            mapCntrl.shortestPathPoints.assignAll(truncated);
          }
        }
      }
      _animRoute = null;
    }
  }

  void _onNewLocation(LatLng? newLoc) {
    if (newLoc == null) {
      _smoothLatLng = null;
      _smoothTarget = null;
      _animRoute = null;
      return;
    }
    if (_animController.isAnimating) {
      return;
    }

    _smoothTarget = newLoc;
    final from = _smoothLatLng ?? newLoc;
    if (from == newLoc) {
      return;
    }

    // Snapshot the current route for animating along it
    final route = mapCntrl.shortestPathPoints;
    if (route.length >= 2) {
      _animRoute = List.from(route);
      _animFromDist = MapCntrl.projectOnRoute(from, _animRoute!).value;
      _animToDist = MapCntrl.projectOnRoute(newLoc, _animRoute!).value;
    } else {
      _animRoute = null;
    }

    _animController.reset();
    _animController.forward();
  }

  void _onAnimate() {
    final eased = _easeInOutCubic(_animController.value);

    if (_animRoute != null && _animRoute!.length >= 2) {
      // Animate along the route polyline
      final currentDist = _animFromDist + (_animToDist - _animFromDist) * eased;
      _smoothLatLng = MapCntrl.pointAtDistOnRoute(_animRoute!, currentDist);
    } else {
      // Fallback: straight-line interpolation
      final from = _smoothLatLng;
      final to = _smoothTarget;
      if (from == null || to == null) return;
      _smoothLatLng = LatLng(
        from.latitude + (to.latitude - from.latitude) * eased,
        from.longitude + (to.longitude - from.longitude) * eased,
      );
    }
    setState(() {});
  }

  static double _easeInOutCubic(double t) {
    return t < 0.5
        ? 4 * t * t * t
        : 1 - (-2 * t + 2) * (-2 * t + 2) * (-2 * t + 2) / 2;
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: WeHelpAppBar(
        title: 'Emergency Map',
        subtitle: 'Nearby volunteers and live position',
        showBack: Get.currentRoute == RouteNames.map,
      ),
      body: Obx(() {
        // Keep smooth position in sync when not animating
        if (!_animController.isAnimating) {
          _smoothLatLng = mapCntrl.currentLatLng.value;
        }
        final latlng = _smoothLatLng;
        final activeRequest = mapCntrl.activeRequest.value;
        final activeRequestLocation = mapCntrl.activeRequestLatLng;
        final routePoints = mapCntrl.activeRoutePoints;

        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _focusMap(latlng, activeRequestLocation),
        );

        return Stack(
          children: [
            buildMap(
              latlng: latlng,
              activeRequestLocation: activeRequestLocation,
              routePoints: routePoints,
              users: mapCntrl.mapUsers,
              mapController: flutterMapController,
            ),
            _MapControlLayer(
              selected: mapCntrl.selectedRoleFilter.value,
              visibleCount: mapCntrl.mapUsers.length,
              hasLiveLocation: latlng != null,
              onSelected: mapCntrl.setRoleFilter,
            ),
            getLocation(
              currentLocation: latlng,
              mapController: flutterMapController,
              bottom:
                  activeRequest == null
                      ? 96
                      : activeRequest.displayMediaUrls.isEmpty
                      ? 228
                      : 318,
            ),
            if (activeRequest != null)
              _ActiveRequestPanel(
                request: activeRequest,
                distanceKm: mapCntrl.activeDistanceKm,
                isCompleting: mapCntrl.isCompleting.value,
                isCancelling: mapCntrl.isCancelling.value,
                onChat: mapCntrl.openActiveRequestChat,
                onDone: mapCntrl.completeActiveRequest,
                onCancel: mapCntrl.cancelActiveRequest,
              ),
          ],
        );
      }),
    );
  }

  void _focusMap(LatLng? currentLocation, LatLng? requestLocation) {
    if (currentLocation == null && requestLocation == null) {
      return;
    }

    final cameraKey =
        '${_cameraKey(currentLocation)}:${_cameraKey(requestLocation)}';
    if (_lastCameraTarget == cameraKey) {
      return;
    }
    _lastCameraTarget = cameraKey;

    try {
      if (currentLocation != null && requestLocation != null) {
        flutterMapController.fitCamera(
          CameraFit.coordinates(
            coordinates: [currentLocation, requestLocation],
            padding: const EdgeInsets.fromLTRB(48, 96, 48, 220),
            maxZoom: 17,
          ),
        );
        return;
      }

      flutterMapController.move(currentLocation ?? requestLocation!, 17.0);
    } catch (_) {
      _lastCameraTarget = null;
    }
  }

  String _cameraKey(LatLng? point) {
    if (point == null) {
      return 'none';
    }
    return '${point.latitude.toStringAsFixed(4)},${point.longitude.toStringAsFixed(4)}';
  }
}

class _MapControlLayer extends StatelessWidget {
  final String selected;
  final int visibleCount;
  final bool hasLiveLocation;
  final ValueChanged<String> onSelected;

  const _MapControlLayer({
    required this.selected,
    required this.visibleCount,
    required this.hasLiveLocation,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: AppSize.sH,
      left: AppSize.m,
      right: AppSize.m,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _MapFilterChip(
                    label: 'All',
                    icon: Icons.layers_rounded,
                    value: 'all',
                    selected: selected,
                    color: AppColors.steelBlue,
                    onSelected: onSelected,
                  ),
                  SizedBox(width: AppSize.xs),
                  _MapFilterChip(
                    label: 'Volunteers',
                    icon: Icons.volunteer_activism_rounded,
                    value: 'volunteer',
                    selected: selected,
                    color: AppColors.reliefGreen,
                    onSelected: onSelected,
                  ),
                  SizedBox(width: AppSize.xs),
                  _MapFilterChip(
                    label: 'Users',
                    icon: Icons.person_pin_circle_rounded,
                    value: 'requestee',
                    selected: selected,
                    color: AppColors.amberOrange,
                    onSelected: onSelected,
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSize.xsH),
            _MapStatusChip(text: _statusText, isLive: hasLiveLocation),
          ],
        ),
      ),
    );
  }

  String get _statusText {
    final scope =
        selected == 'volunteer'
            ? 'volunteers'
            : selected == 'requestee'
            ? 'users'
            : 'people';
    return '$visibleCount nearby $scope';
  }
}

class _MapFilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final String selected;
  final Color color;
  final ValueChanged<String> onSelected;

  const _MapFilterChip({
    required this.label,
    required this.icon,
    required this.value,
    required this.selected,
    required this.color,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isSelected = selected == value;

    return Material(
      color: isSelected ? color : scheme.surface,
      borderRadius: BorderRadius.circular(999),
      elevation: isSelected ? 4 : 2,
      shadowColor: Colors.black.withValues(alpha: 0.16),
      child: InkWell(
        onTap: () => onSelected(value),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 38,
          padding: EdgeInsets.symmetric(horizontal: AppSize.s),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color:
                  isSelected
                      ? color.withValues(alpha: 0.35)
                      : Theme.of(context).dividerColor,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: isSelected ? Colors.white : color),
              SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyling.body_12S.copyWith(
                  color: isSelected ? Colors.white : scheme.onSurface,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapStatusChip extends StatelessWidget {
  final String text;
  final bool isLive;

  const _MapStatusChip({required this.text, required this.isLive});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSize.s, vertical: 7),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isLive ? AppColors.reliefGreen : scheme.onSurfaceVariant,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 7),
          Text(
            text,
            style: AppTextStyling.body_12S.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveRequestPanel extends StatelessWidget {
  final HelpRequest request;
  final double? distanceKm;
  final bool isCompleting;
  final bool isCancelling;
  final VoidCallback onChat;
  final VoidCallback onDone;
  final VoidCallback onCancel;

  const _ActiveRequestPanel({
    required this.request,
    required this.distanceKm,
    required this.isCompleting,
    required this.isCancelling,
    required this.onChat,
    required this.onDone,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isBusy = isCompleting || isCancelling;
    final distanceText =
        distanceKm == null ? null : '${distanceKm!.toStringAsFixed(2)} km away';

    return Positioned(
      left: AppSize.m,
      right: AppSize.m,
      bottom: AppSize.mH,
      child: SafeArea(
        top: false,
        child: Container(
          padding: EdgeInsets.all(AppSize.m),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.emergencyRed.withValues(
                      alpha: 0.12,
                    ),
                    child: const Icon(
                      Icons.route_rounded,
                      color: AppColors.emergencyRed,
                    ),
                  ),
                  SizedBox(width: AppSize.s),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyling.title_16M.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: AppSize.xsH / 2),
                        Text(
                          distanceText ?? request.displayLocation,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyling.body_12S.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: isBusy ? null : onChat,
                    tooltip: 'Chat',
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    color: AppColors.steelBlue,
                  ),
                ],
              ),
              SizedBox(height: AppSize.sH),
              if (request.displayMediaUrls.isNotEmpty) ...[
                RequestMediaStrip(
                  mediaUrls: request.displayMediaUrls,
                  height: 78,
                ),
                SizedBox(height: AppSize.sH),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isBusy ? null : onCancel,
                      icon:
                          isCancelling
                              ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(Icons.close_rounded),
                      label: Text(isCancelling ? 'Cancelling' : 'Cancel'),
                    ),
                  ),
                  SizedBox(width: AppSize.s),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isBusy ? null : onDone,
                      icon:
                          isCompleting
                              ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Icon(Icons.done_rounded),
                      label: Text(isCompleting ? 'Completing' : 'Done'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.reliefGreen,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSize.sH),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          isBusy
                              ? null
                              : () => Get.find<MapCntrl>().startLiveTracking(),
                      icon: const Icon(Icons.navigation, size: 18),
                      label: const Text('Navigate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.steelBlue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
