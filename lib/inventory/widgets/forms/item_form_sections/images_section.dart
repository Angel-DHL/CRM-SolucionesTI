// lib/inventory/widgets/forms/item_form_sections/images_section.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../services/inventory_storage_service.dart';

class ImagesSection extends StatefulWidget {
  final String? primaryImageUrl;
  final List<String> additionalImageUrls;
  final ValueChanged<String?> onPrimaryImageChanged;
  final ValueChanged<List<String>> onAdditionalImagesChanged;
  final String? itemId;

  const ImagesSection({
    super.key,
    this.primaryImageUrl,
    required this.additionalImageUrls,
    required this.onPrimaryImageChanged,
    required this.onAdditionalImagesChanged,
    this.itemId,
  });

  @override
  State<ImagesSection> createState() => _ImagesSectionState();
}

class _ImagesSectionState extends State<ImagesSection> {
  final _storageService = InventoryStorageService.instance;
  bool _isUploading = false;

  Future<void> _uploadPrimaryImage() async {
    final itemId = widget.itemId ?? 'temp_${DateTime.now().millisecondsSinceEpoch}';

    setState(() => _isUploading = true);

    try {
      final url = await _storageService.uploadItemImage(
        itemId,
        isPrimary: true,
      );

      if (url != null) {
        widget.onPrimaryImageChanged(url);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _uploadAdditionalImages() async {
    final itemId = widget.itemId ?? 'temp_${DateTime.now().millisecondsSinceEpoch}';

    if (widget.additionalImageUrls.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Máximo 4 imágenes adicionales'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final urls = await _storageService.uploadMultipleImages(itemId);

      if (urls.isNotEmpty) {
        final totalAllowed = 4 - widget.additionalImageUrls.length;
        final newUrls = urls.take(totalAllowed).toList();
        widget.onAdditionalImagesChanged([
          ...widget.additionalImageUrls,
          ...newUrls,
        ]);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _removePrimaryImage() {
    widget.onPrimaryImageChanged(null);
  }

  void _removeAdditionalImage(int index) {
    final updated = List<String>.from(widget.additionalImageUrls);
    updated.removeAt(index);
    widget.onAdditionalImagesChanged(updated);
  }

  void _showSaveFirstMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Guarda el item primero para subir imágenes'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        _SectionHeader(
          icon: Icons.image_rounded,
          title: 'Imágenes',
          trailing: _isUploading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
        ),
        const SizedBox(height: AppDimensions.lg),

        // Primary image
        Text('Imagen principal', style: AppTextStyles.labelMedium),
        const SizedBox(height: AppDimensions.sm),
        _ImageSlot(
          imageUrl: widget.primaryImageUrl,
          onUpload: _uploadPrimaryImage,
          onRemove: widget.primaryImageUrl != null ? _removePrimaryImage : null,
          isPrimary: true,
          isUploading: _isUploading,
        ),
        const SizedBox(height: AppDimensions.lg),

        // Additional images
        Row(
          children: [
            Text('Imágenes adicionales', style: AppTextStyles.labelMedium),
            const Spacer(),
            Text(
              '${widget.additionalImageUrls.length}/4',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.sm),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: AppDimensions.sm,
            mainAxisSpacing: AppDimensions.sm,
          ),
          itemCount: widget.additionalImageUrls.length < 4
              ? widget.additionalImageUrls.length + 1
              : 4,
          itemBuilder: (context, index) {
            if (index == widget.additionalImageUrls.length) {
              return _AddImageButton(
                onTap: _uploadAdditionalImages,
                isUploading: _isUploading,
              );
            }

            return _ImageThumbnail(
              imageUrl: widget.additionalImageUrls[index],
              onRemove: () => _removeAdditionalImage(index),
            );
          },
        ),

        const SizedBox(height: AppDimensions.sm),
        Text(
          'Formatos permitidos: JPG, PNG, WebP. Máximo 5MB por imagen.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;

  const _SectionHeader({
    required this.icon,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.sm),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: AppDimensions.sm),
        Text(
          title,
          style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w600),
        ),
        if (trailing != null) ...[const Spacer(), trailing!],
      ],
    );
  }
}

class _ImageSlot extends StatelessWidget {
  final String? imageUrl;
  final VoidCallback onUpload;
  final VoidCallback? onRemove;
  final bool isPrimary;
  final bool isUploading;

  const _ImageSlot({
    this.imageUrl,
    required this.onUpload,
    this.onRemove,
    this.isPrimary = false,
    this.isUploading = false,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: imageUrl != null ? AppColors.primary : AppColors.border,
            width: imageUrl != null ? 2 : 1,
          ),
        ),
        child: imageUrl != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusMd - 1,
                    ),
                    child: Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.broken_image_rounded, size: 48),
                      ),
                    ),
                  ),
                  if (onRemove != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        onPressed: onRemove,
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.delete_rounded, size: 20),
                      ),
                    ),
                  if (isPrimary)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Principal',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              )
            : InkWell(
                onTap: isUploading ? null : onUpload,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_rounded,
                      size: 48,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(height: AppDimensions.sm),
                    Text(
                      'Subir imagen',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _ImageThumbnail extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onRemove;

  const _ImageThumbnail({required this.imageUrl, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            border: Border.all(color: AppColors.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm - 1),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Center(child: Icon(Icons.broken_image_rounded)),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddImageButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isUploading;

  const _AddImageButton({required this.onTap, required this.isUploading});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isUploading ? null : onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          border: Border.all(color: AppColors.border, style: BorderStyle.solid),
        ),
        child: Center(
          child: Icon(Icons.add_rounded, color: AppColors.textHint),
        ),
      ),
    );
  }
}
