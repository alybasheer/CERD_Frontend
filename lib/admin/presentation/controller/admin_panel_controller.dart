import 'package:flutter/material.dart';
import 'package:fyp_source_code/network/api_service.dart';
import 'package:fyp_source_code/services/api_names.dart';
import 'package:fyp_source_code/utilities/helpers/toast_helper.dart';
import 'package:get/get.dart';

class AdminPanelController extends GetxController {
  final dioHelper = DioHelper();
  final searchController = TextEditingController();

  final res = <Map<String, dynamic>>[].obs;
  final filteredApplications = <Map<String, dynamic>>[].obs;
  final selectedStatus = 'pending'.obs;
  final isLoading = false.obs;
  final isRefreshingCounts = false.obs;
  final counts = <String, int>{'pending': 0, 'approved': 0, 'rejected': 0}.obs;

  List<String> get statuses => const ['pending', 'approved', 'rejected'];

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(applySearchFilter);
    fetchVolunteerApplications();
    refreshCounts();
  }

  Future<void> changeStatus(String status) async {
    if (selectedStatus.value == status) {
      return;
    }
    selectedStatus.value = status;
    await fetchVolunteerApplications();
  }

  Future<dynamic> fetchVolunteerApplications() async {
    isLoading.value = true;
    try {
      final response = await dioHelper.get(
        url: '${ApiNames.voulnteerApplications}?status=${selectedStatus.value}',
        isauthorize: true,
      );
      final data = response['data'];
      final list =
          data is List
              ? data
                  .whereType<Map>()
                  .map((item) => Map<String, dynamic>.from(item))
                  .toList()
              : <Map<String, dynamic>>[];
      res.assignAll(list);
      counts[selectedStatus.value] = list.length;
      applySearchFilter();
      return res;
    } catch (e) {
      ToastHelper.showError(e.toString().replaceAll('Exception: ', ''));
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshCounts() async {
    isRefreshingCounts.value = true;
    try {
      for (final status in statuses) {
        final response = await dioHelper.get(
          url: '${ApiNames.voulnteerApplications}?status=$status',
          isauthorize: true,
        );
        final data = response['data'];
        counts[status] = data is List ? data.length : 0;
      }
    } catch (e) {
      debugPrint('Error refreshing admin counts: $e');
    } finally {
      isRefreshingCounts.value = false;
    }
  }

  void applySearchFilter() {
    final query = searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      filteredApplications.assignAll(res);
      return;
    }

    filteredApplications.assignAll(
      res.where((item) {
        final userData =
            item['userId'] is Map
                ? Map<String, dynamic>.from(item['userId'] as Map)
                : <String, dynamic>{};
        final haystack =
            [
              item['name'],
              item['expertise'],
              item['city'],
              item['location'],
              item['cnic'],
              userData['email'],
              userData['phone'],
            ].whereType<Object>().join(' ').toLowerCase();
        return haystack.contains(query);
      }),
    );
  }

  Future<dynamic> approveVolunteer(String applicationId) {
    return dioHelper
        .post(url: ApiNames.approveVolunteer(applicationId), isauthorize: true)
        .then((value) async {
          Get.back();
          ToastHelper.showSuccess('admin.volunteer_approved'.tr);
          await fetchVolunteerApplications();
          await refreshCounts();
        });
  }

  Future<dynamic> rejectVolunteer(String applicationId) {
    return dioHelper
        .post(url: ApiNames.rejectVolunteer(applicationId), isauthorize: true)
        .then((value) async {
          Get.back();
          ToastHelper.showSuccess('admin.volunteer_rejected'.tr);
          await fetchVolunteerApplications();
          await refreshCounts();
        });
  }

  @override
  void onClose() {
    searchController.removeListener(applySearchFilter);
    searchController.dispose();
    super.onClose();
  }
}
