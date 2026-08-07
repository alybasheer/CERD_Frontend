import 'package:flutter/material.dart';
import 'package:fyp_source_code/communities/data/model/community_model.dart';
import 'package:fyp_source_code/communities/data/repo/communities_repo.dart';
import 'package:fyp_source_code/services/location_services.dart';
import 'package:fyp_source_code/utilities/helpers/toast_helper.dart';
import 'package:fyp_source_code/utilities/reuse_components/storage_helper.dart';
import 'package:get/get.dart';

class CommunitiesController extends GetxController {
  final CommunitiesRepo _repo = CommunitiesRepo();
  final StorageHelper _storage = StorageHelper();

  final communities = <CommunityModel>[].obs;
  final messages = <CommunityMessage>[].obs;
  final isLoading = false.obs;
  final isSubmitting = false.obs;
  final selectedCategory = Rx<String?>(null);

  final titleController = TextEditingController();
  final detailsController = TextEditingController();
  final timeNeededController = TextEditingController();
  final locationNameController = TextEditingController();
  final peopleRequiredController = TextEditingController();
  final messageController = TextEditingController();

  final categories = const [
    'Natural Disaster',
    'Medical',
    'Accident',
    'Shelter',
    'Other',
  ];

  String get currentUserId => _storage.readData('userId') ?? '';
  bool get isVolunteer =>
      (_storage.readData('role') ?? '').toLowerCase() == 'volunteer';
  bool get isAdmin =>
      (_storage.readData('role') ?? '').toLowerCase() == 'admin';

  @override
  void onInit() {
    super.onInit();
    fetchCommunities();
  }

  Future<void> fetchCommunities() async {
    isLoading.value = true;
    try {
      final position = await getCurrentLocation();
      final list = await _repo.getCommunities(
        category: selectedCategory.value,
        latitude: position.latitude,
        longitude: position.longitude,
      );
      communities.assignAll(list);
    } catch (e) {
      ToastHelper.showErrorMessage(e);
    } finally {
      isLoading.value = false;
    }
  }

  void setCategory(String? category) {
    selectedCategory.value = category;
    fetchCommunities();
  }

  Future<void> createCommunity() async {
    final title = titleController.text.trim();
    final details = detailsController.text.trim();
    final timeNeeded = timeNeededController.text.trim();
    final locationName = locationNameController.text.trim();
    final peopleRequired = int.tryParse(peopleRequiredController.text.trim());

    if (!isVolunteer) {
      ToastHelper.showWarning('community.form.only_volunteers'.tr);
      return;
    }
    if (title.isEmpty ||
        details.isEmpty ||
        selectedCategory.value == null ||
        timeNeeded.isEmpty ||
        locationName.isEmpty ||
        peopleRequired == null) {
      ToastHelper.showError('community.form.complete_fields'.tr);
      return;
    }

    isSubmitting.value = true;
    try {
      final position = await getCurrentLocation();
      await _repo.createCommunity({
        'title': title,
        'details': details,
        'category': selectedCategory.value,
        'timeNeeded': timeNeeded,
        'locationName': locationName,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'peopleRequired': peopleRequired,
      });
      Get.back();
      _clearCreateFields();
      ToastHelper.showSuccess('community.form.published'.tr);
      await fetchCommunities();
    } catch (e) {
      ToastHelper.showErrorMessage(e);
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> joinCommunity(CommunityModel community) async {
    try {
      await _repo.joinCommunity(community.id);
      ToastHelper.showSuccess('community.form.joined'.tr);
      await fetchCommunities();
    } catch (e) {
      ToastHelper.showErrorMessage(e);
    }
  }

  Future<void> startCommunity(CommunityModel community) async {
    try {
      await _repo.startCommunity(community.id);
      ToastHelper.showSuccess('community.form.started'.tr);
      await fetchCommunities();
    } catch (e) {
      ToastHelper.showErrorMessage(e);
    }
  }

  Future<void> deleteCommunity(CommunityModel community) async {
    try {
      await _repo.deleteCommunity(community.id);
      ToastHelper.showSuccess('community.form.deleted'.tr);
      await fetchCommunities();
    } catch (e) {
      ToastHelper.showErrorMessage(e);
    }
  }

  Future<void> fetchMessages(CommunityModel community) async {
    try {
      final list = await _repo.getMessages(community.id);
      messages.assignAll(list);
    } catch (e) {
      ToastHelper.showErrorMessage(e);
    }
  }

  Future<void> sendMessage(CommunityModel community) async {
    final content = messageController.text.trim();
    if (content.isEmpty) {
      return;
    }
    try {
      await _repo.sendMessage(community.id, content);
      messageController.clear();
      await fetchMessages(community);
    } catch (e) {
      ToastHelper.showErrorMessage(e);
    }
  }

  bool canManage(CommunityModel community) {
    return isAdmin || community.creatorId == currentUserId;
  }

  bool canJoin(CommunityModel community) {
    return (isVolunteer || isAdmin) &&
        !community.memberIds.contains(currentUserId) &&
        community.status == 'open';
  }

  bool canChat(CommunityModel community) {
    return isAdmin ||
        community.creatorId == currentUserId ||
        community.memberIds.contains(currentUserId);
  }

  void _clearCreateFields() {
    titleController.clear();
    detailsController.clear();
    timeNeededController.clear();
    locationNameController.clear();
    peopleRequiredController.clear();
  }

  @override
  void onClose() {
    titleController.dispose();
    detailsController.dispose();
    timeNeededController.dispose();
    locationNameController.dispose();
    peopleRequiredController.dispose();
    messageController.dispose();
    super.onClose();
  }
}
