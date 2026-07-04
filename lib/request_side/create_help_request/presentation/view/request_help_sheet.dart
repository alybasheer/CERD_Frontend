import 'package:flutter/material.dart';
import 'package:fyp_source_code/request_side/create_help_request/presentation/view/widgets/request_description_field.dart';
import 'package:fyp_source_code/request_side/create_help_request/presentation/view/widgets/request_dropdown_field.dart';
import 'package:fyp_source_code/request_side/create_help_request/presentation/view/widgets/request_location_chip.dart'
    as request_widgets;
import 'package:fyp_source_code/request_side/create_help_request/presentation/view/widgets/request_upload_card.dart';
import 'package:get/get.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_text.dart';
import 'package:fyp_source_code/utilities/reuse_components/spacing.dart';

import '../controller/request_help_controller.dart';

class RequestHelpSheet extends StatelessWidget {
  const RequestHelpSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RequestHelpController>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SafeArea(
      child: Container(
        height: AppSize.hp(86),
        padding: EdgeInsets.symmetric(
          horizontal: AppSize.m,
          vertical: AppSize.mH,
        ),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(right: AppSize.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                SizedBox(height: AppSize.lH),
                Text(
                  'request_help.title'.tr,
                  style: AppTextStyling.title_18M.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: AppSize.xsH),
                Text(
                  'request_help.subtitle'.tr,
                  style: AppTextStyling.body_14M.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: AppSize.lH),
                Text(
                  'request_help.category'.tr,
                  style: AppTextStyling.body_14M.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSize.sH),
                Obx(
                  () => RequestDropdownField(
                    hint: 'request_help.category_hint'.tr,
                    items: controller.categories,
                    value: controller.selectedCategory.value,
                    onChanged: controller.setCategory,
                  ),
                ),
                SizedBox(height: AppSize.mH),
                Text(
                  'request_help.subcategory'.tr,
                  style: AppTextStyling.body_14M.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSize.sH),
                Obx(
                  () => RequestDropdownField(
                    hint: 'request_help.subcategory_hint'.tr,
                    items: controller.availableSubcategories,
                    value: controller.selectedSubcategory.value,
                    onChanged: controller.setSubcategory,
                  ),
                ),
                SizedBox(height: AppSize.mH),
                Text(
                  'request_help.description'.tr,
                  style: AppTextStyling.body_14M.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSize.sH),
                RequestDescriptionField(
                  controller: controller.descriptionController,
                ),
                SizedBox(height: AppSize.sH),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: controller.applySmartSuggestion,
                    icon: const Icon(Icons.auto_fix_high, size: 18),
                    label: Text('common.improve'.tr),
                    style: TextButton.styleFrom(
                      foregroundColor: scheme.primary,
                    ),
                  ),
                ),
                SizedBox(height: AppSize.mH),
                Text(
                  'request_help.photos'.tr,
                  style: AppTextStyling.body_14M.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSize.sH),
                Obx(
                  () => RequestUploadCard(
                    photos: controller.selectedPhotos.toList(),
                    onTap: controller.pickPhotos,
                    onRemove: controller.removePhoto,
                  ),
                ),
                SizedBox(height: AppSize.mH),
                Obx(
                  () => request_widgets.RequestLocationChip(
                    label: controller.locationLabel.value,
                  ),
                ),
                SizedBox(height: AppSize.xlH),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: scheme.primary,
                          side: BorderSide(
                            color: scheme.primary.withValues(alpha: 0.4),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('common.cancel'.tr),
                      ),
                    ),
                    SizedBox(width: AppSize.s),
                    Expanded(
                      child: Obx(
                        () => ElevatedButton(
                          onPressed:
                              controller.isSubmitting.value
                                  ? null
                                  : controller.submitRequest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: scheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            controller.isSubmitting.value
                                ? 'common.sending'.tr
                                : 'request_help.send_request'.tr,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSize.lH),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
