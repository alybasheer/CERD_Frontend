import 'package:flutter/material.dart';
import 'package:fyp_source_code/alerts/presentation/controller/alerts_controller.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_colors.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_text.dart';
import 'package:fyp_source_code/utilities/reuse_components/spacing.dart';
import 'package:fyp_source_code/utilities/reuse_widgets/app_bar.dart';
import 'package:fyp_source_code/utilities/reuse_widgets/shimmer_loading.dart';
import 'package:get/get.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AlertsController());
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: WeHelpAppBar(
        title: 'alerts.title'.tr,
        subtitle: 'alerts.subtitle'.tr,
        showBack: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return AppShimmer(
            child: ListView.separated(
              padding: EdgeInsets.all(AppSize.m),
              itemCount: 5,
              separatorBuilder: (_, __) => SizedBox(height: AppSize.mH),
              itemBuilder: (_, __) => const ShimmerListTileSkeleton(),
            ),
          );
        }

        if (controller.alerts.isEmpty) {
          return Center(
            child: Text(
              'alerts.no_recent'.tr,
              style: AppTextStyling.body_14M.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.fetchAlerts,
          child: ListView.separated(
            padding: EdgeInsets.all(AppSize.m),
            itemCount: controller.alerts.length,
            separatorBuilder: (_, __) => SizedBox(height: AppSize.mH),
            itemBuilder: (context, index) {
              final alert = controller.alerts[index];
              return Container(
                padding: EdgeInsets.all(AppSize.m),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.emergencyRed.withValues(
                        alpha: 0.1,
                      ),
                      child: Icon(
                        Icons.notifications_active,
                        color: AppColors.emergencyRed,
                      ),
                    ),
                    SizedBox(width: AppSize.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyling.title_16M.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: AppSize.xsH),
                          Text(
                            alert.description,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyling.body_14M.copyWith(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(height: AppSize.sH),
                          Text(
                            alert.locationName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyling.body_12S.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.emergencyRed,
        onPressed: () => _showAlertSheet(controller),
        child: const Icon(Icons.add_alert, color: Colors.white),
      ),
    );
  }

  void _showAlertSheet(AlertsController controller) {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: EdgeInsets.all(AppSize.m),
          decoration: BoxDecoration(
            color: Get.theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller.titleController,
                decoration: InputDecoration(labelText: 'alerts.create_title'.tr),
              ),
              TextField(
                controller: controller.descriptionController,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(labelText: 'alerts.create_description'.tr),
              ),
              TextField(
                controller: controller.locationNameController,
                decoration: InputDecoration(labelText: 'alerts.create_location'.tr),
              ),
              SizedBox(height: AppSize.mH),
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed:
                        controller.isSending.value
                            ? null
                            : controller.sendAlert,
                    icon: const Icon(Icons.notifications_active),
                    label: Text(
                      controller.isSending.value ? 'common.sending'.tr : 'alerts.send_alert'.tr,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emergencyRed,
                      foregroundColor: AppColors.pureWhite,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}
