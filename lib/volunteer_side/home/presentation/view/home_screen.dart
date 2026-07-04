import 'package:flutter/material.dart';
import 'package:fyp_source_code/utilities/reuse_components/spacing.dart';
import 'package:fyp_source_code/volunteer_side/home/presentation/controller/home_controller.dart';
import 'package:fyp_source_code/volunteer_side/home/presentation/view/widgets/quick_actions.dart';
import 'package:fyp_source_code/volunteer_side/home/presentation/view/widgets/req_empty_state.dart';
import 'package:fyp_source_code/volunteer_side/home/presentation/view/widgets/req_header.dart';
import 'package:fyp_source_code/volunteer_side/home/presentation/view/widgets/req_list.dart';
import 'package:fyp_source_code/volunteer_side/home/presentation/view/widgets/silver_appbar.dart';
import 'package:fyp_source_code/utilities/reuse_widgets/shimmer_loading.dart';
import 'package:get/get.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value && controller.requests.isEmpty) {
            return CustomScrollView(
              slivers: [
                sliverAppBar(
                  completedCount: controller.completedCount.value,
                  rating: controller.volunteerRating.value,
                  ratingCount: controller.volunteerRatingCount.value,
                  fullName: controller.fullName.value,
                  locationName: controller.locationName.value,
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                const SliverToBoxAdapter(
                  child: AppShimmer(child: ShimmerHomeSkeleton()),
                ),
              ],
            );
          }

          return CustomScrollView(
            slivers: [
              sliverAppBar(
                completedCount: controller.completedCount.value,
                rating: controller.volunteerRating.value,
                ratingCount: controller.volunteerRatingCount.value,
                fullName: controller.fullName.value,
                locationName: controller.locationName.value,
              ),
              quickActionsSection(),
              requestsHeaderSection(),
              requestsListSection(
                controller.requests,
                onAccept: controller.acceptRequest,
                acceptingIds: controller.acceptingRequestIds,
              ),
              if (controller.requests.isEmpty && !controller.isLoading.value)
                const SliverToBoxAdapter(child: ReqEmptyState()),
              bottomSpacing(),
            ],
          );
        }),
      ),
    );
  }

  static Widget bottomSpacing() {
    return SliverToBoxAdapter(child: SizedBox(height: AppSize.hp(12)));
  }
}
