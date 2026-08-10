import 'package:flutter/material.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_colors.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_text.dart';
import 'package:fyp_source_code/utilities/reuse_components/spacing.dart';
import 'package:get/get.dart';

class VerificationImagePicker extends StatelessWidget {
  final String? selectedImagePath;
  final VoidCallback onTap;
  final bool isLoading;

  const VerificationImagePicker({
    super.key,
    this.selectedImagePath,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'verification.profile_photo_label'.tr,
          style: AppTextStyling.body_12S.copyWith(
            color: AppColors.darkGray,
            fontWeight: FontWeight.w600,
          ),
        ),
        AppSize.mHeight,
        GestureDetector(
          onTap: isLoading ? null : onTap,
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color:
                  selectedImagePath == null
                      ? Color(0xFFF5F7FA)
                      : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    selectedImagePath == null
                        ? AppColors.lightBorderGray
                        : AppColors.safetyBlue,
                width: 2,
              ),
            ),
            child:
                selectedImagePath == null
                    ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 48,
                          color: AppColors.steelBlue,
                        ),
                        AppSize.mHeight,
                        Text(
                          'verification.tap_to_upload_photo'.tr,
                          style: AppTextStyling.body_12S.copyWith(
                            color: AppColors.steelBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        AppSize.sHeight,
                        Text(
                          'verification.upload_hint_photo'.tr,
                          style: AppTextStyling.body_12S.copyWith(
                            color: AppColors.grey,
                          ),
                        ),
                      ],
                    )
                    : Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          color: Colors.grey[300],
                          child: Center(
                            child: Icon(
                              Icons.image,
                              size: 48,
                              color: AppColors.steelBlue,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: isLoading ? null : onTap,
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.emergencyRed,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
          ),
        ),
        AppSize.lHeight,
      ],
    );
  }
}
