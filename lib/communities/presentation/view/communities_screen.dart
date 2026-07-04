import 'package:flutter/material.dart';
import 'package:fyp_source_code/communities/data/model/community_model.dart';
import 'package:fyp_source_code/communities/presentation/controller/communities_controller.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_colors.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_text.dart';
import 'package:fyp_source_code/utilities/reuse_components/spacing.dart';
import 'package:fyp_source_code/utilities/reuse_widgets/app_bar.dart';
import 'package:fyp_source_code/utilities/reuse_widgets/shimmer_loading.dart';
import 'package:get/get.dart';

class CommunitiesScreen extends StatelessWidget {
  const CommunitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CommunitiesController());
    final isVolunteer = controller.isVolunteer;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: WeHelpAppBar(
        title: 'communities.title'.tr,
        subtitle: 'communities.subtitle'.tr,
        showBack: true,
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: Obx(
              () => ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: AppSize.m),
                children: [
                  _filterChip(controller, null, 'communities.filter_all'.tr),
                  ...controller.categories.map(
                    (category) => _filterChip(controller, category, category),
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: Obx(() => _buildList(controller))),
        ],
      ),
      floatingActionButton:
          isVolunteer
              ? FloatingActionButton(
                backgroundColor: AppColors.steelBlue,
                onPressed: () => _showCreateSheet(controller),
                child: const Icon(Icons.add, color: Colors.white),
              )
              : const SizedBox.shrink(),
    );
  }

  Widget _buildList(CommunitiesController controller) {
    if (controller.isLoading.value) {
      return AppShimmer(
        child: ListView.separated(
          padding: EdgeInsets.all(AppSize.m),
          itemCount: 4,
          separatorBuilder: (_, __) => SizedBox(height: AppSize.mH),
          itemBuilder: (_, __) => const ShimmerListTileSkeleton(),
        ),
      );
    }
    if (controller.communities.isEmpty) {
      return Center(
        child: Text(
          'communities.no_requests'.tr,
          style: AppTextStyling.body_14M.copyWith(
            color: Get.theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: controller.fetchCommunities,
      child: ListView.separated(
        padding: EdgeInsets.all(AppSize.m),
        itemCount: controller.communities.length,
        separatorBuilder: (_, __) => SizedBox(height: AppSize.mH),
        itemBuilder: (context, index) {
          final community = controller.communities[index];
          return _CommunityCard(controller: controller, community: community);
        },
      ),
    );
  }

  Widget _filterChip(
    CommunitiesController controller,
    String? value,
    String label,
  ) {
    final selected = controller.selectedCategory.value == value;
    return Padding(
      padding: EdgeInsets.only(right: AppSize.s),
      child: ChoiceChip(
        selected: selected,
        label: Text(label),
        onSelected: (_) => controller.setCategory(value),
        selectedColor: AppColors.steelBlue.withValues(alpha: 0.15),
      ),
    );
  }

  void _showCreateSheet(CommunitiesController controller) {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: EdgeInsets.all(AppSize.m),
          decoration: BoxDecoration(
            color: Get.theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller.titleController,
                  decoration: InputDecoration(labelText: 'communities.create_title'.tr),
                ),
                TextField(
                  controller: controller.detailsController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(labelText: 'communities.create_details'.tr),
                ),
                Obx(
                  () => DropdownButtonFormField<String>(
                    value: controller.selectedCategory.value,
                    decoration: InputDecoration(labelText: 'communities.create_category'.tr),
                    items:
                        controller.categories
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                    onChanged:
                        (value) => controller.selectedCategory.value = value,
                  ),
                ),
                TextField(
                  controller: controller.timeNeededController,
                  decoration: InputDecoration(labelText: 'communities.create_time'.tr),
                ),
                TextField(
                  controller: controller.locationNameController,
                  decoration: InputDecoration(labelText: 'communities.create_location'.tr),
                ),
                TextField(
                  controller: controller.peopleRequiredController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'communities.create_people'.tr,
                  ),
                ),
                SizedBox(height: AppSize.mH),
                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed:
                          controller.isSubmitting.value
                              ? null
                              : controller.createCommunity,
                      icon: const Icon(Icons.publish),
                      label: Text(
                        controller.isSubmitting.value
                            ? 'common.publishing'.tr
                            : 'common.publish'.tr,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.steelBlue,
                        foregroundColor: AppColors.pureWhite,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}

class _CommunityCard extends StatelessWidget {
  final CommunitiesController controller;
  final CommunityModel community;

  const _CommunityCard({required this.controller, required this.community});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSize.m),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  community.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyling.title_16M.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                community.status,
                style: AppTextStyling.body_12S.copyWith(
                  color: AppColors.steelBlue,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSize.sH),
          Text(
            community.details,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyling.body_14M.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: AppSize.sH),
          Text(
            '${community.category} - ${community.locationName}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyling.body_12S.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: AppSize.mH),
          Wrap(
            spacing: AppSize.s,
            children: [
              if (controller.canJoin(community))
                OutlinedButton.icon(
                  onPressed: () => controller.joinCommunity(community),
                  icon: const Icon(Icons.group_add),
                  label: Text('common.join'.tr),
                ),
              if (controller.canChat(community))
                OutlinedButton.icon(
                  onPressed: () => _showMessages(controller, community),
                  icon: const Icon(Icons.chat),
                  label: Text('common.chat'.tr),
                ),
              if (controller.canManage(community))
                OutlinedButton.icon(
                  onPressed: () => controller.startCommunity(community),
                  icon: const Icon(Icons.play_arrow),
                  label: Text('common.start'.tr),
                ),
              if (controller.canManage(community))
                OutlinedButton.icon(
                  onPressed: () => controller.deleteCommunity(community),
                  icon: const Icon(Icons.delete_outline),
                  label: Text('common.delete'.tr),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMessages(
    CommunitiesController controller,
    CommunityModel community,
  ) {
    controller.fetchMessages(community);
    Get.bottomSheet(
      SafeArea(
        child: Container(
          height: AppSize.hp(70),
          padding: EdgeInsets.all(AppSize.m),
          decoration: BoxDecoration(
            color: Get.theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Text(
                community.title,
                style: AppTextStyling.title_16M.copyWith(
                  color: Get.theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: AppSize.mH),
              Expanded(
                child: Obx(
                  () => ListView.builder(
                    itemCount: controller.messages.length,
                    itemBuilder: (context, index) {
                      final message = controller.messages[index];
                      return ListTile(
                        dense: true,
                        title: Text(message.senderName),
                        subtitle: Text(message.content),
                      );
                    },
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller.messageController,
                      decoration: InputDecoration(hintText: 'communities.message_hint'.tr),
                    ),
                  ),
                  IconButton(
                    onPressed: () => controller.sendMessage(community),
                    icon: const Icon(Icons.send),
                    color: AppColors.steelBlue,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}
