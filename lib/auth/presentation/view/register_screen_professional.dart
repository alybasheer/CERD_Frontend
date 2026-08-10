import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fyp_source_code/auth/presentation/controller/auth_contrl.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_colors.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_text.dart';
import 'package:fyp_source_code/utilities/reuse_components/spacing.dart';
import 'package:fyp_source_code/utilities/reuse_widgets/shimmer_loading.dart';
import 'package:get/get.dart';

class RegisterScreenProfessional extends StatelessWidget {
  const RegisterScreenProfessional({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.put(AuthController());
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor:
          theme.brightness == Brightness.dark
              ? theme.scaffoldBackgroundColor
              : const Color(0xFFF6F9FD),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final logoWatermarkSize = (constraints.maxWidth * 0.92).clamp(
              260.0,
              420.0,
            );

            return Stack(
              children: [
                _LogoWatermark(size: logoWatermarkSize),
                SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.symmetric(horizontal: AppSize.l),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: AppSize.mH,
                        bottom: AppSize.lH,
                      ),
                      child: Form(
                        key: authController.registerFormKey,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 430),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _TopBar(scheme: scheme),
                                SizedBox(height: AppSize.lH),
                                _RegisterHeader(scheme: scheme),
                                SizedBox(height: AppSize.lH),
                                _RegisterCard(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _RegisterTextField(
                                        controller:
                                            authController.usernameController,
                                        label: 'auth.full_name.label'.tr,
                                        hint: 'auth.full_name.hint'.tr,
                                        icon: Icons.person_outline_rounded,
                                        textInputAction: TextInputAction.next,
                                        validator: authController.validateName,
                                      ),
                                      SizedBox(height: AppSize.mH),
                                      _RegisterTextField(
                                        controller:
                                            authController.emailController,
                                        label: 'auth.email.label'.tr,
                                        hint: 'auth.email.hint'.tr,
                                        icon: Icons.email_outlined,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        textInputAction: TextInputAction.next,
                                        validator: authController.validateEmail,
                                      ),
                                      SizedBox(height: AppSize.mH),
                                      Obx(
                                        () => _RegisterTextField(
                                          controller:
                                              authController.passController,
                                          label: 'auth.password.label'.tr,
                                          hint: 'auth.password.create_hint'.tr,
                                          icon: Icons.lock_outline_rounded,
                                          obscureText:
                                              !authController
                                                  .isPasswordVisible
                                                  .value,
                                          textInputAction: TextInputAction.next,
                                          validator:
                                              authController.validatePassword,
                                          suffixIcon: IconButton(
                                            tooltip:
                                                authController
                                                        .isPasswordVisible
                                                        .value
                                                        ? 'auth.password.hide'.tr
                                                        : 'auth.password.show'.tr,
                                            icon: Icon(
                                              authController
                                                      .isPasswordVisible
                                                      .value
                                                  ? Icons.visibility_rounded
                                                  : Icons
                                                      .visibility_off_rounded,
                                            ),
                                            onPressed:
                                                authController
                                                    .togglePasswordVisibility,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: AppSize.sH),
                                      _PasswordRequirements(
                                        controller:
                                            authController.passController,
                                      ),
                                      SizedBox(height: AppSize.mH),
                                      Obx(
                                        () => _RegisterTextField(
                                          controller:
                                              authController
                                                  .confirmPassController,
                                          label: 'auth.password.confirm_label'.tr,
                                          hint: 'auth.password.confirm_hint'.tr,
                                          icon: Icons.lock_reset_rounded,
                                          obscureText:
                                              !authController
                                                  .isConfirmPasswordVisible
                                                  .value,
                                          textInputAction: TextInputAction.done,
                                          validator:
                                              authController
                                                  .validateConfirmPassword,
                                          suffixIcon: IconButton(
                                            tooltip:
                                                authController
                                                        .isConfirmPasswordVisible
                                                        .value
                                                        ? 'auth.password.hide'.tr
                                                        : 'auth.password.show'.tr,
                                            icon: Icon(
                                              authController
                                                      .isConfirmPasswordVisible
                                                      .value
                                                  ? Icons.visibility_rounded
                                                  : Icons
                                                      .visibility_off_rounded,
                                            ),
                                            onPressed:
                                                authController
                                                    .toggleConfirmPasswordVisibility,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: AppSize.lH),
                                      _CreateAccountButton(
                                        controller: authController,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: AppSize.mH),
                                _SignInPrompt(scheme: scheme),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LogoWatermark extends StatelessWidget {
  final double size;

  const _LogoWatermark({required this.size});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IgnorePointer(
      child: Align(
        alignment: const Alignment(0, -0.78),
        child: Opacity(
          opacity: isDark ? 0.04 : 0.075,
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

class _TopBar extends StatelessWidget {
  final ColorScheme scheme;

  const _TopBar({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: scheme.surface.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: Get.back,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 42,
              height: 42,
              child: Icon(Icons.arrow_back_rounded, color: scheme.primary),
            ),
          ),
        ),
        SizedBox(width: AppSize.s),
        Expanded(
          child: Text(
            'auth.register.top'.tr,
            maxLines: 2,
            overflow: TextOverflow.fade,
            softWrap: true,
            style: AppTextStyling.body_12S.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _RegisterHeader extends StatelessWidget {
  final ColorScheme scheme;

  const _RegisterHeader({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 66,
          height: 66,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            shape: BoxShape.circle,
            border: Border.all(color: scheme.primary.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.10),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset('assets/logo.png', fit: BoxFit.cover),
          ),
        ),
        SizedBox(height: AppSize.mH),
        Text(
          'auth.register.title'.tr,
          textAlign: TextAlign.center,
          style: AppTextStyling.title_30M.copyWith(
            color: scheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: AppSize.xsH),
        Text(
          'auth.register.subtitle'.tr,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.fade,
          style: AppTextStyling.body_14M.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _RegisterCard extends StatelessWidget {
  final Widget child;

  const _RegisterCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(AppSize.m),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _RegisterTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;

  const _RegisterTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyling.body_12S.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: AppSize.xsH),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          style: AppTextStyling.body_14M.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyling.body_14M.copyWith(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.72),
            ),
            filled: true,
            fillColor:
                theme.brightness == Brightness.dark
                    ? theme.inputDecorationTheme.fillColor
                    : const Color(0xFFF8FAFC),
            prefixIcon: Icon(icon, color: scheme.primary, size: 21),
            suffixIcon:
                suffixIcon == null
                    ? null
                    : IconTheme(
                      data: IconThemeData(color: scheme.onSurfaceVariant),
                      child: suffixIcon!,
                    ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppSize.m,
              vertical: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: scheme.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _PasswordRequirements extends StatelessWidget {
  final TextEditingController controller;

  const _PasswordRequirements({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final password = controller.text;
        final requirements = [
          _RequirementData(
            label: 'auth.password.req.characters'.tr,
            isMet: password.length >= 6,
          ),
          _RequirementData(
            label: 'auth.password.req.uppercase'.tr,
            isMet: RegExp(r'[A-Z]').hasMatch(password),
          ),
          _RequirementData(
            label: 'auth.password.req.lowercase'.tr,
            isMet: RegExp(r'[a-z]').hasMatch(password),
          ),
          _RequirementData(
            label: 'auth.password.req.number'.tr,
            isMet: RegExp(r'[0-9]').hasMatch(password),
          ),
        ];

        return Container(
          padding: EdgeInsets.all(AppSize.s),
          decoration: BoxDecoration(
            color:
                theme.brightness == Brightness.dark
                    ? scheme.surfaceContainerHighest.withValues(alpha: 0.35)
                    : scheme.primary.withValues(alpha: 0.055),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.shield_outlined, size: 17, color: scheme.primary),
                  SizedBox(width: AppSize.xs),
                  Text(
                    'auth.password.requirements'.tr,
                    style: AppTextStyling.body_12S.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSize.xsH),
              Wrap(
                spacing: AppSize.xs,
                runSpacing: AppSize.xsH,
                children:
                    requirements
                        .map((item) => _RequirementChip(item: item))
                        .toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RequirementChip extends StatelessWidget {
  final _RequirementData item;

  const _RequirementChip({required this.item});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = item.isMet ? AppColors.reliefGreen : scheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color:
            item.isMet
                ? AppColors.reliefGreen.withValues(alpha: 0.10)
                : scheme.surface.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            item.isMet ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 15,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            item.label,
            style: AppTextStyling.body_12S.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RequirementData {
  final String label;
  final bool isMet;

  const _RequirementData({required this.label, required this.isMet});
}

class _CreateAccountButton extends StatelessWidget {
  final AuthController controller;

  const _CreateAccountButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        height: AppSize.buttonHeight,
        child: ElevatedButton(
          onPressed:
              controller.isLoading.value
                  ? null
                  : () => controller.onRegisterClick(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.safetyBlue,
            disabledBackgroundColor: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.12),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child:
              controller.isLoading.value
                  ? AppShimmer(
                    child: Container(
                      height: 18,
                      width: 118,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  )
                  : Text(
                    'auth.register.title'.tr,
                    style: AppTextStyling.body_14M.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
        ),
      ),
    );
  }
}

class _SignInPrompt extends StatelessWidget {
  final ColorScheme scheme;

  const _SignInPrompt({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: 'auth.have_account'.tr,
              style: AppTextStyling.body_12S.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            TextSpan(
              text: 'auth.sign_in'.tr,
              style: AppTextStyling.body_12S.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w800,
              ),
              recognizer: TapGestureRecognizer()..onTap = () => Get.back(),
            ),
          ],
        ),
      ),
    );
  }
}
