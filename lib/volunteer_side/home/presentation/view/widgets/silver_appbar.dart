import 'package:flutter/material.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_colors.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_text.dart';
import 'package:fyp_source_code/utilities/reuse_components/spacing.dart';
import 'package:fyp_source_code/volunteer_side/home/presentation/view/widgets/help_toggle.dart';
import 'package:fyp_source_code/volunteer_side/home/presentation/view/widgets/stat_card.dart';
import 'package:get/get.dart';

Widget sliverAppBar({
  required int completedCount,
  required double rating,
  required int ratingCount,
  required String fullName,
  required String locationName,
}) {
  final theme = Get.theme;
  final scheme = theme.colorScheme;
  final isDark = theme.brightness == Brightness.dark;

  return SliverToBoxAdapter(
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.steelBlue.withValues(alpha: 0.88),
            AppColors.safetyBlue.withValues(alpha: 0.86),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.safetyBlue.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: EdgeInsets.all(AppSize.m),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(
                color: AppColors.steelBlue.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            padding: EdgeInsets.all(AppSize.m),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppColors.steelBlue, AppColors.safetyBlue],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.steelBlue.withValues(alpha: 0.22),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(3),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.steelBlue.withValues(alpha: 0.1),
                    child: Icon(
                      Icons.person_2_rounded,
                      color: AppColors.pureWhite,
                      size: 40,
                    ),
                  ),
                ),
                SizedBox(width: AppSize.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: AppTextStyling.title_18M.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(height: AppSize.xsH),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 16,
                            color: AppColors.steelBlue,
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              locationName.trim().isEmpty
                                  ? 'volunteer.home.resolving_area'.tr
                                  : locationName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyling.body_12S.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Tooltip(
                  message: 'volunteer.home.alerts'.tr,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        colors: [AppColors.emergencyRed, AppColors.amberOrange],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.emergencyRed.withValues(alpha: 0.22),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(10),
                    child: Icon(
                      Icons.notifications_rounded,
                      color: AppColors.pureWhite,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSize.sH),
          const HelpToggle(),
          SizedBox(height: AppSize.mH),
          Row(
            children: [
              Expanded(
                child: statCard(
                  completedCount.toString(),
                  'volunteer.home.completed'.tr,
                  Icons.check_circle_rounded,
                  AppColors.reliefGreen,
                ),
              ),
              SizedBox(width: AppSize.m),
              Expanded(
                child: statCard(
                  rating.toStringAsFixed(1),
                  ratingCount == 1
                      ? '1 ${'common.rating'.tr}'
                      : '$ratingCount ${'common.ratings'.tr}',
                  Icons.star_rounded,
                  AppColors.amberOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
