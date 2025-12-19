import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Full-screen zoomable image viewer for product images
/// Supports pinch-to-zoom, pan, double-tap, and swipe navigation
class FullscreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String? productName;

  const FullscreenImageViewer({
    super.key,
    required this.images,
    this.initialIndex = 0,
    this.productName,
  });

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer> {
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

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Photo View Gallery
          PhotoViewGallery.builder(
            scrollPhysics: const BouncingScrollPhysics(),
            builder: (BuildContext context, int index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: CachedNetworkImageProvider(
                  widget.images[index],
                ),
                initialScale: PhotoViewComputedScale.contained,
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 4.0,
                heroAttributes: PhotoViewHeroAttributes(
                  tag: 'product-image-${widget.images[index]}',
                ),
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.black,
                    child: Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 64,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  );
                },
              );
            },
            itemCount: widget.images.length,
            pageController: _pageController,
            onPageChanged: _onPageChanged,
            backgroundDecoration: const BoxDecoration(
              color: Colors.black,
            ),
          ),

          // Close button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Product name (optional, only show if provided)
                  if (widget.productName != null)
                    Expanded(
                      child: Text(
                        widget.productName!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  // Close button
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Image indicators (only show if more than one image)
          if (widget.images.length > 1)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: widget.images.asMap().entries.map((entry) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == entry.key
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

