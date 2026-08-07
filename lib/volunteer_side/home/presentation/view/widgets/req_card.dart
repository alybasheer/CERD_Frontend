import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_colors.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_text.dart';
import 'package:fyp_source_code/utilities/reuse_components/spacing.dart';
import 'package:fyp_source_code/utilities/reuse_widgets/request_media_gallery.dart';
import 'package:fyp_source_code/volunteer_side/home/presentation/view/widgets/request_details_dialog.dart';

Widget requestCard(
  int index, {
  required ImageProvider? requestImage,
  required List<String> mediaUrls,
  required String title,
  required String description,
  required String location,
  bool isSos = false,
  bool isAccepting = false,
  VoidCallback? onAccept,
}) {
  final theme = Get.theme;
  final scheme = theme.colorScheme;

  return Container(
    decoration: BoxDecoration(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isSos
            ? AppColors.emergencyRed.withValues(alpha: 0.65)
            : theme.dividerColor,
        width: isSos ? 1.5 : 1,
      ),
      boxShadow: [
        BoxShadow(
          color: isSos
              ? AppColors.emergencyRed.withValues(alpha: 0.18)
              : Colors.black.withValues(alpha: 0.06),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Get.dialog(
            RequestDetailsDialog(
              image: requestImage,
              mediaUrls: mediaUrls,
              title: title,
              description: description,
              location: location,
              isAccepting: isAccepting,
              onAccept: onAccept,
            ),
            barrierColor: AppColors.darkGray.withOpacity(0.4),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(AppSize.mH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppColors.steelBlue, AppColors.safetyBlue],
                      ),
                    ),
                    padding: EdgeInsets.all(2),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.steelBlue.withOpacity(0.1),
                      backgroundImage: requestImage,
                      child:
                          requestImage == null
                              ? Icon(
                                Icons.person_2_rounded,
                                color: AppColors.steelBlue,
                                size: 32,
                              )
                              : null,
                    ),
                  ),
                  SizedBox(width: AppSize.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyling.title_16M.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: AppSize.xsH),
                        Container(
                          decoration: BoxDecoration(
                            color: isSos
                                ? AppColors.emergencyRed.withValues(alpha: 0.15)
                                : AppColors.amberOrange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSize.s,
                            vertical: 2,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSos) ...[
                                Icon(
                                  Icons.sos,
                                  size: 12,
                                  color: AppColors.emergencyRed,
                                ),
                                SizedBox(width: 3),
                              ],
                              Text(
                                isSos ? 'request.card.emergency'.tr : 'common.urgent'.tr,
                                style: AppTextStyling.body_12S.copyWith(
                                  color: isSos
                                      ? AppColors.emergencyRed
                                      : AppColors.amberOrange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.mediumGray,
                  ),
                ],
              ),
              SizedBox(height: AppSize.mH),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyling.body_14M.copyWith(
                  color: scheme.onSurface,
                  height: 1.4,
                ),
              ),
              SizedBox(height: AppSize.mH),
              if (mediaUrls.isNotEmpty) ...[
                RequestMediaStrip(mediaUrls: mediaUrls, height: 86),
                SizedBox(height: AppSize.mH),
              ],
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                  SizedBox(width: AppSize.s),
                  Expanded(
                    child: Text(
                      location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyling.body_12S.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSize.mH),
              Row(
                children: [
                  
                  
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isAccepting ? null : onAccept,
                      icon:
                          isAccepting
                              ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(Icons.check_circle),
                      label: Text(isAccepting ? 'common.accepting'.tr : 'common.accept'.tr),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.reliefGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
