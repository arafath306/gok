import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../screens/full_screen_media_viewer.dart';
import 'package:provider/provider.dart';
import '../services/general_settings_provider.dart';

class ThreadImageCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final double height;

  const ThreadImageCarousel({
    super.key,
    required this.imageUrls,
    this.height = 220,
  });

  @override
  State<ThreadImageCarousel> createState() => _ThreadImageCarouselState();
}

class _ThreadImageCarouselState extends State<ThreadImageCarousel> {
  int _currentIndex = 0;
  double? _dynamicAspectRatio;

  @override
  void initState() {
    super.initState();
    _resolveFirstImageAspectRatio();
  }

  @override
  void didUpdateWidget(covariant ThreadImageCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrls != widget.imageUrls) {
      _resolveFirstImageAspectRatio();
    }
  }

  void _resolveFirstImageAspectRatio() {
    if (widget.imageUrls.length <= 1) return; // Only needed for multi-image carousel
    try {
      final ImageStream stream = CachedNetworkImageProvider(widget.imageUrls.first)
          .resolve(const ImageConfiguration());
      late ImageStreamListener listener;
      listener = ImageStreamListener((ImageInfo info, bool _) {
        if (mounted) {
          final double w = info.image.width.toDouble();
          final double h = info.image.height.toDouble();
          if (w > 0 && h > 0) {
            final double calculatedRatio = w / h;
            // Prevent the carousel from becoming insanely tall by clamping at 0.75 (4:5 portrait)
            // But let it be as wide as it needs to be so wide images aren't cropped.
            final double clampedRatio = calculatedRatio < 0.75 ? 0.75 : calculatedRatio;
            setState(() {
              _dynamicAspectRatio = clampedRatio;
            });
          }
        }
        stream.removeListener(listener);
      });
      stream.addListener(listener);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) return const SizedBox.shrink();

    final lowDataMode = Provider.of<GeneralSettingsProvider>(context).lowDataMode;

    String getOptimizedUrl(String originalUrl) {
      if (!lowDataMode) return originalUrl;
      if (originalUrl.contains('/object/public/')) {
        return '${originalUrl.replaceFirst('/object/public/', '/render/image/public/')}?quality=20&width=300';
      }
      return originalUrl;
    }

    final isSmall = widget.height <= 120;
    final borderRadius = BorderRadius.circular(isSmall ? 8.0 : 12.0);
    final screenHeight = MediaQuery.of(context).size.height;

    // ── Small quote-post preview ─────────────────────────────────────────────
    if (isSmall) {
      return GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FullScreenMediaViewer(
              imageUrls: widget.imageUrls,
              initialIndex: 0,
            ),
          ),
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: CachedNetworkImage(
            imageUrl: getOptimizedUrl(widget.imageUrls.first),
            memCacheWidth: 400,
            height: widget.height,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(color: Colors.black12),
            errorWidget: (context, url, error) => Container(
              color: Colors.black12,
              child: const Icon(Icons.broken_image, color: Colors.white54),
            ),
          ),
        ),
      );
    }

    // ── Single Image (Original Flawless Implementation) ──────────────────────
    if (widget.imageUrls.length == 1) {
      return GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FullScreenMediaViewer(
              imageUrls: widget.imageUrls,
              initialIndex: 0,
            ),
          ),
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: screenHeight * 0.75, // Caps height for extremely tall images
            ),
            child: CachedNetworkImage(
              imageUrl: getOptimizedUrl(widget.imageUrls.first),
              memCacheWidth: 800,
              width: double.infinity,
              // fitWidth makes the image perfectly fill the screen width.
              // If it's taller than 75% of screen height, it seamlessly crops the top/bottom 
              // which looks natural in a feed, just like the original code.
              fit: BoxFit.fitWidth,
              placeholder: (context, url) => Container(
                height: 220,
                color: Colors.black12,
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E824C)),
                    ),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                height: 220,
                color: Colors.black12,
                child: const Icon(Icons.broken_image, color: Colors.white54),
              ),
            ),
          ),
        ),
      );
    }

    // ── Multiple Images Carousel ──────────────────────────────────────────────
    // Uses the dynamic aspect ratio to size the PageView properly.
    final double carouselAspectRatio = _dynamicAspectRatio ?? 1.0;

    return ClipRRect(
      borderRadius: borderRadius,
      child: AspectRatio(
        aspectRatio: carouselAspectRatio,
        child: Container(
          width: double.infinity,
          color: Colors.black12,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              PageView.builder(
                itemCount: widget.imageUrls.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FullScreenMediaViewer(
                          imageUrls: widget.imageUrls,
                          initialIndex: index,
                        ),
                      ),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: getOptimizedUrl(widget.imageUrls[index]),
                      memCacheWidth: 800,
                      // fitWidth mimics the single image behavior inside the AspectRatio container.
                      fit: BoxFit.fitWidth,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: (context, url) => const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E824C)),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.white54),
                    ),
                  );
                },
              ),
              Positioned(
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      widget.imageUrls.length,
                      (index) => Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentIndex == index
                              ? Theme.of(context).primaryColor
                              : Colors.white60,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
