import 'dart:io';
import 'package:flutter/material.dart';
import '../services/app_content_service.dart';
import '../models/app_content_models.dart';
import '../themes/app_theme.dart';

/// Beautiful hero slider widget with cached images
/// Displays at the top of home page with auto-scroll
class HeroSlider extends StatefulWidget {
  final double height;
  final Duration autoScrollInterval;
  final Function(String?)? onSlidePressed;

  const HeroSlider({
    super.key,
    this.height = 180,
    this.autoScrollInterval = const Duration(seconds: 5),
    this.onSlidePressed,
  });

  @override
  State<HeroSlider> createState() => _HeroSliderState();
}

class _HeroSliderState extends State<HeroSlider> {
  final AppContentService _apiService = AppContentService();
  final PageController _pageController = PageController();
  List<HeroSlide> _slides = [];
  bool _isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadSlides();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadSlides() async {
    try {
      final slides = await _apiService.getHeroSlides();
      if (mounted) {
        setState(() {
          _slides = slides;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _startAutoScroll() {
    Future.delayed(widget.autoScrollInterval, () {
      if (mounted && _slides.isNotEmpty) {
        final nextIndex = (_currentIndex + 1) % _slides.length;
        _pageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
        _startAutoScroll();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (_isLoading) {
      return _buildLoadingState();
    }

    // No slides available
    if (_slides.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Slider
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _slides.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return _buildSlideCard(_slides[index], isDark);
            },
          ),
        ),

        const SizedBox(height: 12),

        // Dots indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _slides.length,
            (index) => _buildDotIndicator(index, isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: widget.height,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildSlideCard(HeroSlide slide, bool isDark) {
    return GestureDetector(
      onTap: () {
        if (widget.onSlidePressed != null) {
          widget.onSlidePressed!(slide.buttonLink);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image (from local cache or network)
              _buildImage(slide),

              // Gradient overlay - only show if button exists
              if (slide.buttonText != null &&
                  slide.buttonText!.isNotEmpty &&
                  slide.buttonLink != null &&
                  slide.buttonLink!.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.5),
                      ],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),

              // Only show button if both buttonText and buttonLink exist
              if (slide.buttonText != null &&
                  slide.buttonText!.isNotEmpty &&
                  slide.buttonLink != null &&
                  slide.buttonLink!.isNotEmpty)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      slide.buttonText!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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

  Widget _buildImage(HeroSlide slide) {
    final imagePath = slide.imageDownloadUrl;

    // Check if it's a local file path
    if (imagePath.startsWith('/')) {
      final file = File(imagePath);
      return Image.file(
        file,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
      );
    }

    // Network image (fallback)
    return Image.network(
      imagePath,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
            strokeWidth: 2,
            color: AppTheme.primaryGreen,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildPlaceholder();
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppTheme.primaryGreen.withValues(alpha: 0.1),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 48,
          color: AppTheme.primaryGreen.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildDotIndicator(int index, bool isDark) {
    final isActive = index == _currentIndex;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.primaryGreen
            : (isDark ? Colors.white38 : Colors.grey.shade400),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

