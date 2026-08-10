import 'package:flutter/material.dart';
import 'package:fyp_source_code/communities/presentation/view/communities_screen.dart';
import 'package:fyp_source_code/start_point/veiw_cntrl.dart';
import 'package:fyp_source_code/utilities/reuse_widgets/app_bottom_nav.dart';
import 'package:fyp_source_code/volunteer_side/home/presentation/view/home_screen.dart';
import 'package:fyp_source_code/volunteer_side/map/presentation/view/map_screen.dart';
import 'package:fyp_source_code/volunteer_side/profile/presentation/view/profile_screen.dart';
import 'package:get/get.dart';

class StartPoint extends StatefulWidget {
  const StartPoint({super.key});

  @override
  State<StartPoint> createState() => _StartPointState();
}

class _StartPointState extends State<StartPoint> {
  /// Tabs are built lazily on first visit but kept alive afterwards
  /// (IndexedStack), so real-time listeners (new help requests, tracking)
  /// keep running no matter which tab is visible.
  final List<Widget?> _builtPages = List<Widget?>.filled(4, null);

  Widget _page(int index) {
    return _builtPages[index] ??= switch (index) {
      0 => const HomeScreen(),
      1 => MapScreen(),
      2 => const CommunitiesScreen(),
      3 => const ProfileScreen(),
      _ => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final entryVeiwCntrl = Get.put(EntryViewCntrl());
    return Obx(
      () {
        final index = entryVeiwCntrl.currentIndex.value;
        return Scaffold(
          body: IndexedStack(
            index: index,
            children: [
              for (int i = 0; i < _builtPages.length; i++) _page(i),
            ],
          ),
          bottomNavigationBar: AppBottomNav(
            currentIndex: index,
            items: [
              BottomNavItem(
                icon: Icons.home_rounded,
                label: 'common.home'.tr,
                onTap: () => entryVeiwCntrl.setIndex(0),
              ),
              BottomNavItem(
                icon: Icons.map_rounded,
                label: 'common.map'.tr,
                onTap: () => entryVeiwCntrl.setIndex(1),
              ),
              BottomNavItem(
                icon: Icons.groups_rounded,
                label: 'common.community'.tr,
                onTap: () => entryVeiwCntrl.setIndex(2),
              ),
              BottomNavItem(
                icon: Icons.person_rounded,
                label: 'common.profile'.tr,
                onTap: () => entryVeiwCntrl.setIndex(3),
              ),
            ],
          ),
        );
      },
    );
  }
}
