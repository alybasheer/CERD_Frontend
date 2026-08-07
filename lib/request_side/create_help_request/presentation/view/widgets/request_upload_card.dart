import 'package:flutter/material.dart';
import 'package:fyp_source_code/request_side/create_help_request/presentation/controller/request_help_controller.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_text.dart';
import 'package:fyp_source_code/utilities/reuse_components/spacing.dart';
import 'package:get/get.dart';

class RequestUploadCard extends StatelessWidget {
  final List<RequestPhoto> photos;
  final VoidCallback? onTap;
  final void Function(int index)? onRemove;

  const RequestUploadCard({
    super.key,
    required this.photos,
    this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final canAddMore = photos.length < RequestHelpController.maxPhotos;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSize.s),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor, width: 1.2),
      ),
      child:
          photos.isEmpty
              ? _EmptyUploadState(onTap: onTap)
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        color: scheme.primary,
                        size: 20,
                      ),
                      SizedBox(width: AppSize.xs),
                      Expanded(
                        child: Text(
                          'request.form.photo_progress'.trParams({
                            'count': photos.length.toString(),
                          }),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyling.body_14M.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (canAddMore)
                        TextButton.icon(
                          onPressed: onTap,
                          icon: const Icon(Icons.add_photo_alternate, size: 18),
                          label: Text('request.form.add'.tr),
                          style: TextButton.styleFrom(
                            foregroundColor: scheme.primary,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: AppSize.sH),
                  SizedBox(
                    height: 104,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: photos.length,
                      separatorBuilder: (_, __) => SizedBox(width: AppSize.s),
                      itemBuilder: (context, index) {
                        return _PhotoPreview(
                          photo: photos[index],
                          onRemove: () => onRemove?.call(index),
                        );
                      },
                    ),
                  ),
                ],
              ),
    );
  }
}

class _EmptyUploadState extends StatelessWidget {
  final VoidCallback? onTap;

  const _EmptyUploadState({this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 112,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              color: scheme.primary,
              size: 32,
            ),
            SizedBox(height: AppSize.xsH),
            Text(
              'request.form.add_photos'.tr,
              style: AppTextStyling.body_14M.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: AppSize.xsH),
            Text(
              'request.form.photo_limit'.tr,
              style: AppTextStyling.body_12S.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  final RequestPhoto photo;
  final VoidCallback? onRemove;

  const _PhotoPreview({required this.photo, this.onRemove});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 116,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(photo.bytes, fit: BoxFit.cover),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 7),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.68),
                    ],
                  ),
                ),
                child: Text(
                  photo.sizeLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyling.body_12S.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: Material(
                color: scheme.surface.withValues(alpha: 0.92),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onRemove,
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
