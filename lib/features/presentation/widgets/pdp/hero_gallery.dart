import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'inline_video_player.dart';
import '../../../../core/theme/app_theme.dart';

/// Hero Gallery Widget for Enhanced PDP
/// Displays product images in a carousel with indicators
class HeroGallery extends StatefulWidget {
  final List<String> images;
  final Function(int)? onImageChanged;
  final String? videoUrl;
  final String? productName;

  const HeroGallery({
    super.key,
    required this.images,
    this.onImageChanged,
    this.videoUrl,
    this.productName,
  });

  @override
  State<HeroGallery> createState() => _HeroGalleryState();
}

class _HeroGalleryState extends State<HeroGallery> {
  int currentIndex = 0;
  bool _showVideoPlayer = false;
  final CarouselSliderController carouselController =
      CarouselSliderController();

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return Container(
        height: 400,
        color: AppTheme.getSurface(context),
        child: Center(
          child: Icon(
            Icons.image_not_supported,
            size: 64,
            color: AppTheme.getTextSecondary(context),
          ),
        ),
      );
    }

    return Column(
      children: [
        // Main carousel with video overlay
        SizedBox(
          height: 400,
          child: Stack(
            children: [
              // Show video player overlay if activated
              if (_showVideoPlayer &&
                  widget.videoUrl != null &&
                  widget.videoUrl!.isNotEmpty)
                Positioned.fill(
                  child: InlineVideoPlayer(
                    videoUrl: widget.videoUrl!,
                    productName: widget.productName ?? 'Product Video',
                    onClose: () {
                      setState(() {
                        _showVideoPlayer = false;
                      });
                    },
                  ),
                ),

              // Main carousel (hidden when video is playing)
              if (!_showVideoPlayer)
                CarouselSlider(
                  carouselController: carouselController,
                  options: CarouselOptions(
                    height: 400,
                    viewportFraction: 1.0,
                    enableInfiniteScroll: widget.images.length > 1,
                    onPageChanged: (index, reason) {
                      setState(() {
                        currentIndex = index;
                      });
                      widget.onImageChanged?.call(index);
                    },
                  ),
                  items:
                      widget.images.map((imageUrl) {
                        return Builder(
                          builder: (BuildContext context) {
                            return Container(
                              width: MediaQuery.of(context).size.width,
                              decoration: BoxDecoration(
                                color: AppTheme.getSurface(context),
                              ),
                              child: Stack(
                                children: [
                                  // Main image
                                  CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    fit: BoxFit.contain,
                                    width: double.infinity,
                                    height: double.infinity,
                                    placeholder:
                                        (context, url) => Container(
                                          color: AppTheme.getSurface(context),
                                          child: const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        ),
                                    errorWidget:
                                        (context, url, error) => Container(
                                          color: AppTheme.getSurface(context),
                                          child: Center(
                                            child: Icon(
                                              Icons.image_not_supported,
                                              size: 64,
                                              color: AppTheme.getTextSecondary(
                                                context,
                                              ),
                                            ),
                                          ),
                                        ),
                                  ),

                                  // Video button overlay (only on current image and if video exists)
                                  if (widget.images.indexOf(imageUrl) ==
                                          currentIndex &&
                                      widget.videoUrl != null &&
                                      widget.videoUrl!.isNotEmpty)
                                    Positioned(
                                      bottom: 40,
                                      left: 20,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _showVideoPlayer = true;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(
                                              0.8,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(
                                                0.2,
                                              ),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.play_circle_filled,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Watch Video',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        );
                      }).toList(),
                ),
            ],
          ),
        ),

        // Image indicators (hidden when video is playing)
        if (widget.images.length > 1 && !_showVideoPlayer) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children:
                widget.images.asMap().entries.map((entry) {
                  return GestureDetector(
                    onTap: () {
                      carouselController.animateToPage(
                        entry.key,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            currentIndex == entry.key
                                ? AppTheme.getTextPrimary(context)
                                : AppTheme.getTextSecondary(
                                  context,
                                ).withOpacity(0.5),
                      ),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}
