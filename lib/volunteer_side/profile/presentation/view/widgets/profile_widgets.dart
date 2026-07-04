import 'package:flutter/material.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_colors.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_text.dart';
import 'package:fyp_source_code/utilities/reuse_components/spacing.dart';
import 'package:fyp_source_code/utilities/reuse_components/storage_helper.dart';
import 'package:fyp_source_code/volunteer_side/profile/presentation/controller/profile_controller.dart';
import 'package:get/get.dart';

class ProfileHero extends StatelessWidget {
  final ProfileController controller;

  const ProfileHero({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        padding: EdgeInsets.all(AppSize.m),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: const [Color(0xFF0F5DB8), Color(0xFF1976D2)],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.steelBlue.withValues(alpha: 0.24),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.pureWhite.withValues(alpha: 0.18),
                  backgroundImage: _resolveAvatar(controller.profileImage.value),
                  child: controller.profileImage.value.trim().isNotEmpty
                      ? null
                      : Text(
                          controller.initials,
                          style: AppTextStyling.title_22L.copyWith(
                            color: AppColors.pureWhite,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
                SizedBox(width: AppSize.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.profileName.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyling.title_18M.copyWith(
                          color: AppColors.pureWhite,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: AppSize.xsH),
                      Text(
                        controller.profileEmail.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyling.body_12S.copyWith(
                          color: AppColors.pureWhite.withValues(alpha: 0.86),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  flex: 0,
                  child: _RolePill(
                    label: controller.displayRole,
                    icon: controller.roleIcon,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSize.lH),
            Row(
              children: [
                Expanded(
                  child: _HeroInfo(
                    icon: Icons.verified_user_rounded,
                    label: 'profile.status'.tr,
                    value: controller.statusLabel,
                  ),
                ),
                SizedBox(width: AppSize.s),
                Expanded(
                  child: _HeroInfo(
                    icon: Icons.location_on_rounded,
                    label: 'profile.location'.tr,
                    value: controller.profileLocation.value,
                  ),
                ),
              ],
            ),
            if (controller.isVolunteer) ...[
              SizedBox(height: AppSize.s),
              _HeroInfo(
                icon: Icons.star_rounded,
                label: 'profile.rating'.tr,
                value: controller.ratingSummary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ProfileAccountSection extends StatelessWidget {
  final ProfileController controller;

  const ProfileAccountSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return _ProfileSection(
      title: 'profile.account_details'.tr,
      icon: Icons.badge_rounded,
      child: Column(
        children: [
          _ProfileTextField(
            controller: controller.nameController,
            label: 'profile.full_name'.tr,
            icon: Icons.person_rounded,
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: AppSize.mH),
          _ProfileTextField(
            controller: controller.emailController,
            label: 'profile.email'.tr,
            icon: Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: AppSize.mH),
          _ProfileTextField(
            controller: controller.locationController,
            label: 'profile.location'.tr,
            icon: Icons.location_on_rounded,
            textInputAction: TextInputAction.done,
          ),
          SizedBox(height: AppSize.mH),
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => OutlinedButton.icon(
                    onPressed:
                        controller.isResolvingLocation.value
                            ? null
                            : controller.useCurrentLocation,
                    icon:
                        controller.isResolvingLocation.value
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.my_location_rounded),
                    label: Text(
                      controller.isResolvingLocation.value
                          ? 'profile.finding'.tr
                          : 'profile.use_current'.tr,
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 46),
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      side: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.45),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: AppSize.s),
              Expanded(
                child: Obx(
                  () => ElevatedButton.icon(
                    onPressed:
                        controller.isSaving.value
                            ? null
                            : controller.saveProfile,
                    icon:
                        controller.isSaving.value
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Icon(Icons.save_rounded),
                    label: Text(
                      controller.isSaving.value
                          ? 'common.saving'.tr
                          : 'common.save'.tr,
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 46),
                      backgroundColor: AppColors.safetyBlue,
                      foregroundColor: AppColors.pureWhite,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProfileQuickActions extends StatelessWidget {
  final ProfileController controller;

  const ProfileQuickActions({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final actions = <_ProfileAction>[
        _ProfileAction(
          label:
              controller.isVolunteer
                  ? 'profile.volunteer_home'.tr
                  : 'profile.request_home'.tr,
          icon: Icons.home_rounded,
          color: AppColors.safetyBlue,
          onTap: controller.openPrimaryWorkspace,
        ),
        _ProfileAction(
          label: 'common.alerts'.tr,
          icon: Icons.notifications_active_rounded,
          color: AppColors.emergencyRed,
          onTap: controller.openAlerts,
        ),
        _ProfileAction(
          label: 'common.coordination'.tr,
          icon: Icons.people_alt_rounded,
          color: AppColors.steelBlue,
          onTap: controller.openCoordination,
        ),
        if (controller.isVolunteer)
          _ProfileAction(
            label: 'profile.communities'.tr,
            icon: Icons.groups_rounded,
            color: AppColors.reliefGreen,
            onTap: controller.openCommunities,
          ),
      ];

      return _ProfileSection(
        title: 'profile.quick_actions'.tr,
        icon: Icons.grid_view_rounded,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = (constraints.maxWidth - AppSize.s) / 2;
            return Wrap(
              spacing: AppSize.s,
              runSpacing: AppSize.sH,
              children:
                  actions
                      .map(
                        (action) =>
                            _ActionTile(action: action, width: itemWidth),
                      )
                      .toList(),
            );
          },
        ),
      );
    });
  }
}

class ProfilePreferencesSection extends StatelessWidget {
  final ProfileController controller;

  const ProfilePreferencesSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return _ProfileSection(
      title: 'profile.preferences'.tr,
      icon: Icons.tune_rounded,
      child: Obx(
        () => SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: Icon(
            controller.isSwitching.value
                ? Icons.dark_mode_rounded
                : Icons.light_mode_rounded,
            color: AppColors.safetyBlue,
          ),
          title: Text(
            'profile.dark_mode'.tr,
            style: AppTextStyling.body_14M.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          value: controller.isSwitching.value,
          activeThumbColor: AppColors.safetyBlue,
          onChanged: controller.onSwitch,
        ),
      ),
    );
  }
}

class ProfilePolicySection extends StatelessWidget {
  const ProfilePolicySection({super.key});

  @override
  Widget build(BuildContext context) {
    return _ProfileSection(
      title: 'profile.privacy'.tr,
      icon: Icons.policy_rounded,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.lock_rounded, color: AppColors.safetyBlue),
        title: Text(
          'profile.data_permissions'.tr,
          style: AppTextStyling.body_14M.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => _showPrivacySheet(context),
      ),
    );
  }

  void _showPrivacySheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final scheme = Theme.of(context).colorScheme;

        return SafeArea(
          top: false,
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.44,
            minChildSize: 0.34,
            maxChildSize: 0.72,
            builder: (context, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(
                  AppSize.l,
                  AppSize.sH,
                  AppSize.l,
                  AppSize.lH,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Theme.of(context).dividerColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    SizedBox(height: AppSize.lH),
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.privacy_tip_rounded,
                            color: scheme.primary,
                            size: 21,
                          ),
                        ),
                        SizedBox(width: AppSize.s),
                        Expanded(
                          child: Text(
                            'profile.data_permissions'.tr,
                            style: AppTextStyling.title_18M.copyWith(
                              color: scheme.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSize.mH),
                    _PolicyLine(
                      icon: Icons.key_rounded,
                      title: 'profile.session_access'.tr,
                      text: 'profile.session_access.text'.tr,
                    ),
                    _PolicyLine(
                      icon: Icons.location_on_rounded,
                      title: 'profile.location_use'.tr,
                      text: 'profile.location_use.text'.tr,
                    ),
                    _PolicyLine(
                      icon: Icons.palette_rounded,
                      title: 'profile.preferences'.tr,
                      text: 'profile.preferences.text'.tr,
                    ),
                    SizedBox(height: AppSize.sH),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: scheme.primary,
                          foregroundColor: scheme.onPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('common.got_it'.tr),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class ProfileSignOutSection extends StatelessWidget {
  final ProfileController controller;

  const ProfileSignOutSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSize.buttonHeight,
      child: ElevatedButton.icon(
        onPressed: controller.signOut,
        icon: const Icon(Icons.logout_rounded),
        label: Text('profile.sign_out'.tr),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.emergencyRed,
          foregroundColor: AppColors.pureWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _ProfileSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSize.m),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              SizedBox(width: AppSize.xs),
              Text(
                title,
                style: AppTextStyling.title_16M.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSize.mH),
          child,
        ],
      ),
    );
  }
}

class _HeroInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HeroInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSize.s),
      decoration: BoxDecoration(
        color: AppColors.pureWhite.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.pureWhite.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.pureWhite, size: 18),
          SizedBox(width: AppSize.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyling.body_12S.copyWith(
                    color: AppColors.pureWhite.withValues(alpha: 0.72),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyling.body_12S.copyWith(
                    color: AppColors.pureWhite,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  final String label;
  final IconData icon;

  const _RolePill({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 112),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: AppSize.s, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.pureWhite.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: AppColors.pureWhite.withValues(alpha: 0.22),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.pureWhite, size: 15),
            SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyling.body_12S.copyWith(
                  color: AppColors.pureWhite,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  const _ProfileTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyling.body_12S.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: AppSize.xsH),
        SizedBox(
          height: 48,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            style: AppTextStyling.body_14M.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: scheme.primary, size: 20),
              filled: true,
              fillColor: theme.inputDecorationTheme.fillColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: scheme.primary, width: 1.4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final _ProfileAction action;
  final double width;

  const _ActionTile({required this.action, required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 72,
      child: Material(
        color: action.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: action.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSize.s, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: action.color.withValues(alpha: 0.14),
                  child: Icon(action.icon, color: action.color, size: 18),
                ),
                SizedBox(width: AppSize.xs),
                Expanded(
                  child: Text(
                    action.label,
                    maxLines: 2,
                    overflow: TextOverflow.fade,
                    style: AppTextStyling.body_12S.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PolicyLine extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _PolicyLine({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: AppSize.mH),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: scheme.primary, size: 18),
          ),
          SizedBox(width: AppSize.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyling.body_14M.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  text,
                  softWrap: true,
                  style: AppTextStyling.body_12S.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ProfileAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

ImageProvider? _resolveAvatar(String? imageUrl) {
  final value = imageUrl?.trim() ?? '';
  if (value.isEmpty) {
    return null;
  }
  if (value.startsWith('http')) {
    final token = StorageHelper().readData('token')?.toString().trim();
    return NetworkImage(
      value,
      headers:
          token == null || token.isEmpty
              ? null
              : {'Authorization': 'Bearer $token'},
    );
  }
  if (value.startsWith('assets/')) {
    return AssetImage(value);
  }
  return null;
}
