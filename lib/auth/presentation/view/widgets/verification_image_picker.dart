import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_colors.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_text.dart';
import 'package:fyp_source_code/utilities/reuse_components/spacing.dart';
import 'package:get/get.dart';

class VerificationImagePicker extends StatelessWidget {
  final String label;
  final String helperText;
  final bool isRequired;
  final Uint8List? imageBytes;
  final String? fileName;
  final VoidCallback onTap;
  final bool isLoading;

  const VerificationImagePicker({
    super.key,
    required this.label,
    required this.helperText,
    required this.onTap,
    this.isRequired = false,
    this.imageBytes,
    this.fileName,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasImage = imageBytes != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: AppTextStyling.body_12S.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
            children: [
              TextSpan(text: label),
              if (isRequired)
                TextSpan(
                  text: ' *',
                  style: AppTextStyling.body_12S.copyWith(
                    color: AppColors.emergencyRed,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
        ),
        AppSize.xsHeight,
        Text(
          helperText,
          maxLines: 3,
          overflow: TextOverflow.visible,
          style: AppTextStyling.body_12S.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.35,
          ),
        ),
        AppSize.sHeight,
        GestureDetector(
          onTap: isLoading ? null : onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: hasImage ? 132 : 112,
            width: double.infinity,
            decoration: BoxDecoration(
              color:
                  hasImage
                      ? scheme.surfaceContainerHighest
                      : theme.inputDecorationTheme.fillColor ?? scheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    hasImage
                        ? scheme.primary.withValues(alpha: 0.75)
                        : scheme.outlineVariant,
                width: hasImage ? 1.6 : 1,
              ),
            ),
            child:
                hasImage
                    ? Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.memory(imageBytes!, fit: BoxFit.cover),
                        ),
                        Positioned(
                          left: 10,
                          right: 10,
                          bottom: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.image_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    fileName?.trim().isNotEmpty == true
                                        ? fileName!.trim()
                                        : 'verification.selected_image'.tr,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyling.body_12S.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.edit_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                    : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload_rounded,
                          size: 34,
                          color: scheme.primary,
                        ),
                        AppSize.xsHeight,
                        Text(
                          'verification.tap_to_upload'.tr,
                          style: AppTextStyling.body_14M.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'verification.upload_hint'.tr,
                          style: AppTextStyling.body_12S.copyWith(
                            color: scheme.onSurfaceVariant,
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
