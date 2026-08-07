import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:fyp_source_code/volunteer_side/volunteer_verification/presentation/controller/waiting_screen_controller.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_colors.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_text.dart';
import 'package:get/get.dart';

class WaitingScreen extends StatefulWidget {
  const WaitingScreen({super.key});

  @override
  State<WaitingScreen> createState() => _WaitingScreenState();
}

class _WaitingScreenState extends State<WaitingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late WaitingScreenController controller;

  @override
  void initState() {
    super.initState();

    // Initialize controller
    controller = Get.put(WaitingScreenController());

    // Animation for pulsing icon
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD), // Light blue background
        ),
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 40,
                  horizontal: 28,
                ),
                width: MediaQuery.of(context).size.width * 0.82,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1E3A8A), // Darker blue (top-left)
                      const Color(0xFF2563EB), // Medium blue (bottom-right)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF3B82F6).withOpacity(0.40),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E3A8A).withOpacity(0.35),
                      blurRadius: 30,
                      spreadRadius: 3,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// Status Icon - Changes based on approval status
                    Obx(() {
                      if (controller.isApproved.value) {
                        return Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green.withOpacity(0.18),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.25),
                              width: 1.3,
                            ),
                          ),
                          child: const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 60,
                          ),
                        );
                      } else if (controller.isRejected.value) {
                        return Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red.withOpacity(0.18),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.25),
                              width: 1.3,
                            ),
                          ),
                          child: const Icon(
                            Icons.cancel,
                            color: Colors.red,
                            size: 60,
                          ),
                        );
                      }
                      return AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 0.9 + 0.1 * _controller.value,
                            child: child,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.18),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.25),
                              width: 1.3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.steelBlue.withOpacity(0.30),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.hourglass_top,
                            color: Colors.white,
                            size: 60,
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 28),

                    /// Title - Changes based on status
                    Obx(() {
                      String title = 'waiting.title_pending'.tr;
                      if (controller.isApproved.value) {
                        title = 'waiting.title_approved'.tr;
                      } else if (controller.isRejected.value) {
                        title = 'waiting.title_rejected'.tr;
                      }
                      return Text(
                        title,
                        textAlign: TextAlign.center,
                        style: AppTextStyling.title_18M.copyWith(
                          color:
                              controller.isApproved.value
                                  ? Colors.green
                                  : controller.isRejected.value
                                  ? Colors.red
                                  : Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    }),

                    const SizedBox(height: 16),

                    /// Subtitle - Changes based on status
                    Obx(() {
                      String subtitle =
                          'waiting.subtitle_pending'.tr;
                      if (controller.isApproved.value) {
                        subtitle =
                            'waiting.subtitle_approved'.tr;
                      } else if (controller.isRejected.value) {
                        subtitle = 'waiting.subtitle_rejected'.tr;
                      }
                      return Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: AppTextStyling.title_16M.copyWith(
                          color: Colors.white.withOpacity(0.85),
                          height: 1.5,
                        ),
                      );
                    }),

                    const SizedBox(height: 32),

                    /// Animated Progress Bar
                    Obx(() {
                      if (controller.isApproved.value ||
                          controller.isRejected.value) {
                        return const SizedBox.shrink();
                      }
                      return Container(
                        height: 5,
                        width: 140,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white.withOpacity(0.25),
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            height: 5,
                            width: 55,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
