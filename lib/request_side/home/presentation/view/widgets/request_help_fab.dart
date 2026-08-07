import 'package:flutter/material.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_colors.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_text.dart';
import 'package:fyp_source_code/utilities/reuse_components/spacing.dart';
import 'package:get/get.dart';

class RequestHelpFab extends StatelessWidget {
  final VoidCallback onPressed;

  const RequestHelpFab({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: AppColors.emergencyRed,
      icon: const Icon(Icons.sos_rounded, color: AppColors.pureWhite),
      label: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSize.s),
        child: Text(
          'request_help.title'.tr,
          style: AppTextStyling.body_14M.copyWith(
            color: AppColors.pureWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
