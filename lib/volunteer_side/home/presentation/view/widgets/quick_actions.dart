import 'package:flutter/material.dart';
import 'package:fyp_source_code/routing/route_names.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_colors.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_text.dart';
import 'package:fyp_source_code/utilities/reuse_components/spacing.dart';
import 'package:get/get.dart';

Widget quickActionsSection() {
  return SliverToBoxAdapter(
    child: Padding(
      padding: EdgeInsets.all(AppSize.m),
      child: Row(
        children: [
          actionButton(
            icon: Icons.notifications_active,
            label: 'common.alerts'.tr,
            color: AppColors.pureWhite,
            backgroundColor: AppColors.emergencyRed,
            onTap: () => Get.toNamed(RouteNames.alerts),
          ),
          SizedBox(width: AppSize.m),
          actionButton(
            icon: Icons.people_alt,
            label: 'common.coordination'.tr,
            color: AppColors.pureWhite,
            backgroundColor: AppColors.steelBlue,
            onTap: () => Get.toNamed(RouteNames.coordination),
          ),
        ],
      ),
    ),
  );
}

Widget actionButton({
  required IconData icon,
  required String label,
  required Color color,
  required Color backgroundColor,
  required VoidCallback onTap,
}) {
  final scheme = Get.theme.colorScheme;

  return Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: backgroundColor.withValues(alpha: 0.16)),
        ),
        padding: EdgeInsets.symmetric(
          vertical: AppSize.sH,
          horizontal: AppSize.s,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: backgroundColor, size: 20),
            SizedBox(width: AppSize.s),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyling.body_14M.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
