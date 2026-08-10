import 'package:flutter/rendering.dart';

class OnboardingModel {
  final String titleKey;
  final String descriptionKey;
  final String assetsImg;
  final Color iconColor;

  OnboardingModel({
    required this.titleKey,
    required this.descriptionKey,
    required this.assetsImg,
    required this.iconColor,
  });
}
