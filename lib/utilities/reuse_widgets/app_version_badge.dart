import 'package:flutter/material.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_colors.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_text.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppVersionBadge extends StatelessWidget {
  final bool light;

  const AppVersionBadge({super.key, this.light = false});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: PackageInfo.fromPlatform().then((info) => info.version),
      builder: (context, snapshot) {
        final version = snapshot.data ?? '?';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: light
                ? Colors.white.withValues(alpha: 0.18)
                : AppColors.steelBlue.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: light
                  ? Colors.white.withValues(alpha: 0.35)
                  : AppColors.steelBlue.withValues(alpha: 0.25),
            ),
          ),
          child: Text(
            'v$version',
            style: AppTextStyling.body_12S.copyWith(
              color: light ? Colors.white : AppColors.steelBlue,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      },
    );
  }
}
