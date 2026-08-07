import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fyp_source_code/auth/presentation/controller/auth_contrl.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_colors.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_text.dart';
import 'package:fyp_source_code/utilities/reuse_components/spacing.dart';
import 'package:fyp_source_code/utilities/reuse_widgets/shimmer_loading.dart';
import 'package:get/get.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.put(AuthController());
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableHeight = constraints.maxHeight;
            final logoSize = (availableHeight * 0.14).clamp(82.0, 118.0);

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: AppSize.l),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSize.lH),
                  child: Form(
                    key: authController.loginFormKey,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 430),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: availableHeight * 0.035),
                          _LoginHeader(scheme: scheme, logoSize: logoSize),
                          SizedBox(height: AppSize.lH),
                          _LoginCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _AuthTextField(
                                  controller: authController.emailController,
                                  label: 'auth.email.label'.tr,
                                  hint: 'auth.email.hint'.tr,
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: authController.validateEmail,
                                ),
                                SizedBox(height: AppSize.mH),
                                Obx(
                                  () => _AuthTextField(
                                    controller: authController.passController,
                                    label: 'auth.password.label'.tr,
                                    hint: 'auth.password.hint'.tr,
                                    icon: Icons.lock_outlined,
                                    obscureText:
                                        !authController.isPasswordVisible.value,
                                    validator: authController.validatePassword,
                                    suffixIcon: IconButton(
                                      tooltip:
                                          authController.isPasswordVisible.value
                                              ? 'auth.password.hide'.tr
                                              : 'auth.password.show'.tr,
                                      icon: Icon(
                                        authController.isPasswordVisible.value
                                            ? Icons.visibility_rounded
                                            : Icons.visibility_off_rounded,
                                      ),
                                      onPressed:
                                          authController
                                              .togglePasswordVisibility,
                                    ),
                                  ),
                                ),
                                SizedBox(height: AppSize.sH),
                                _LoginOptions(controller: authController),
                                SizedBox(height: AppSize.lH),
                                _SignInButton(controller: authController),
                                SizedBox(height: AppSize.mH),
                                _GoogleSignInButton(controller: authController),
                              ],
                            ),
                          ),
                          SizedBox(height: AppSize.mH),
                          _SignUpPrompt(scheme: scheme),
                          SizedBox(height: availableHeight * 0.035),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LoginHeader extends StatelessWidget {
  final ColorScheme scheme;
  final double logoSize;

  const _LoginHeader({required this.scheme, required this.logoSize});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: logoSize,
          height: logoSize,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: scheme.primary.withValues(alpha: 0.12),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset('assets/logo.png', fit: BoxFit.cover),
          ),
        ),
        SizedBox(height: AppSize.lH),
        Text(
          'auth.login.welcome'.tr,
          textAlign: TextAlign.center,
          style: AppTextStyling.title_30M.copyWith(
            color: scheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: AppSize.xsH),
        Text(
          'auth.login.subtitle'.tr,
          textAlign: TextAlign.center,
          style: AppTextStyling.body_14M.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _LoginCard extends StatelessWidget {
  final Widget child;

  const _LoginCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(AppSize.m),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;

  const _AuthTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
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
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: AppSize.xsH),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          keyboardType: keyboardType,
          style: AppTextStyling.body_14M.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyling.body_14M.copyWith(
              color: scheme.onSurfaceVariant,
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

class _LoginOptions extends StatelessWidget {
  final AuthController controller;

  const _LoginOptions({required this.controller});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final rememberMe = Obx(
      () => InkWell(
        onTap:
            () => controller.toggleRememberMe(!controller.isRememberMe.value),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Checkbox(
                  value: controller.isRememberMe.value,
                  onChanged:
                      (value) => controller.toggleRememberMe(value ?? false),
                  activeColor: scheme.primary,
                  checkColor: scheme.onPrimary,
                  side: BorderSide(color: scheme.outline, width: 1.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              SizedBox(width: AppSize.xs),
              Flexible(
                child: Text(
                  'auth.remember_me'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  style: AppTextStyling.body_12S.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(children: [Expanded(child: rememberMe)]);
      },
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  final AuthController controller;

  const _GoogleSignInButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Obx(
      () => SizedBox(
        width: double.infinity,
        height: AppSize.buttonHeight,
        child: OutlinedButton.icon(
          onPressed:
              controller.isLoading.value
                  ? null
                  : () => controller.signInWithGoogle(),
          icon: Image.asset(
            'assets/icons/google_logo.png',
            height: 20,
            width: 20,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.login, size: 20),
          ),
          label: Text(
            'auth.sign_in_google'.tr,
            style: AppTextStyling.body_14M.copyWith(
              color:
                  controller.isLoading.value
                      ? scheme.onSurface.withValues(alpha: 0.38)
                      : scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: theme.dividerColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
            disabledBackgroundColor:
                scheme.onSurface.withValues(alpha: 0.04),
          ),
        ),
      ),
    );
  }
}

class _SignInButton extends StatelessWidget {
  final AuthController controller;

  const _SignInButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        height: AppSize.buttonHeight,
        child: ElevatedButton(
          onPressed: controller.isLoading.value ? null : controller.onLogin,
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
                      width: 88,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  )
                  : Text(
                    'auth.sign_in'.tr,
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

class _SignUpPrompt extends StatelessWidget {
  final ColorScheme scheme;

  const _SignUpPrompt({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: 'auth.no_account'.tr,
              style: AppTextStyling.body_12S.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            TextSpan(
              text: 'auth.sign_up'.tr,
              style: AppTextStyling.body_12S.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w800,
              ),
              recognizer:
                  TapGestureRecognizer()..onTap = () => Get.toNamed('/signup'),
            ),
          ],
        ),
      ),
    );
  }
}
