import 'package:flutter/material.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_colors.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_text.dart';
import 'package:fyp_source_code/utilities/reuse_components/container_decoration.dart';
import 'package:fyp_source_code/utilities/reuse_components/spacing.dart';
import 'package:fyp_source_code/utilities/reuse_widgets/request_media_gallery.dart';
import 'package:get/get.dart';

class RequestDetailsDialog extends StatelessWidget {
  final ImageProvider? image;
  final List<String> mediaUrls;
  final String title;
  final String description;
  final String location;
  final bool isAccepting;
  final VoidCallback? onAccept;

  const RequestDetailsDialog({
    super.key,
    this.image,
    this.mediaUrls = const <String>[],
    required this.title,
    required this.description,
    required this.location,
    this.isAccepting = false,
    this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: AppSize.hp(82)),
        child: Container(
          margin: EdgeInsets.all(AppSize.mH),
          decoration: ContainerDecorations.customShadowDecoration(
            backgroundColor: scheme.surface,
            borderRadius: 16,
            shadowColor: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            spreadRadius: 0,
          ),
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: EdgeInsets.all(AppSize.mH),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.steelBlue,
                                    AppColors.safetyBlue,
                                  ],
                                ),
                              ),
                              padding: EdgeInsets.all(3),
                              child: CircleAvatar(
                                radius: 38,
                                backgroundColor: AppColors.steelBlue.withValues(
                                  alpha: 0.1,
                                ),
                                backgroundImage: image,
                                child:
                                    image == null
                                        ? Icon(
                                          Icons.person_2_rounded,
                                          color: AppColors.steelBlue,
                                          size: 40,
                                        )
                                        : null,
                              ),
                            ),
                          ),
                          SizedBox(height: AppSize.mH),
                          if (mediaUrls.isNotEmpty) ...[
                            Text(
                              'volunteer.home.situation_photos'.tr,
                              style: AppTextStyling.body_12S.copyWith(
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: AppSize.sH),
                            RequestMediaStrip(
                              mediaUrls: mediaUrls,
                              height: 104,
                            ),
                            SizedBox(height: AppSize.mH),
                          ],
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyling.title_16M.copyWith(
                              color: scheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: AppSize.sH),
                          Text(
                            description,
                            style: AppTextStyling.body_14M.copyWith(
                              color: scheme.onSurface,
                              height: 1.4,
                            ),
                          ),
                          SizedBox(height: AppSize.mH),
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
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyling.body_12S.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: AppSize.mH),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Get.back(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.steelBlue,
                            side: BorderSide(
                              color: AppColors.steelBlue.withValues(alpha: 0.5),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('common.cancel'.tr),
                        ),
                      ),
                      SizedBox(width: AppSize.s),
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              isAccepting
                                  ? null
                                  : () {
                                    Get.back();
                                    onAccept?.call();
                                  },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.reliefGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(isAccepting ? 'common.accepting'.tr : 'common.accept'.tr),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
