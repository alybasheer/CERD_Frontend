import 'package:flutter/material.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_colors.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_text.dart';
import 'package:get/get.dart';

class WeHelpAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final Widget? subtitleWidget;
  final List<Widget>? actions;
  final bool showBack;
  final bool centerTitle;
  final VoidCallback? onBack;

  const WeHelpAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.subtitleWidget,
    this.actions,
    this.showBack = false,
    this.centerTitle = false,
    this.onBack,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(subtitle == null && subtitleWidget == null ? 64 : 76);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final start = isDark ? const Color(0xFF172554) : AppColors.safetyBlue;
    final end = isDark ? const Color(0xFF0F172A) : AppColors.steelBlue;

    return AppBar(
      toolbarHeight: preferredSize.height,
      automaticallyImplyLeading: false,
      leading:
          showBack
              ? IconButton(
                onPressed: onBack ?? Get.back,
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'common.back'.tr,
              )
              : null,
      titleSpacing: showBack ? 0 : 20,
      centerTitle: centerTitle,
      actions: actions,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [start, end],
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment:
            centerTitle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title.tr,
            maxLines: 2,
            overflow: TextOverflow.fade,
            softWrap: true,
            style: AppTextStyling.title_18M.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (subtitle != null || subtitleWidget != null) ...[
            const SizedBox(height: 2),
            subtitleWidget ??
                Text(
                  subtitle!.tr,
                  maxLines: 2,
                  overflow: TextOverflow.fade,
                  softWrap: true,
                  style: AppTextStyling.body_12S.copyWith(
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
          ],
        ],
      ),
      foregroundColor: Colors.white,
      backgroundColor: scheme.primary,
      elevation: 0,
    );
  }
}
