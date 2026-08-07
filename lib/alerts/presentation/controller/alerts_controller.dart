import 'package:flutter/material.dart';
import 'package:fyp_source_code/alerts/data/model/alert_model.dart';
import 'package:fyp_source_code/alerts/data/repo/alerts_repo.dart';
import 'package:fyp_source_code/services/location_services.dart';
import 'package:fyp_source_code/utilities/helpers/toast_helper.dart';
import 'package:get/get.dart';

class AlertsController extends GetxController {
  final AlertsRepo _repo = AlertsRepo();

  final alerts = <AlertModel>[].obs;
  final isLoading = false.obs;
  final isSending = false.obs;

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final locationNameController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchAlerts();
  }

  Future<void> fetchAlerts() async {
    isLoading.value = true;
    try {
      final position = await getCurrentLocation();
      final list = await _repo.getAlerts(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      alerts.assignAll(list);
    } catch (e) {
      ToastHelper.showErrorMessage(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> sendAlert() async {
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();
    final locationName = locationNameController.text.trim();

    if (title.isEmpty || description.isEmpty || locationName.isEmpty) {
      ToastHelper.showError('alerts.fill_required'.tr);
      return;
    }

    isSending.value = true;
    try {
      final position = await getCurrentLocation();
      await _repo.createAlert({
        'title': title,
        'description': description,
        'locationName': locationName,
        'latitude': position.latitude,
        'longitude': position.longitude,
      });
      Get.back();
      titleController.clear();
      descriptionController.clear();
      locationNameController.clear();
      ToastHelper.showSuccess('alerts.sent'.tr);
      await fetchAlerts();
    } catch (e) {
      ToastHelper.showErrorMessage(e);
    } finally {
      isSending.value = false;
    }
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    locationNameController.dispose();
    super.onClose();
  }
}
