import 'package:flutter/material.dart';
import 'package:fyp_source_code/localization/language_capsule.dart';
import 'package:fyp_source_code/splash_onboardings/presentation/controller/splash_controller.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_colors.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_text.dart';
import 'package:fyp_source_code/utilities/reuse_components/spacing.dart';
import 'package:get/get.dart';

class SplashScreenProfessional extends StatefulWidget {
  const SplashScreenProfessional({super.key});

  @override
  State<SplashScreenProfessional> createState() =>
      _SplashScreenProfessionalState();
}

class _SplashScreenProfessionalState extends State<SplashScreenProfessional>
    with TickerProviderStateMixin {
  late final SplashController controller;
  late final AnimationController introController;
  late final AnimationController pulseController;
  late final Animation<double> entrance;

  @override
  void initState() {
    super.initState();
    controller = Get.put(SplashController());
    introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1650),
    )..repeat();
    entrance = CurvedAnimation(
      parent: introController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    introController.dispose();
    pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF07111F) : const Color(0xFFF7FAFE),
      body: SafeArea(
        child: Stack(
          children: [
            _BackgroundLogo(isDark: isDark),
            const Align(
              alignment: AlignmentDirectional.topEnd,
              child: LanguageCapsule(),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSize.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 3),
                  ListenableBuilder(
                    listenable: Listenable.merge([
                      introController,
                      pulseController,
                    ]),
                    builder: (context, _) {
                      final introValue = entrance.value;

                      return Opacity(
                        opacity: introValue.clamp(0.0, 1.0),
                        child: Transform.translate(
                          offset: Offset(0, 18 * (1 - introValue)),
                          child: Transform.scale(
                            scale: 0.92 + (introValue * 0.08),
                            child: _SplashIdentity(
                              pulse: pulseController.value,
                              scheme: scheme,
                              isDark: isDark,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const Spacer(flex: 2),
                  _SplashFooter(controller: controller, scheme: scheme),
                  SizedBox(height: AppSize.xlH),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackgroundLogo extends StatelessWidget {
  final bool isDark;

  const _BackgroundLogo({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final size = (MediaQuery.sizeOf(context).width * 0.9).clamp(280.0, 430.0);

    return IgnorePointer(
      child: Align(
        alignment: const Alignment(0, -0.14),
        child: Opacity(
          opacity: isDark ? 0.025 : 0.055,
          child: Image.asset(
            'assets/logo.png',
            width: size,
            height: size,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _SplashIdentity extends StatelessWidget {
  final double pulse;
  final ColorScheme scheme;
  final bool isDark;

  const _SplashIdentity({
    required this.pulse,
    required this.scheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final ringOpacity = (1 - pulse).clamp(0.0, 1.0);
    final logoSize = (MediaQuery.sizeOf(context).width * 0.28).clamp(
      108.0,
      138.0,
    );

    return Column(
      children: [
        SizedBox(
          width: logoSize + 84,
          height: logoSize + 84,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _PulseRing(
                size: logoSize + 26 + (pulse * 42),
                color: scheme.primary.withValues(alpha: 0.20 * ringOpacity),
              ),
              _PulseRing(
                size: logoSize + 52 + (pulse * 38),
                color: AppColors.emergencyRed.withValues(
                  alpha: 0.10 * ringOpacity,
                ),
              ),
              _LogoDisc(size: logoSize, scheme: scheme, isDark: isDark),
              Positioned(right: 17, bottom: 28, child: const _SosBadge()),
            ],
          ),
        ),
        SizedBox(height: AppSize.lH),
        Text(
          'splash.brand'.tr,
          textAlign: TextAlign.center,
          style: AppTextStyling.title_30M.copyWith(
            color: scheme.primary,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        SizedBox(height: AppSize.xsH),
        Text(
          'splash.tagline'.tr,
          textAlign: TextAlign.center,
          style: AppTextStyling.body_14M.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _PulseRing extends StatelessWidget {
  final double size;
  final Color color;

  const _PulseRing({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
    );
  }
}

class _LogoDisc extends StatelessWidget {
  final double size;
  final ColorScheme scheme;
  final bool isDark;

  const _LogoDisc({
    required this.size,
    required this.scheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: scheme.primary.withValues(alpha: isDark ? 0.18 : 0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: isDark ? 0.22 : 0.14),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipOval(child: Image.asset('assets/logo.png', fit: BoxFit.cover)),
    );
  }
}

class _SosBadge extends StatelessWidget {
  const _SosBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.emergencyRed,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: AppColors.emergencyRed.withValues(alpha: 0.24),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.notifications_active_rounded,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            'onboarding.badge.sos'.tr,
            style: AppTextStyling.body_12S.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashFooter extends StatelessWidget {
  final SplashController controller;
  final ColorScheme scheme;

  const _SplashFooter({required this.controller, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1900),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 5,
                backgroundColor: scheme.primary.withValues(alpha: 0.10),
                valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
              ),
            );
          },
        ),
        SizedBox(height: AppSize.mH),
        Obx(
          () => Text(
            _getStatusMessage(controller.userStatus.value),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyling.body_12S.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _getStatusMessage(UserStatus status) {
    switch (status) {
      case UserStatus.notAuthenticated:
        return 'splash.status.preparing'.tr;
      case UserStatus.authenticated:
        return 'splash.status.loading_profile'.tr;
      case UserStatus.pending:
        return 'splash.status.checking_verification'.tr;
      case UserStatus.verified:
        return 'splash.status.opening_dashboard'.tr;
    }
  }
}
