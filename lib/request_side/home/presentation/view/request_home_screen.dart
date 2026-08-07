import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:fyp_source_code/request_side/create_help_request/data/model/help_request.dart';
import 'package:fyp_source_code/request_side/home/presentation/controller/tracking_controller.dart';
import 'package:fyp_source_code/routing/route_names.dart';
import 'package:get/get.dart';
import 'package:fyp_source_code/request_side/home/presentation/controller/request_home_controller.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_colors.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_text.dart';
import 'package:fyp_source_code/utilities/reuse_components/spacing.dart';
import 'package:fyp_source_code/utilities/reuse_widgets/app_bar.dart';
import 'package:fyp_source_code/utilities/reuse_widgets/app_version_badge.dart';
import 'package:fyp_source_code/utilities/reuse_widgets/shimmer_loading.dart';
import 'package:latlong2/latlong.dart';

class RequestHomeScreen extends StatelessWidget {
  const RequestHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(RequestHomeController());
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const WeHelpAppBar(
        title: 'request.home.title',
        subtitle: 'request.home.subtitle',
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Center(child: AppVersionBadge(light: true)),
          ),
        ],
      ),
      body: Obx(
        () => RefreshIndicator(
          onRefresh: controller.refreshDashboard,
          child: ListView(
            padding: EdgeInsets.all(AppSize.m),
            children: [
              _SectionTitle(title: 'request.home.nearby'.tr),
              SizedBox(height: AppSize.sH),
              if (controller.isLoading.value)
                AppShimmer(
                  child: Column(
                    children: List.generate(
                      3,
                      (index) => Padding(
                        padding: EdgeInsets.only(bottom: AppSize.sH),
                        child: const ShimmerListTileSkeleton(),
                      ),
                    ),
                  ),
                )
              else if (controller.nearbyVolunteers.isEmpty)
                _EmptyBox(text: 'request.home.nearby.empty'.tr)
              else
                ...controller.nearbyVolunteers.map(_VolunteerTile.new),
              _SosStatusSection(controller: controller),
              _TrackingMapSection(controller: controller.trackingController),
              if (controller.activeRequests.isNotEmpty) ...[
                SizedBox(height: AppSize.lH),
                _SectionTitle(title: 'request.home.active_requests'.tr),
                SizedBox(height: AppSize.sH),
                ...controller.activeRequests.map(
                  (request) => _RequestTile(
                    request: request,
                    onChat: () => controller.openRequestChat(request),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SosEmergencyBar(controller: controller),
          _RequestBottomNavBar(controller: controller),
        ],
      ),
    );
  }
}

class _SosStatusSection extends StatelessWidget {
  final RequestHomeController controller;

  const _SosStatusSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    final request = controller.activeRequests
        .where((r) => r.isSos && _isOpenSosStatus(r))
        .firstOrNull;
    if (request == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: AppSize.sH, bottom: AppSize.sH),
      child: _SosStatusCard(
        request: request,
        onCallHelpline: controller.openHelplineSheet,
        onCancel: () => controller.cancelActiveSos(request),
        controller: controller,
      ),
    );
  }

  static bool _isOpenSosStatus(HelpRequest request) {
    final status = request.status?.toLowerCase().trim() ?? '';
    return status == 'open' || status == 'active' || status == 'pending';
  }
}

class _SosStatusCard extends StatefulWidget {
  final HelpRequest request;
  final VoidCallback onCallHelpline;
  final VoidCallback onCancel;
  final RequestHomeController controller;

  const _SosStatusCard({
    required this.request,
    required this.onCallHelpline,
    required this.onCancel,
    required this.controller,
  });

  @override
  State<_SosStatusCard> createState() => _SosStatusCardState();
}

class _SosStatusCardState extends State<_SosStatusCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _elapsed {
    final created = DateTime.tryParse(widget.request.createdAt ?? '');
    if (created == null) return '';
    final diff = DateTime.now().difference(created);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    return '${diff.inHours} hr ${diff.inMinutes % 60} min ago';
  }

  @override
  Widget build(BuildContext context) {
    final notified = widget.request.notifiedCount;

    return Container(
      padding: EdgeInsets.all(AppSize.m),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.emergencyRed,
            AppColors.emergencyRed.withValues(alpha: 0.78),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.emergencyRed.withValues(alpha: 0.30),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sos, color: Colors.white, size: 26),
              SizedBox(width: AppSize.s),
              Text(
                'sos.status.active'.tr,
                style: AppTextStyling.title_16M.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Text(
                _elapsed,
                style: AppTextStyling.body_12S.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSize.sH),
          Text(
            notified != null && notified > 0
                ? 'sos.status.notified_count'.trParams({
                    'count': '$notified',
                  })
                : 'sos.status.notified'.tr,
            style: AppTextStyling.body_14M.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppSize.sH),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onCallHelpline,
                  icon: const Icon(Icons.phone_in_talk_rounded, size: 18),
                  label: Text('common.helpline'.tr),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
              SizedBox(width: AppSize.s),
              Expanded(
                child: TextButton.icon(
                  onPressed: widget.onCancel,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: Text('sos.cancel'.tr),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSize.sH),
          _SosSnoozeRow(widget.controller),
        ],
      ),
    );
  }
}

class _SosSnoozeRow extends StatefulWidget {
  final RequestHomeController controller;

  const _SosSnoozeRow(this.controller);

  @override
  State<_SosSnoozeRow> createState() => _SosSnoozeRowState();
}

class _SosSnoozeRowState extends State<_SosSnoozeRow> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _pickSnoozeDuration() {
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: AppSize.m),
                child: Center(
                  child: Text(
                    'sos.snooze.title'.tr,
                    style: AppTextStyling.title_16M.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              ..._snoozeOptions.map(
                (entry) => ListTile(
                  leading: const Icon(Icons.bedtime_rounded),
                  title: Text('sos.snooze.option'.trParams({'min': entry.label})),
                  subtitle: Text(
                    entry.duration == const Duration(minutes: 5)
                        ? 'sos.snooze.recommended'.tr
                        : 'sos.snooze.pause_hint'.tr,
                  ),
                  trailing: const Icon(Icons.alarm_off_rounded, size: 20),
                  onTap: () {
                    Get.back();
                    widget.controller.snoozeSos(entry.duration);
                  },
                ),
              ),
              SizedBox(height: AppSize.mH),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      barrierColor: const Color(0x99000000),
    );
  }

  static const _snoozeOptions = [
    _Snooze('5 min', Duration(minutes: 5)),
    _Snooze('15 min', Duration(minutes: 15)),
    _Snooze('30 min', Duration(minutes: 30)),
  ];

  @override
  Widget build(BuildContext context) {
    if (widget.controller.isSosSnoozed) {
      return Row(
        children: [
          Expanded(
            child: Chip(
              avatar: const Icon(
                Icons.bedtime_rounded,
                size: 18,
                color: AppColors.emergencyRed,
              ),
              label: Text(
                'sos.snooze.paused'.trParams({'time': widget.controller.snoozeLabel}),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              backgroundColor: Colors.white,
              labelStyle: const TextStyle(
                color: AppColors.emergencyRed,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          SizedBox(width: AppSize.s),
          TextButton.icon(
            onPressed: widget.controller.clearSnooze,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text('sos.snooze.resume'.tr),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
          ),
        ],
      );
    }

    return Align(
      alignment: Alignment.center,
      child: TextButton.icon(
        onPressed: _pickSnoozeDuration,
        icon: const Icon(Icons.bedtime_rounded, size: 18),
        label: Text('sos.snooze'.tr),
        style: TextButton.styleFrom(foregroundColor: Colors.white),
      ),
    );
  }
}

class _Snooze {
  final String label;
  final Duration duration;

  const _Snooze(this.label, this.duration);
}

class _TrackingMapSection extends StatelessWidget {
  final TrackingController controller;

  const _TrackingMapSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.isTracking.value) return const SizedBox.shrink();

      final volPos = controller.volunteerPosition.value;
      final destination =
          controller.routePoints.isNotEmpty
              ? controller.routePoints.last
              : null;
      final dist = controller.remainingDistanceKm.value;
      final eta = controller.remainingMinutes.value;
      final status = controller.trackingStatus.value;
      final route = controller.routePoints;
      final traveled = controller.traveledPoints;

      return Container(
        height: 260,
        margin: EdgeInsets.only(bottom: AppSize.sH),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
          color: Theme.of(context).colorScheme.surface,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Container(
              height: 32,
              padding: EdgeInsets.symmetric(horizontal: AppSize.s),
              decoration: BoxDecoration(
                color:
                    status == 'arrived'
                        ? AppColors.reliefGreen.withValues(alpha: 0.12)
                        : AppColors.steelBlue.withValues(alpha: 0.10),
              ),
              child: Row(
                children: [
                  Icon(
                    status == 'arrived'
                        ? Icons.check_circle
                        : Icons.location_on,
                    size: 16,
                    color:
                        status == 'arrived'
                            ? AppColors.reliefGreen
                            : AppColors.steelBlue,
                  ),
                  SizedBox(width: AppSize.xs),
                  Text(
                    status == 'arrived'
                        ? 'Volunteer arrived'
                        : 'Volunteer en route',
                    style: AppTextStyling.body_12S.copyWith(
                      color:
                          status == 'arrived'
                              ? AppColors.reliefGreen
                              : AppColors.steelBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Spacer(),
                  if (dist != null)
                    Text(
                      '${dist.toStringAsFixed(1)} km',
                      style: AppTextStyling.body_12S.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (eta != null) ...[
                    SizedBox(width: AppSize.xs),
                    Text(
                      '~$eta min',
                      style: AppTextStyling.body_12S.copyWith(
                        color: AppColors.mediumGray,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              height: 32,
              padding: EdgeInsets.symmetric(horizontal: AppSize.s),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => Get.toNamed(RouteNames.trackingMap),
                    icon: const Icon(Icons.fullscreen, size: 16),
                    label: Text('sos.tracking.view_map'.tr),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.steelBlue,
                      padding: EdgeInsets.symmetric(horizontal: AppSize.s),
                      textStyle: AppTextStyling.body_12S.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter:
                      volPos ?? destination ?? const LatLng(31.52, 74.35),
                  initialZoom: 14,
                  minZoom: 1,
                  maxZoom: 19,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.fyp.volunteer_emergency_network',
                  ),
                  if (route.length >= 2)
                    PolylineLayer(
                      polylines: <Polyline<Object>>[
                        Polyline<Object>(
                          points: route,
                          strokeWidth: 5,
                          color: AppColors.steelBlue.withValues(alpha: 0.6),
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
                          strokeWidth: 4,
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
                          width: 28,
                          height: 28,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.reliefGreen,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.reliefGreen.withValues(
                                    alpha: 0.4,
                                  ),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (destination != null && route.length >= 2)
                        Marker(
                          point: destination,
                          width: 24,
                          height: 24,
                          child: Icon(
                            Icons.location_on,
                            color: AppColors.emergencyRed,
                            size: 28,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _SosEmergencyBar extends StatelessWidget {
  final RequestHomeController controller;

  const _SosEmergencyBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: EdgeInsets.fromLTRB(
        AppSize.m,
        AppSize.mH,
        AppSize.m,
        AppSize.sH,
      ),
      child: Obx(() {
        final isSending = controller.isSendingSos.value;

        return Row(
          children: [
            Expanded(
              child: _SosPulseButton(
                isSending: isSending,
                onPressed: isSending ? null : controller.sendSos,
              ),
            ),
            SizedBox(width: AppSize.s),
            _HelplineButton(onTap: controller.openHelplineSheet),
          ],
        );
      }),
    );
  }
}

class _HelplineButton extends StatelessWidget {
  final VoidCallback onTap;

  const _HelplineButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.phone_in_talk_rounded, size: 18),
        label: Text('common.helpline'.tr),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.steelBlue,
          side: BorderSide(
            color: AppColors.steelBlue.withValues(alpha: 0.4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          textStyle: AppTextStyling.body_12S.copyWith(
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _SosPulseButton extends StatefulWidget {
  final bool isSending;
  final VoidCallback? onPressed;

  const _SosPulseButton({required this.isSending, required this.onPressed});

  @override
  State<_SosPulseButton> createState() => _SosPulseButtonState();
}

class _SosPulseButtonState extends State<_SosPulseButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1650),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final glow = _pulse.value;

        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              top: -8 - (glow * 5),
              bottom: -8 - (glow * 5),
              left: 4 - (glow * 6),
              right: 4 - (glow * 6),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: AppColors.emergencyRed.withValues(
                    alpha: 0.10 + (glow * 0.08),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              top: -4 - (glow * 3),
              bottom: -4 - (glow * 3),
              left: 9 - (glow * 4),
              right: 9 - (glow * 4),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: AppColors.emergencyRed.withValues(
                    alpha: 0.16 + (glow * 0.10),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.emergencyRed.withValues(
                        alpha: 0.20 + (glow * 0.18),
                      ),
                      blurRadius: 18 + (glow * 12),
                      spreadRadius: 1 + (glow * 3),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: widget.onPressed,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: AppColors.emergencyRed,
                  disabledBackgroundColor: AppColors.emergencyRed.withValues(
                    alpha: 0.72,
                  ),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.13),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.08),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.isSending)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        else
                          const Icon(
                            Icons.warning_rounded,
                            color: Colors.white,
                            size: 21,
                          ),
                        SizedBox(width: AppSize.xs),
                        Text(
                          widget.isSending
                              ? 'request.home.sending_sos'.tr
                              : 'request.home.sos'.tr,
                          style: AppTextStyling.body_14M.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RequestBottomNavBar extends StatelessWidget {
  final RequestHomeController controller;

  const _RequestBottomNavBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSize.s, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'common.home'.tr,
                isActive: true,
                onTap: () {},
              ),
              _NavItem(
                icon: Icons.notifications_active_rounded,
                label: 'common.alerts'.tr,
                isActive: false,
                onTap: controller.openAlerts,
              ),
              _NavItem(
                icon: Icons.add_circle_outline_rounded,
                label: 'common.help'.tr,
                isActive: false,
                onTap: controller.openRequestHelpSheet,
              ),
              _NavItem(
                icon: Icons.people_alt_rounded,
                label: 'common.coordination'.tr,
                isActive: false,
                onTap: controller.openCoordination,
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'common.profile'.tr,
                isActive: false,
                onTap: controller.openProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive ? AppColors.steelBlue : AppColors.mediumGray,
                size: 26,
              ),
              SizedBox(height: AppSize.xsH),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyling.body_12S.copyWith(
                  color: isActive ? AppColors.steelBlue : AppColors.mediumGray,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyling.title_16M.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _VolunteerTile extends StatelessWidget {
  final NearbyVolunteer volunteer;

  const _VolunteerTile(this.volunteer);

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      icon: Icons.volunteer_activism,
      iconColor: AppColors.reliefGreen,
      title: volunteer.name,
      subtitle: volunteer.expertise,
      trailing:
          '${volunteer.ratingAverage.toStringAsFixed(1)} • '
          '${volunteer.ratingCount} '
          '${volunteer.ratingCount == 1 ? 'common.rating'.tr : 'common.ratings'.tr}',
    );
  }
}

class _RequestTile extends StatelessWidget {
  final HelpRequest request;
  final VoidCallback onChat;

  const _RequestTile({required this.request, required this.onChat});

  @override
  Widget build(BuildContext context) {
    final status = request.status?.toLowerCase().trim() ?? '';
    final canChat =
        request.acceptedBy != null &&
        request.acceptedBy!.trim().isNotEmpty &&
        (status == 'accepted' || status == 'in_progress');

    return _InfoCard(
      icon: request.isSos ? Icons.sos : Icons.support_agent,
      iconColor: request.isSos ? AppColors.emergencyRed : AppColors.steelBlue,
      title: request.displayTitle,
      subtitle: request.displayLocation,
      trailing: request.status ?? 'common.active'.tr,
      action:
          canChat
              ? Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onChat,
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: Text(
                    request.acceptedByName == null ||
                            request.acceptedByName!.trim().isEmpty
                        ? 'request.home.chat_volunteer'.tr
                        : 'Chat ${request.acceptedByName}',
                  ),
                ),
              )
              : null,
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String trailing;
  final Widget? action;

  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSize.sH),
      padding: EdgeInsets.all(AppSize.m),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: iconColor.withValues(alpha: 0.12),
                child: Icon(icon, color: iconColor),
              ),
              SizedBox(width: AppSize.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyling.title_16M.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: AppSize.xsH),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyling.body_12S.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: AppSize.s),
              Text(
                trailing,
                style: AppTextStyling.body_12S.copyWith(
                  color: AppColors.steelBlue,
                ),
              ),
            ],
          ),
          if (action != null) ...[SizedBox(height: AppSize.sH), action!],
        ],
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final String text;

  const _EmptyBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSize.m),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Text(
        text,
        style: AppTextStyling.body_14M.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
