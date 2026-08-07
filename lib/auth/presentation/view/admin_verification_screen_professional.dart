import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fyp_source_code/volunteer_side/volunteer_verification/presentation/controller/volunteer_verification_controller.dart';
import 'package:fyp_source_code/auth/presentation/view/widgets/verification_image_picker.dart';
import 'package:fyp_source_code/auth/presentation/view/widgets/verification_submit_button.dart';
import 'package:fyp_source_code/auth/presentation/view/widgets/verification_text_field.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_colors.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_text.dart';
import 'package:fyp_source_code/utilities/reuse_components/spacing.dart';
import 'package:fyp_source_code/utilities/reuse_widgets/app_bar.dart';
import 'package:get/get.dart';

class AdminVerificationScreenProfessional extends StatelessWidget {
  const AdminVerificationScreenProfessional({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(VolunteerVerificationController());

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: WeHelpAppBar(
        title: 'verification.title',
        subtitle: 'verification.subtitle',
        showBack: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSize.l),
            child: Form(
              key: controller.verificationFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSize.lHeight,

                  // HEADER
                  Text(
                    'verification.complete_profile'.tr,
                    style: AppTextStyling.title_30M.copyWith(
                      color: AppColors.safetyBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppSize.mHeight,
                  Text(
                    'verification.subtitle'.tr,
                    style: AppTextStyling.body_12S.copyWith(
                      color: AppColors.grey,
                      height: 1.5,
                    ),
                  ),
                  AppSize.xxxlHeight,

                  // PROFILE PHOTO
                  Obx(
                    () => VerificationImagePicker(
                      label: 'verification.profile_photo_label'.tr,
                      helperText: 'verification.profile_photo_helper'.tr,
                      imageBytes: controller.profilePhoto.value?.bytes,
                      fileName: controller.profilePhoto.value?.name,
                      onTap: () => controller.pickProfilePhoto(),
                      isLoading: controller.isSubmitting.value,
                    ),
                  ),

                  // FULL NAME FIELD
                  VerificationTextField(
                    label: 'verification.full_name'.tr,
                    hintText: 'verification.full_name_hint'.tr,
                    controller: controller.fullNameController,
                    validator: (val) => controller.validateFullName(val),
                    keyboardType: TextInputType.name,
                    prefixIcon: Icons.person_outline,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(
                          r"[a-zA-Z\s']",
                        ), // Allow only letters, spaces, and apostrophes
                      ),
                    ],
                  ),

                  // EMAIL FIELD
                  VerificationTextField(
                    label: 'auth.email.label'.tr,
                    hintText: 'auth.email.hint'.tr,
                    controller: controller.emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    validator: (val) => controller.validateEmail(val),
                  ),

                  // EXPERTISE FIELD
                  VerificationTextField(
                    label: 'verification.expertise'.tr,
                    hintText: 'verification.expertise_hint'.tr,
                    controller: controller.expertiseController,
                    validator: (val) => controller.validateExpertise(val),
                    keyboardType: TextInputType.text,
                    prefixIcon: Icons.school_outlined,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(
                          r"[a-zA-Z0-9\s,&\-]",
                        ), // Allow letters, numbers, spaces, commas, ampersands, hyphens
                      ),
                    ],
                  ),

                  // CNIC FIELD
                  VerificationTextField(
                    label: 'verification.cnic_number'.tr,
                    hintText: 'verification.cnic_format_hint'.tr,
                    controller: controller.cnicController,
                    validator: (val) => controller.validateCNIC(val),
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.card_membership_outlined,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[0-9\-]'),
                      ), // Only digits and hyphens
                    ],
                  ),

                  // CITY FIELD
                  VerificationTextField(
                    label: 'verification.city'.tr,
                    hintText: 'verification.city_hint'.tr,
                    controller: controller.cityController,
                    validator: (val) => controller.validateCity(val),
                    keyboardType: TextInputType.text,
                    prefixIcon: Icons.location_city_outlined,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(
                          r"[a-zA-Z\s'-]",
                        ), // Allow letters, spaces, hyphens, apostrophes
                      ),
                    ],
                  ),

                  // LOCATION FIELD
                  VerificationTextField(
                    label: 'verification.location_address'.tr,
                    hintText: 'verification.location_hint'.tr,
                    controller: controller.locationController,
                    validator: (val) => controller.validateLocation(val),
                    keyboardType: TextInputType.text,
                    prefixIcon: Icons.location_on_outlined,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(
                          r"[a-zA-Z0-9\s,/.()'-]",
                        ), // Allow alphanumeric, spaces, commas, hyphens, slashes, dots, parentheses
                      ),
                    ],
                  ),

                  // DESCRIPTION/REASON FIELD
                  VerificationTextField(
                    label: 'verification.why_volunteer'.tr,
                    hintText: 'verification.why_volunteer_hint'.tr,
                    controller: controller.descriptionController,
                    validator: (val) => controller.validateDescription(val),
                    keyboardType: TextInputType.multiline,
                    maxLines: 5,
                    prefixIcon: Icons.edit_outlined,
                  ),

                  AppSize.xxxlHeight,

                  // SUBMIT BUTTON
                  Obx(
                    () => VerificationSubmitButton(
                      isLoading: controller.isSubmitting.value,
                      onPressed: () => controller.submitVerification(),
                      label: 'verification.submit_btn'.tr,
                    ),
                  ),

                  AppSize.xxxlHeight,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
