import 'package:flutter/material.dart';
import 'package:fyp_source_code/admin/presentation/controller/admin_panel_controller.dart';
import 'package:fyp_source_code/utilities/reuse_components/storage_helper.dart';
import 'package:get/get.dart';

final AdminPanelController ctrl = Get.find<AdminPanelController>();

void popupCard(BuildContext context, Map<String, dynamic> application) {
  final data = Map<String, dynamic>.from(application);
  final applicationId = _stringValue(data['_id']);
  final userData =
      data['userId'] is Map
          ? Map<String, dynamic>.from(data['userId'] as Map)
          : <String, dynamic>{};
  final token = StorageHelper().readData('token')?.toString().trim();
  final imageHeaders =
      token == null || token.isEmpty
          ? null
          : <String, String>{'Authorization': 'Bearer $token'};

  showDialog(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440, maxHeight: 720),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'admin.volunteer_review'.tr,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          _StatusChip(status: _stringValue(data['status'])),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_stringValue(data['profileImage']).isNotEmpty)
                        Center(
                          child: CircleAvatar(
                            radius: 38,
                            backgroundColor: Colors.blue.withValues(
                              alpha: 0.10,
                            ),
                            backgroundImage: NetworkImage(
                              _stringValue(data['profileImage']),
                              headers: imageHeaders,
                            ),
                          ),
                        ),
                      if (_stringValue(data['profileImage']).isNotEmpty)
                        const SizedBox(height: 16),
                       _infoRow('admin.label_name'.tr, _stringValue(data['name'])),
                      _infoRow(
                        'admin.label_email'.tr,
                        _stringValue(userData['email']).isNotEmpty
                            ? _stringValue(userData['email'])
                            : 'admin.not_available'.tr,
                      ),
                      _infoRow(
                        'admin.label_phone'.tr,
                        _stringValue(userData['phone']).isNotEmpty
                            ? _stringValue(userData['phone'])
                            : 'admin.phone_not_provided'.tr,
                      ),
                      _infoRow('admin.label_city'.tr, _stringValue(data['city'])),
                      _infoRow('admin.label_location'.tr, _stringValue(data['location'])),
                      if (_coordinateText(data).isNotEmpty)
                        _infoRow('admin.label_gps'.tr, _coordinateText(data)),
                      _infoRow('admin.label_expertise'.tr, _stringValue(data['expertise'])),
                      _infoRow('admin.label_cnic'.tr, _stringValue(data['cnic'])),
                      _infoRow('admin.label_reason'.tr, _stringValue(data['reason'])),
                      const SizedBox(height: 18),
                      Text(
                        'admin.verification_docs'.tr,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      _DocumentPreview(
                        title: 'admin.cnic_front'.tr,
                        imageUrl: _stringValue(data['cnicFrontImage']),
                        headers: imageHeaders,
                      ),
                      const SizedBox(height: 12),
                      _DocumentPreview(
                        title: 'admin.cnic_back'.tr,
                        imageUrl: _stringValue(data['cnicBackImage']),
                        headers: imageHeaders,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => ctrl.rejectVolunteer(applicationId),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          side: BorderSide(color: Colors.red.shade200),
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text('common.reject'.tr),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => ctrl.approveVolunteer(applicationId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text('common.approve'.tr),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _infoRow(String title, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.isEmpty ? 'admin.not_provided'.tr : value,
          style: TextStyle(color: Colors.grey.shade800, height: 1.35),
        ),
      ],
    ),
  );
}

String _stringValue(dynamic value) {
  if (value == null) {
    return '';
  }
  return value.toString().trim();
}

String _coordinateText(Map<String, dynamic> data) {
  final lat = _stringValue(data['latitude']);
  final lng = _stringValue(data['longitude']);
  if (lat.isEmpty || lng.isEmpty) {
    return '';
  }
  return '$lat, $lng';
}

class _DocumentPreview extends StatelessWidget {
  final String title;
  final String imageUrl;
  final Map<String, String>? headers;

  const _DocumentPreview({
    required this.title,
    required this.imageUrl,
    required this.headers,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 164,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child:
              hasImage
                  ? ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      headers: headers,
                      errorBuilder: (_, __, ___) => _emptyDocumentState(),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) {
                          return child;
                        }
                        return const Center(child: CircularProgressIndicator());
                      },
                    ),
                  )
                  : _emptyDocumentState(),
        ),
      ],
    );
  }

  Widget _emptyDocumentState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.image_not_supported_outlined, color: Colors.grey.shade500),
        const SizedBox(height: 8),
        Text(
          'admin.doc_not_available'.tr,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.isEmpty ? 'pending' : status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

Color _getStatusColor(String status) {
  switch (status) {
    case 'approved':
      return Colors.green;
    case 'rejected':
      return Colors.red;
    case 'pending':
    default:
      return Colors.orange;
  }
}
