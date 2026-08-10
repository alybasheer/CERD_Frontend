import 'package:flutter/material.dart';
import 'package:fyp_source_code/localization/locale_controller.dart';
import 'package:get/get.dart';

class LanguageCapsule extends StatelessWidget {
  const LanguageCapsule({super.key});

  @override
  Widget build(BuildContext context) {
    final localeController = Get.find<LocaleController>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsetsDirectional.only(end: 12, top: 8),
        child: Obx(
          () => Material(
            elevation: 4,
            color: scheme.surface,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: localeController.toggleLanguage,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.language_rounded, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      !localeController.isUrdu ? 'language.ur'.tr : 'language.en'.tr,
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
