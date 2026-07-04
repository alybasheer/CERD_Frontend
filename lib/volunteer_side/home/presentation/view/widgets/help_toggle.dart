import 'package:flutter/material.dart';
import 'package:fyp_source_code/routing/route_names.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_colors.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_text.dart';
import 'package:fyp_source_code/utilities/reuse_components/spacing.dart';
import 'package:get/get.dart';

class HelpToggle extends StatefulWidget {
  const HelpToggle({super.key});

  @override
  State<HelpToggle> createState() => _HelpToggleState();
}

class _HelpToggleState extends State<HelpToggle> {
  bool _isOn = false;

  Future<void> _handleToggle() async {
    if (_isOn) {
      return;
    }

    setState(() => _isOn = true);
    await Get.toNamed(RouteNames.requestHome);
    if (mounted) {
      setState(() => _isOn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: _handleToggle,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSize.m,
          vertical: AppSize.sH,
        ),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'volunteer.home.need_help'.tr,
                    style: AppTextStyling.body_14M.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: AppSize.xsH),
                  Text(
                    'volunteer.home.switch_request'.tr,
                    style: AppTextStyling.body_12S.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46,
              height: 26,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color:
                    _isOn ? AppColors.reliefGreen : AppColors.lightBorderGray,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Align(
                alignment: _isOn ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.pureWhite,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
