import 'package:flutter/material.dart';
import 'package:fyp_source_code/utilities/reuse_components/spacing.dart';
import 'package:fyp_source_code/utilities/reuse_widgets/app_bar.dart';
import 'package:fyp_source_code/volunteer_side/profile/presentation/controller/profile_controller.dart';
import 'package:fyp_source_code/volunteer_side/profile/presentation/view/widgets/profile_widgets.dart';
import 'package:get/get.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl =
        Get.isRegistered<ProfileController>()
            ? Get.find<ProfileController>()
            : Get.put(ProfileController());
    ctrl.refreshFromStorage();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: WeHelpAppBar(
        title: 'profile.title'.tr,
        subtitle: 'profile.subtitle'.tr,
        showBack: true,
        onBack: ctrl.goBackOrHome,
        actions: [
          IconButton(
            onPressed: ctrl.goHome,
            tooltip: 'common.home'.tr,
            icon: const Icon(Icons.home_rounded, color: Colors.white),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSize.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProfileHero(controller: ctrl),
              SizedBox(height: AppSize.mH),
              ProfileAccountSection(controller: ctrl),
              SizedBox(height: AppSize.mH),
              ProfileQuickActions(controller: ctrl),
              SizedBox(height: AppSize.mH),
              ProfilePreferencesSection(controller: ctrl),
              SizedBox(height: AppSize.mH),
              ProfilePolicySection(),
              SizedBox(height: AppSize.mH),
              ProfileSignOutSection(controller: ctrl),
              SizedBox(height: AppSize.lH),
            ],
          ),
        ),
      ),
    );
  }
}
