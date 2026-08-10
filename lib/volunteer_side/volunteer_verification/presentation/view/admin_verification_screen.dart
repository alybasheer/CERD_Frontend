import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fyp_source_code/auth/presentation/view/widgets/verification_image_picker.dart';
import 'package:fyp_source_code/auth/presentation/view/widgets/verification_submit_button.dart';
import 'package:fyp_source_code/auth/presentation/view/widgets/verification_text_field.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_colors.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_text.dart';
import 'package:fyp_source_code/utilities/reuse_components/spacing.dart';
import 'package:fyp_source_code/utilities/reuse_widgets/app_bar.dart';
import 'package:fyp_source_code/volunteer_side/volunteer_verification/presentation/controller/volunteer_verification_controller.dart';
import 'package:get/get.dart';

class VolunteerVerficationScreen extends StatelessWidget {
  const VolunteerVerficationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(VolunteerVerificationController());
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: WeHelpAppBar(
        title: 'verification.title'.tr,
        subtitle: 'verification.subtitle'.tr,
        showBack: true,
      ),
      bottomNavigationBar: SafeArea(
        minimum: EdgeInsets.fromLTRB(AppSize.l, 8, AppSize.l, AppSize.m),
        child: Obx(
          () => VerificationSubmitButton(
            isLoading: controller.isSubmitting.value,
            onPressed: controller.submitVerification,
            label: 'verification.submit_btn'.tr,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(AppSize.l, AppSize.m, AppSize.l, 18),
          child: Form(
            key: controller.verificationFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IntroPanel(scheme: scheme),
                AppSize.lHeight,
                _SectionTitle(
                  title: 'verification.section_account'.tr,
                  subtitle: 'verification.section_account_sub'.tr,
                ),
                _ReadOnlyInfoField(
                  label: 'verification.account_email'.tr,
                  value: controller.emailController.text,
                  icon: Icons.email_outlined,
                ),
                AppSize.xxlHeight,
                _SectionTitle(
                  title: 'verification.section_identity'.tr,
                  subtitle:
                      'verification.section_identity_sub'.tr,
                ),
                Obx(
                  () => VerificationImagePicker(
                    label: 'verification.cnic_front_label'.tr,
                    helperText:
                        'verification.cnic_front_helper'.tr,
                    isRequired: true,
                    imageBytes: controller.cnicFrontPhoto.value?.bytes,
                    fileName: controller.cnicFrontPhoto.value?.name,
                    onTap: controller.pickCnicFrontPhoto,
                    isLoading: controller.isSubmitting.value,
                  ),
                ),
                Obx(
                  () => VerificationImagePicker(
                    label: 'verification.cnic_back_label'.tr,
                    helperText:
                        'verification.cnic_back_helper'.tr,
                    isRequired: true,
                    imageBytes: controller.cnicBackPhoto.value?.bytes,
                    fileName: controller.cnicBackPhoto.value?.name,
                    onTap: controller.pickCnicBackPhoto,
                    isLoading: controller.isSubmitting.value,
                  ),
                ),
                Obx(
                  () => VerificationImagePicker(
                    label: 'verification.profile_photo_label'.tr,
                    helperText:
                        'verification.profile_photo_helper'.tr,
                    imageBytes: controller.profilePhoto.value?.bytes,
                    fileName: controller.profilePhoto.value?.name,
                    onTap: controller.pickProfilePhoto,
                    isLoading: controller.isSubmitting.value,
                  ),
                ),
                Obx(
                  () => _UploadProgress(
                    readyCount:
                        (controller.cnicFrontPhoto.value == null ? 0 : 1) +
                        (controller.cnicBackPhoto.value == null ? 0 : 1),
                  ),
                ),
                AppSize.xxlHeight,
                _SectionTitle(
                  title: 'verification.section_personal'.tr,
                  subtitle:
                      'verification.section_personal_sub'.tr,
                ),
                 VerificationTextField(
                  label: 'verification.full_name'.tr,
                  hintText: 'verification.full_name_hint'.tr,
                  controller: controller.fullNameController,
                  validator: controller.validateFullName,
                  keyboardType: TextInputType.name,
                  prefixIcon: Icons.person_outline,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s']")),
                  ],
                ),
                VerificationTextField(
                  label: 'verification.expertise'.tr,
                  hintText: 'verification.expertise_hint'.tr,
                  controller: controller.expertiseController,
                  validator: controller.validateExpertise,
                  keyboardType: TextInputType.text,
                  prefixIcon: Icons.school_outlined,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r"[a-zA-Z0-9\s,&\-]"),
                    ),
                  ],
                ),
                VerificationTextField(
                  label: 'verification.cnic_number'.tr,
                  hintText: 'verification.cnic_hint'.tr,
                  controller: controller.cnicController,
                  validator: controller.validateCNIC,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.badge_outlined,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9\-]')),
                  ],
                ),
                AppSize.xxlHeight,
                _SectionTitle(
                  title: 'verification.section_location'.tr,
                  subtitle:
                      'verification.section_location_sub'.tr,
                ),
                Obx(
                  () => _CurrentLocationButton(
                    isLoading: controller.isResolvingLocation.value,
                    hasCoordinates:
                        controller.latitude.value != null &&
                        controller.longitude.value != null,
                    onPressed: controller.useCurrentLocation,
                  ),
                ),
                AppSize.mHeight,
                VerificationTextField(
                  label: 'verification.city'.tr,
                  hintText: 'verification.city_hint'.tr,
                  controller: controller.cityController,
                  validator: controller.validateCity,
                  keyboardType: TextInputType.text,
                  prefixIcon: Icons.location_city_outlined,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s'-]")),
                  ],
                ),
                VerificationTextField(
                  label: 'verification.location_address'.tr,
                  hintText: 'verification.location_hint'.tr,
                  controller: controller.locationController,
                  validator: controller.validateLocation,
                  keyboardType: TextInputType.text,
                  prefixIcon: Icons.location_on_outlined,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r"[a-zA-Z0-9\s,\-/\.()']"),
                    ),
                  ],
                ),
                Obx(() {
                  final lat = controller.latitude.value;
                  final lng = controller.longitude.value;
                  if (lat == null || lng == null) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 14),
                    child: Text(
                      '${'verification.gps_attached'.tr}: ${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                      style: AppTextStyling.body_12S.copyWith(
                        color: AppColors.reliefGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                }),
                AppSize.xxlHeight,
                _SectionTitle(
                  title: 'verification.section_motivation'.tr,
                  subtitle:
                      'verification.section_motivation_sub'.tr,
                ),
                VerificationTextField(
                  label: 'verification.why_volunteer'.tr,
                  hintText: 'verification.why_volunteer_hint'.tr,
                  controller: controller.descriptionController,
                  validator: controller.validateDescription,
                  keyboardType: TextInputType.multiline,
                  maxLines: 5,
                  prefixIcon: Icons.edit_outlined,
                ),
                AppSize.lHeight,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IntroPanel extends StatelessWidget {
  final ColorScheme scheme;

  const _IntroPanel({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'verification.intro_title'.tr,
                  maxLines: 2,
                  style: AppTextStyling.title_18M.copyWith(
                    color: AppColors.safetyBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'verification.intro_description'.tr,
                  style: AppTextStyling.body_12S.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyling.body_14M.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTextStyling.body_12S.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadProgress extends StatelessWidget {
  final int readyCount;

  const _UploadProgress({required this.readyCount});

  @override
  Widget build(BuildContext context) {
    final complete = readyCount == 2;
    final color = complete ? AppColors.reliefGreen : AppColors.amberOrange;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            complete ? Icons.check_circle_rounded : Icons.info_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'verification.upload_progress'.trParams({'count': readyCount.toString()}),
              style: AppTextStyling.body_12S.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentLocationButton extends StatelessWidget {
  final bool isLoading;
  final bool hasCoordinates;
  final VoidCallback onPressed;

  const _CurrentLocationButton({
    required this.isLoading,
    required this.hasCoordinates,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon:
            isLoading
                ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                : Icon(
                  hasCoordinates
                      ? Icons.my_location_rounded
                      : Icons.location_searching_rounded,
                ),
        label: Text(
          isLoading
              ? 'verification.detecting_location'.tr
              : hasCoordinates
              ? 'verification.update_location'.tr
              : 'verification.use_location'.tr,
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor:
              hasCoordinates ? AppColors.reliefGreen : scheme.primary,
          side: BorderSide(
            color:
                hasCoordinates
                    ? AppColors.reliefGreen.withValues(alpha: 0.45)
                    : scheme.outlineVariant,
          ),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyInfoField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ReadOnlyInfoField({
    required this.label,
    required this.value,
    required this.icon,
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
        AppSize.xsHeight,
        Container(
          height: 54,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: theme.inputDecorationTheme.fillColor ?? scheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(icon, color: scheme.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value.trim().isEmpty ? 'verification.no_email'.tr : value.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyling.body_14M.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
