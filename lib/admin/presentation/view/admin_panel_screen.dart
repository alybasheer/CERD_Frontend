import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fyp_source_code/admin/presentation/controller/admin_panel_controller.dart';
import 'package:fyp_source_code/admin/presentation/view/widgets/popup_card.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_colors.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_text.dart';
import 'package:fyp_source_code/utilities/reuse_widgets/app_bar.dart';
import 'package:fyp_source_code/utilities/reuse_widgets/shimmer_loading.dart';
import 'package:get/get.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(AdminPanelController());

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: WeHelpAppBar(
        title: 'admin.title'.tr,
        subtitle: 'admin.subtitle'.tr,
        showBack: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ctrl.fetchVolunteerApplications();
          await ctrl.refreshCounts();
        },
        child: Obx(() {
          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SummaryStrip(ctrl: ctrl),
                      const SizedBox(height: 14),
                      _StatusFilters(ctrl: ctrl),
                      const SizedBox(height: 12),
                      _SearchField(ctrl: ctrl),
                    ],
                  ),
                ),
              ),
              if (ctrl.isLoading.value)
                SliverPadding(
                  padding: const EdgeInsets.all(12),
                  sliver: SliverList.separated(
                    itemCount: 6,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder:
                        (_, __) => const AppShimmer(
                          child: ShimmerListTileSkeleton(
                            showLeadingCircle: true,
                            subtitleLines: 2,
                          ),
                        ),
                  ),
                )
              else if (ctrl.filteredApplications.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(status: ctrl.selectedStatus.value),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 18),
                  sliver: SliverList.separated(
                    itemCount: ctrl.filteredApplications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = ctrl.filteredApplications[index];
                      return _ApplicationCard(
                        item: item,
                        onTap: () => popupCard(context, item),
                      );
                    },
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  final AdminPanelController ctrl;

  const _SummaryStrip({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SummaryTile(
          label: 'common.pending'.tr,
          value: ctrl.counts['pending'] ?? 0,
          color: AppColors.amberOrange,
        ),
        const SizedBox(width: 8),
        _SummaryTile(
          label: 'common.approved'.tr,
          value: ctrl.counts['approved'] ?? 0,
          color: AppColors.reliefGreen,
        ),
        const SizedBox(width: 8),
        _SummaryTile(
          label: 'common.rejected'.tr,
          value: ctrl.counts['rejected'] ?? 0,
          color: AppColors.emergencyRed,
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value.toString(),
              style: AppTextStyling.title_18M.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyling.body_12S.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusFilters extends StatelessWidget {
  final AdminPanelController ctrl;

  const _StatusFilters({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ctrl.statuses.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final status = ctrl.statuses[index];
          final selected = ctrl.selectedStatus.value == status;
          final color = _statusColor(status);
          return ChoiceChip(
            selected: selected,
            label: Text(_getStatusLabel(status)),
            onSelected: (_) => ctrl.changeStatus(status),
            selectedColor: color.withValues(alpha: 0.16),
            labelStyle: TextStyle(
              color: selected ? color : Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
            side: BorderSide(
              color: selected ? color.withValues(alpha: 0.45) : Colors.black12,
            ),
          );
        },
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final AdminPanelController ctrl;

  const _SearchField({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextField(
      controller: ctrl.searchController,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'admin.search_hint'.tr,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon:
            ctrl.searchController.text.trim().isEmpty
                ? null
                : IconButton(
                  onPressed: ctrl.searchController.clear,
                  icon: const Icon(Icons.close_rounded),
                ),
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;

  const _ApplicationCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final userData =
        item['userId'] is Map
            ? Map<String, dynamic>.from(item['userId'] as Map)
            : <String, dynamic>{};
    final name =
        _stringValue(item['name']).isEmpty
            ? 'admin.no_name'.tr
            : _stringValue(item['name']);
    final status =
        _stringValue(item['status']).isEmpty
            ? 'pending'
            : _stringValue(item['status']);
    final profileImage = _stringValue(item['profileImage']);
    final subtitle = [
      _stringValue(item['expertise']),
      _stringValue(item['city']),
    ].where((part) => part.isNotEmpty).join(' • ');

    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.safetyBlue.withValues(alpha: 0.10),
                backgroundImage:
                    profileImage.isNotEmpty
                        ? CachedNetworkImageProvider(profileImage)
                        : null,
                child:
                    profileImage.isEmpty
                        ? Text(
                          name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        )
                        : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyling.body_14M.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        _StatusChip(status: status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle.isEmpty ? 'admin.no_expertise'.tr : subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyling.body_12S.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _stringValue(userData['email']).isEmpty
                          ? 'admin.email_not_available'.tr
                          : _stringValue(userData['email']),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyling.body_12S.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: AppColors.amberOrange),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String status;

  const _EmptyState({required this.status});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.assignment_turned_in_outlined,
              size: 42,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'admin.no_applications'.trParams({'status': _getStatusLabel(status)}),
              textAlign: TextAlign.center,
              style: AppTextStyling.body_14M.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'admin.pull_refresh'.tr,
              textAlign: TextAlign.center,
              style: AppTextStyling.body_12S.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _getStatusLabel(status),
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'approved':
      return AppColors.reliefGreen;
    case 'rejected':
      return AppColors.emergencyRed;
    case 'pending':
    default:
      return AppColors.amberOrange;
  }
}

String _getStatusLabel(String status) {
  switch (status.trim().toLowerCase()) {
    case 'approved':
      return 'common.approved'.tr;
    case 'rejected':
      return 'common.rejected'.tr;
    case 'pending':
    default:
      return 'common.pending'.tr;
  }
}

String _stringValue(dynamic value) {
  if (value == null) {
    return '';
  }
  return value.toString().trim();
}
