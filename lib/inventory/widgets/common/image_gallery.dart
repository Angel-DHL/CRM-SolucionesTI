// lib/inventory/widgets/common/image_gallery.dart

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';

class ImageGallery extends StatefulWidget {
  final String? primaryImage;
  final List<String> additionalImages;
  final double height;
  final bool showThumbnails;
  final bool allowFullscreen;
  final VoidCallback? onAddImage;
  final Function(int)? onRemoveImage;
  final bool editable;

  const ImageGallery({
    super.key,
    this.primaryImage,
    this.additionalImages = const [],
    this.height = 250,
    this.showThumbnails = true,
    this.allowFullscreen = true,
    this.onAddImage,
    this.onRemoveImage,
    this.editable = false,
  });

  @override
  State<ImageGallery> createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<ImageGallery> {
  int _currentIndex = 0;
  late PageController _pageController;

  List<String> get allImages {
    final images = <String>[];
    if (widget.primaryImage != null) images.add(widget.primaryImage!);
    images.addAll(widget.additionalImages);
    return images;
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToImage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _openFullscreen(int index) {
    if (!widget.allowFullscreen) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            _FullscreenGallery(images: allImages, initialIndex: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (allImages.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Main image viewer
        SizedBox(
          height: widget.height,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemCount: allImages.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _openFullscreen(index),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMd,
                        ),
                        color: AppColors.surface,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMd,
                        ),
                        child: Image.network(
                          allImages[index],
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.broken_image_rounded,
                                size: 48,
                                color: AppColors.textHint,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Navigation arrows
              if (allImages.length > 1) ...[
                Positioned(
                  left: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _NavigationButton(
                      icon: Icons.chevron_left_rounded,
                      onTap: _currentIndex > 0
                          ? () => _goToImage(_currentIndex - 1)
                          : null,
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _NavigationButton(
                      icon: Icons.chevron_right_rounded,
                      onTap: _currentIndex < allImages.length - 1
                          ? () => _goToImage(_currentIndex + 1)
                          : null,
                    ),
                  ),
                ),
              ],

              // Page indicator
              if (allImages.length > 1)
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      allImages.length,
                      (index) => Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentIndex == index
                              ? AppColors.primary
                              : Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                ),

              // Edit button
              if (widget.editable && widget.onRemoveImage != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    onPressed: () => widget.onRemoveImage!(_currentIndex),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.delete_rounded, size: 20),
                  ),
                ),
            ],
          ),
        ),

        // Thumbnails
        if (widget.showThumbnails && allImages.length > 1) ...[
          const SizedBox(height: AppDimensions.md),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: allImages.length + (widget.editable ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == allImages.length && widget.editable) {
                  return _buildAddButton();
                }

                return GestureDetector(
                  onTap: () => _goToImage(index),
                  child: Container(
                    width: 60,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusSm,
                      ),
                      border: Border.all(
                        color: _currentIndex == index
                            ? AppColors.primary
                            : AppColors.border,
                        width: _currentIndex == index ? 2 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusSm - 1,
                      ),
                      child: Image.network(
                        allImages[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.broken_image_rounded,
                            size: 24,
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return GestureDetector(
      onTap: widget.editable ? widget.onAddImage : null,
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: AppColors.border,
            style: widget.editable ? BorderStyle.solid : BorderStyle.solid,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.editable
                    ? Icons.add_photo_alternate_rounded
                    : Icons.image_rounded,
                size: 48,
                color: AppColors.textHint,
              ),
              const SizedBox(height: AppDimensions.sm),
              Text(
                widget.editable ? 'Agregar imagen' : 'Sin imagen',
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

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: widget.onAddImage,
      child: Container(
        width: 60,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          border: Border.all(
            color: AppColors.primary,
            style: BorderStyle.solid,
          ),
          color: AppColors.primarySurface,
        ),
        child: const Center(
          child: Icon(Icons.add_rounded, color: AppColors.primary),
        ),
      ),
    );
  }
}

class _NavigationButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _NavigationButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(onTap != null ? 0.5 : 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white.withOpacity(onTap != null ? 1 : 0.5),
          size: 24,
        ),
      ),
    );
  }
}

class _FullscreenGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullscreenGallery({required this.images, required this.initialIndex});

  @override
  State<_FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<_FullscreenGallery> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1} / ${widget.images.length}'),
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemCount: widget.images.length,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Image.network(widget.images[index], fit: BoxFit.contain),
            ),
          );
        },
      ),
    );
  }
}
