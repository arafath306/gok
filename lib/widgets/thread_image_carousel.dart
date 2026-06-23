import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../screens/full_screen_media_viewer.dart';

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

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) return const SizedBox.shrink();

    final isSmall = widget.height <= 120;
    final borderRadius = BorderRadius.circular(isSmall ? 8.0 : 12.0);

    if (widget.imageUrls.length == 1) {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FullScreenMediaViewer(
                imageUrls: widget.imageUrls,
                initialIndex: 0,
              ),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: borderRadius,
          child: CachedNetworkImage(
            imageUrl: widget.imageUrls.first,
            height: widget.height,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
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
              color: Colors.black12,
              child: const Icon(Icons.broken_image, color: Colors.white54),
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        height: widget.height,
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
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FullScreenMediaViewer(
                          imageUrls: widget.imageUrls,
                          initialIndex: index,
                        ),
                      ),
                    );
                  },
                  child: CachedNetworkImage(
                    imageUrl: widget.imageUrls[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (context, url) => Container(
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
                      color: Colors.black12,
                      child: const Icon(Icons.broken_image, color: Colors.white54),
                    ),
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
                            ? const Color(0xFF7C4DFF)
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
    );
  }
}
