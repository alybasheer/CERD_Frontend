import 'package:flutter/material.dart';
import 'package:fyp_source_code/utilities/reuse_components/spacing.dart';
import 'package:fyp_source_code/utilities/reuse_components/storage_helper.dart';
import 'package:fyp_source_code/volunteer_side/home/presentation/view/widgets/req_card.dart';
import 'package:fyp_source_code/request_side/create_help_request/data/model/help_request.dart';

Widget requestsListSection(
  List<HelpRequest> requests, {
  required void Function(HelpRequest) onAccept,
  Set<String> acceptingIds = const {},
}) {
  if (requests.isEmpty) {
    return const SliverToBoxAdapter(child: SizedBox.shrink());
  }

  return SliverList(
    delegate: SliverChildBuilderDelegate((context, index) {
      final request = requests[index];
      final image = _resolveImage(request.displayImage);

      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSize.m,
          vertical: AppSize.m,
        ),
        child: requestCard(
          index,
          requestImage: image,
          mediaUrls: request.displayMediaUrls,
          title: request.displayTitle,
          description: request.description ?? 'No description provided.',
          location: request.displayLocation,
          isSos: request.isSos,
          isAccepting: acceptingIds.contains(request.sId),
          onAccept: () => onAccept(request),
        ),
      );
    }, childCount: requests.length),
  );
}

ImageProvider? _resolveImage(String? imageUrl) {
  if (imageUrl == null || imageUrl.isEmpty) {
    return null;
  }
  if (imageUrl.startsWith('http')) {
    return NetworkImage(imageUrl, headers: _authHeaders());
  }
  if (imageUrl.startsWith('assets/')) {
    return AssetImage(imageUrl);
  }

  return null;
}

Map<String, String>? _authHeaders() {
  final token = StorageHelper().readData('token')?.toString().trim();
  if (token == null || token.isEmpty) {
    return null;
  }
  return {'Authorization': 'Bearer $token'};
}
