import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fyp_source_code/splash_onboardings/presentation/controller/onboarding_controller.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_colors.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_text.dart';
import 'package:get/get.dart';

class OnboardingScreenProfessional extends StatelessWidget {
  const OnboardingScreenProfessional({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OnboardingController());
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: controller.pageController,
                onPageChanged: controller.onPageChanged,
                itemCount: controller.onboardingPages.length,
                itemBuilder: (context, index) {
                  return _OnboardingPage(
                    model: controller.onboardingPages[index],
                    index: index,
                  );
                },
              ),
            ),
            Obx(
              () => _OnboardingControls(
                currentPage: controller.currentPage.value,
                pageCount: controller.onboardingPages.length,
                isLastPage: controller.isLastPage.value,
                onSkip: controller.skipOnboarding,
                onNext:
                    controller.isLastPage.value
                        ? controller.finishOnboarding
                        : controller.nextPage,
                scheme: scheme,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final dynamic model;
  final int index;

  const _OnboardingPage({required this.model, required this.index});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final visualHeight = 250.h.clamp(220.0, 300.0);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 16.h),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.sizeOf(context).height - 190.h,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _VisualPanel(
              color: model.iconColor,
              index: index,
              height: visualHeight,
            ),
            SizedBox(height: 34.h),
            Text(
              model.titleKey.toString().tr,
              textAlign: TextAlign.center,
              style: AppTextStyling.title_16M.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w800,
                height: 1.12,
              ),
            ),
            SizedBox(height: 14.h),
            Text(
              model.descriptionKey.toString().tr,
              textAlign: TextAlign.center,
              maxLines: 
            3,
              style: AppTextStyling.body_14M.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisualPanel extends StatelessWidget {
  final Color color;
  final int index;
  final double height;

  const _VisualPanel({
    required this.color,
    required this.index,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 850),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 22),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        height: height,
        width: double.infinity,
        padding: EdgeInsets.all(22.w),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(26.r),
          border: Border.all(color: color.withValues(alpha: 0.18)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 26,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -22,
              right: -16,
              child: _SoftCircle(size: 106.w, color: color),
            ),
            Positioned(
              bottom: -16,
              left: -12,
              child: _SoftCircle(
                size: 72.w,
                color: color.withValues(alpha: 0.7),
              ),
            ),
            Center(
              child: Container(
                width: 150.w,
                height: 150.w,
                padding: EdgeInsets.all(28.w),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.20)),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.18),
                      blurRadius: 22,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(_mainIcon, color: color, size: 76.sp),
              ),
            ),
            ..._contextBadges(color),
          ],
        ),
      ),
    );
  }

  IconData get _mainIcon {
    switch (index) {
      case 0:
        return Icons.sos_rounded;
      case 1:
        return Icons.map_rounded;
      case 2:
        return Icons.groups_rounded;
      case 3:
        return Icons.notifications_active_rounded;
      default:
        return Icons.volunteer_activism_rounded;
    }
  }

  List<Widget> _contextBadges(Color color) {
    final badges = <List<dynamic>>[
      [Icons.sos_rounded, 'onboarding.badge.sos'],
      [Icons.my_location_rounded, 'onboarding.badge.live'],
      [Icons.groups_rounded, 'onboarding.badge.team'],
      [Icons.notifications_active_rounded, 'onboarding.badge.alert'],
      [Icons.check_circle_rounded, 'onboarding.badge.ready'],
    ];
    final badge = badges[index % badges.length];

    return [
      Positioned(
        left: 8,
        top: 10,
        child: _MiniBadge(
          icon: badge[0] as IconData,
          label: (badge[1] as String).tr,
          color: color,
        ),
      ),
      Positioned(
        right: 8,
        bottom: 10,
        child: _MiniBadge(
          icon: Icons.verified_rounded,
          label: 'onboarding.badge.trusted'.tr,
          color: AppColors.reliefGreen,
        ),
      ),
    ];
  }
}

class _SoftCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _SoftCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.10),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MiniBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15.sp),
          SizedBox(width: 5.w),
          Text(
            label,
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingControls extends StatelessWidget {
  final int currentPage;
  final int pageCount;
  final bool isLastPage;
  final VoidCallback onSkip;
  final VoidCallback onNext;
  final ColorScheme scheme;

  const _OnboardingControls({
    required this.currentPage,
    required this.pageCount,
    required this.isLastPage,
    required this.onSkip,
    required this.onNext,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 22.h),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(pageCount, (index) {
              final isActive = index == currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: EdgeInsets.symmetric(horizontal: 3.w),
                width: isActive ? 20.w : 7.w,
                height: 7.h,
                decoration: BoxDecoration(
                  color:
                      isActive
                          ? AppColors.safetyBlue
                          : scheme.outline.withValues(alpha: 0.32),
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                flex: 6,
                child: SizedBox(
                  height: 52.h,
                  child: OutlinedButton.icon(
                    onPressed: onSkip,
                    icon: Icon(
                      Icons.flash_on_rounded,
                      size: 18.sp,
                      color: AppColors.emergencyRed,
                    ),
                    label: Text(
                      'onboarding.skip'.tr,
                      style: TextStyle(
                        color: AppColors.emergencyRed,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: AppColors.emergencyRed.withValues(alpha: 0.42),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                flex: 4,
                child: SizedBox(
                  height: 52.h,
                  child: ElevatedButton(
                    onPressed: onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.safetyBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                    ),
                    child: Text(
                      isLastPage
                          ? 'onboarding.get_started'.tr
                          : 'common.next'.tr,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
