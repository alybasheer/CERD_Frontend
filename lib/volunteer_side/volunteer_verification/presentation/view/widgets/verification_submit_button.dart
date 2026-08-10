import 'package:flutter/material.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_colors.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_text.dart';
import 'package:fyp_source_code/utilities/reuse_components/spacing.dart';
import 'package:fyp_source_code/utilities/reuse_widgets/shimmer_loading.dart';
import 'package:get/get.dart';

class VerificationSubmitButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  final String? label;

  const VerificationSubmitButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppSize.buttonHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.safetyBlue,
          disabledBackgroundColor: AppColors.lightGrey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child:
            isLoading
                ? AppShimmer(
                  child: Container(
                    height: 18,
                    width: 110,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                )
                : Text(
                  label ?? 'verification.submit_btn'.tr,
                  style: AppTextStyling.body_14M.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
      ),
    );
  }
}
