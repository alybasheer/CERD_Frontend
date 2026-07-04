import 'package:flutter/material.dart';
import 'package:fyp_source_code/routing/route_names.dart';
import 'package:fyp_source_code/splash_onboardings/data/models/onboarding_model.dart';
import 'package:fyp_source_code/utilities/reuse_components/storage_helper.dart';
import 'package:get/get.dart';

class OnboardingController extends GetxController {
  late PageController pageController;
  final RxInt currentPage = 0.obs;
  final RxBool isLastPage = false.obs;

  final List<OnboardingModel> onboardingPages = [
    OnboardingModel(
      titleKey: 'onboarding.page1.title',
      descriptionKey: 'onboarding.page1.description',
      assetsImg: 'assets/icons/sosIcon.svg',
      iconColor: Color(0xFFE53935),
    ),
    OnboardingModel(
      titleKey: 'onboarding.page2.title',
      descriptionKey: 'onboarding.page2.description',
      assetsImg: 'assets/icons/map.svg',
      iconColor: Color(0xFF00897B),
    ),
    OnboardingModel(
      titleKey: 'onboarding.page3.title',
      descriptionKey: 'onboarding.page3.description',
      assetsImg: 'assets/icons/teamIcon.svg',
      iconColor: Color(0xFF0047ab),
    ),
    OnboardingModel(
      titleKey: 'onboarding.page4.title',
      descriptionKey: 'onboarding.page4.description',
      assetsImg: 'assets/icons/alertIcon.svg',
      iconColor: Color(0xFFFB8C00),
    ),
    OnboardingModel(
      titleKey: 'onboarding.page5.title',
      descriptionKey: 'onboarding.page5.description',
      assetsImg: 'assets/icons/thumbsup.svg',
      iconColor: Color(0xFF43A047),
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    pageController = PageController();
  }

  void onPageChanged(int index) {
    currentPage.value = index;
    isLastPage.value = index == onboardingPages.length - 1;
  }

  void nextPage() {
    if (!isLastPage.value) {
      pageController.nextPage(
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void skipOnboarding() {
    _markOnboardingAsComplete();
    Get.offAllNamed(RouteNames.login);
  }

  void finishOnboarding() {
    _markOnboardingAsComplete();
    Get.offAllNamed(RouteNames.login);
  }

  void _markOnboardingAsComplete() {
    StorageHelper().saveData('hasSeenOnboarding', true);
    print('✅ Onboarding marked as complete');
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
