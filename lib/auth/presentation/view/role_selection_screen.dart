import 'package:flutter/material.dart';
import 'package:fyp_source_code/auth/presentation/view/widgets/role_card.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_text.dart';
import 'package:fyp_source_code/utilities/reuse_components/spacing.dart';
import 'package:get/get.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSize.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSize.xxxlHeight,
              Text('role.selection.title'.tr, style: AppTextStyling.title_30M),
              AppSize.sHeight,
              Text(
                'role.selection.subtitle'.tr,
                style: AppTextStyling.body_12S,
              ),
              AppSize.xxxlHeight,
              // Request Help Card
              roleCard(
                'request_help',
                Icons.favorite,
                Colors.orange[700]!,
                'role.request_help.title'.tr,
                'role.request_help.description'.tr,
              ),
              AppSize.lHeight,
              AppSize.lHeight,

              // Volunteer Card (Primary)
              roleCard(
                'volunteer',
                Icons.handshake,
                Colors.blue[700]!,
                'role.volunteer.title'.tr,
                'role.volunteer.description'.tr,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
