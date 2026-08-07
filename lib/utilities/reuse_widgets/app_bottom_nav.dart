import 'package:flutter/material.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_colors.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_text.dart';
import 'package:fyp_source_code/utilities/reuse_components/spacing.dart';

/// One destination in the shared bottom navigation bar.
class BottomNavItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const BottomNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

/// The single, consistent bottom navigation bar used across the whole app
/// (Volunteer and Help Seeker sides). Identical design, spacing, icons,
/// active state, height and behavior everywhere - it never changes or
/// shifts between pages.
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final List<BottomNavItem> items;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSize.m,
            right: AppSize.m,
            top: AppSize.sH,
            bottom: AppSize.mH,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (int i = 0; i < items.length; i++)
                _NavItem(
                  icon: items[i].icon,
                  label: items[i].label,
                  isActive: i == currentIndex,
                  onTap: items[i].onTap,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive ? AppColors.steelBlue : AppColors.mediumGray,
                size: 28,
              ),
              SizedBox(height: AppSize.xsH),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyling.body_12S.copyWith(
                  color: isActive ? AppColors.steelBlue : AppColors.mediumGray,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
