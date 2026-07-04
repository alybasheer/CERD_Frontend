import 'package:flutter/material.dart';
import 'package:fyp_source_code/request_side/create_help_request/data/model/help_request.dart';
import 'package:get/get.dart';
import 'package:fyp_source_code/request_side/home/presentation/controller/request_home_controller.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_colors.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_text.dart';
import 'package:fyp_source_code/utilities/reuse_components/spacing.dart';
import 'package:fyp_source_code/utilities/reuse_widgets/app_bar.dart';
import 'package:fyp_source_code/utilities/reuse_widgets/shimmer_loading.dart';

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

        return _SosPulseButton(
          isSending: isSending,
          onPressed: isSending ? null : controller.sendSos,
        );
      }),
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
