import 'package:flutter/material.dart';
import '../themes/app_theme.dart';
import '../utils/theme_extensions.dart';

/// Floating action button with expandable social media icons
/// Expands upward showing Facebook, YouTube, TikTok, Instagram, WhatsApp
class FloatingSocialButton extends StatefulWidget {
  final String? facebookUrl;
  final String? youtubeUrl;
  final String? tiktokUrl;
  final String? instagramUrl;
  final String? whatsappUrl;
  final Function(String url)? onSocialPressed;

  const FloatingSocialButton({
    super.key,
    this.facebookUrl,
    this.youtubeUrl,
    this.tiktokUrl,
    this.instagramUrl,
    this.whatsappUrl,
    this.onSocialPressed,
  });

  @override
  State<FloatingSocialButton> createState() => _FloatingSocialButtonState();
}

class _FloatingSocialButtonState extends State<FloatingSocialButton>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 0.125).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _handleSocialPress(String? url) {
    if (url != null && url.isNotEmpty && widget.onSocialPressed != null) {
      widget.onSocialPressed!(url);
    }
    _toggleExpand();
  }

  @override
  Widget build(BuildContext context) {
    // Fixed height to accommodate 5 social buttons + main button
    // Main button: 48px + spacing: 12px + (5 buttons × 44px) + (4 spacings × 10px) = 300px
    const double totalHeight = 350.0;
    
    return SizedBox(
      width: 50,
      height: totalHeight,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Social buttons (expanded upward) - WhatsApp added as index 4
          if (_isExpanded || _animationController.isAnimating)
            _buildSocialButton(
              index: 4,
              imagePath: 'assets/socials/whatsapp.png',
              label: 'WhatsApp',
              url: widget.whatsappUrl ?? 'https://wa.me',
            ),
          if (_isExpanded || _animationController.isAnimating)
            _buildSocialButton(
              index: 3,
              imagePath: 'assets/socials/instagram.png',
              label: 'Instagram',
              url: widget.instagramUrl ?? 'https://instagram.com',
            ),
          if (_isExpanded || _animationController.isAnimating)
            _buildSocialButton(
              index: 2,
              imagePath: 'assets/socials/tiktok.png',
              label: 'TikTok',
              url: widget.tiktokUrl ?? 'https://tiktok.com',
            ),
          if (_isExpanded || _animationController.isAnimating)
            _buildSocialButton(
              index: 1,
              imagePath: 'assets/socials/youtube.png',
              label: 'YouTube',
              url: widget.youtubeUrl ?? 'https://youtube.com',
            ),
          if (_isExpanded || _animationController.isAnimating)
            _buildSocialButton(
              index: 0,
              imagePath: 'assets/socials/facebook.png',
              label: 'Facebook',
              url: widget.facebookUrl ?? 'https://facebook.com',
            ),

          // Main floating button (clean, no shadow)
          Positioned(
            bottom: 0,
            child: GestureDetector(
              onTap: _toggleExpand,
              child: AnimatedBuilder(
                animation: _rotationAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationAnimation.value * 3.14159 * 2,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            context.primaryColor,
                            context.primaryColor.darker(0.2),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          _isExpanded ? Icons.close : Icons.share,
                          key: ValueKey(_isExpanded),
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required int index,
    required String imagePath,
    required String label,
    required String url,
  }) {
    // Calculate position from bottom with consistent spacing
    // Button spacing: 12px from main button + (index × 54px spacing between buttons)
    final double bottomOffset = 60.0 + (index * 54.0);

    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        // Clamp values to valid range
        final scale = _expandAnimation.value.clamp(0.0, 1.0);
        final opacity = _expandAnimation.value.clamp(0.0, 1.0);

        return Positioned(
          bottom: bottomOffset * scale,
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: GestureDetector(
                onTap: () => _handleSocialPress(url),
                child: Container(
                  width: 44,
                  height: 44,
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
