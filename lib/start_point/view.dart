import 'package:flutter/material.dart';
import 'package:fyp_source_code/communities/presentation/view/communities_screen.dart';
import 'package:fyp_source_code/start_point/veiw_cntrl.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_colors.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_text.dart';
import 'package:fyp_source_code/utilities/reuse_components/spacing.dart';
import 'package:fyp_source_code/volunteer_side/home/presentation/view/home_screen.dart';
import 'package:fyp_source_code/volunteer_side/map/presentation/view/map_screen.dart';
import 'package:fyp_source_code/volunteer_side/profile/presentation/view/profile_screen.dart';
import 'package:get/get.dart';

class StartPoint extends StatelessWidget {
  const StartPoint({super.key});

  List<Widget> get pages => [
    const HomeScreen(),
    MapScreen(),
    const CommunitiesScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final entryVeiwCntrl = Get.put(EntryViewCntrl());
    return Obx(
      () => Scaffold(
        body: pages[entryVeiwCntrl.currentIndex.value],
        bottomNavigationBar: _buildBottomNavBar(entryVeiwCntrl),
      ),
    );
  }

  static Widget _buildBottomNavBar(EntryViewCntrl controller) {
    return Container(
      decoration: BoxDecoration(
        color: Get.theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: AppSize.mH,
          top: AppSize.sH,
          left: AppSize.m,
          right: AppSize.m,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navBarItem(
              icon: Icons.home_rounded,
              label: 'common.home'.tr,
              isActive: controller.currentIndex.value == 0,
              onTap: () => controller.setIndex(0),
            ),
            _navBarItem(
              icon: Icons.map_rounded,
              label: 'common.map'.tr,
              isActive: controller.currentIndex.value == 1,
              onTap: () => controller.setIndex(1),
            ),
            _navBarItem(
              icon: Icons.groups_rounded,
              label: 'common.community'.tr,
              isActive: controller.currentIndex.value == 2,
              onTap: () => controller.setIndex(2),
            ),
            _navBarItem(
              icon: Icons.person_rounded,
              label: 'common.profile'.tr,
              isActive: controller.currentIndex.value == 3,
              onTap: () => controller.setIndex(3),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _navBarItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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
            style: AppTextStyling.body_12S.copyWith(
              color: isActive ? AppColors.steelBlue : AppColors.mediumGray,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
