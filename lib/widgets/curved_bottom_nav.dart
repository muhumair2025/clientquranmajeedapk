import 'package:flutter/material.dart';
import '../themes/app_theme.dart';
import '../localization/app_localizations_extension.dart';
import '../utils/theme_extensions.dart';

class CurvedBottomNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final List<BottomNavItem> items;

  const CurvedBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final itemCount = items.length;
    
    // Add horizontal padding to give edge items more space
    const horizontalPadding = 12.0;
    final availableWidth = screenWidth - (horizontalPadding * 2);
    final itemWidth = availableWidth / itemCount;
    
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    
    // Find active item's list index
    final activeListIndex = items.indexWhere((item) => item.index == selectedIndex);
    
    // Calculate notch X position with padding offset
    double notchCenterX;
    if (isRTL) {
      notchCenterX = screenWidth - horizontalPadding - (activeListIndex * itemWidth + itemWidth / 2);
    } else {
      notchCenterX = horizontalPadding + (activeListIndex * itemWidth + itemWidth / 2);
    }
    
    // Get safe area padding for proper spacing
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const barHeight = 60.0;
    final totalHeight = 85.0 + bottomPadding;
    
    return SizedBox(
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Subtle ambient glow under notch for premium look
          AnimatedPositioned(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            bottom: bottomPadding + 38,
            left: notchCenterX - 35,
            child: IgnorePointer(
              child: Container(
                width: 70,
                height: 30,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      context.primaryColor.withValues(alpha: 0.08),
                      context.primaryColor.withValues(alpha: 0.02),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // Bottom bar with curved notch
          Positioned(
            bottom: bottomPadding,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: Size(screenWidth, barHeight),
              painter: _CurvedNavBarPainter(
                notchCenterX: notchCenterX,
                notchRadius: 32,
                backgroundColor: context.primaryColor,
                shadowColor: Colors.black.withValues(alpha: 0.15),
              ),
            ),
          ),
          // Navigation items with padding
          Positioned(
            bottom: bottomPadding + 4,
            left: horizontalPadding,
            right: horizontalPadding,
            child: SizedBox(
              height: barHeight - 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: items.map((item) => Expanded(
                  child: _buildNavItem(
                    context,
                    item,
                    item.index == selectedIndex,
                    itemWidth,
                  ),
                )).toList(),
              ),
            ),
          ),
          // Floating active circle - aligned with notch
          AnimatedPositioned(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            bottom: 42 + bottomPadding,
            left: notchCenterX - 26,
            child: IgnorePointer(
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    // Outer soft shadow for depth
                    BoxShadow(
                      color: context.primaryColor.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                    // Middle shadow for definition
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                      spreadRadius: -2,
                    ),
                    // Inner shadow for elevation
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                      spreadRadius: -1,
                    ),
                  ],
                ),
                child: Icon(
                  _getActiveIcon(),
                  color: context.primaryColor,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  IconData _getActiveIcon() {
    final activeItem = items.firstWhere(
      (item) => item.index == selectedIndex,
      orElse: () => items.first,
    );
    return activeItem.filledIcon;
  }

  Widget _buildNavItem(BuildContext context, BottomNavItem item, bool isSelected, double itemWidth) {
    final Color activeColor = context.primaryColor;
    final Color inactiveColor = Colors.white.withValues(alpha: 0.85);
    
    // Responsive font size
    final screenWidth = MediaQuery.of(context).size.width;
    double baseFontSize;
    if (screenWidth < 340) {
      baseFontSize = 9.0;
    } else if (screenWidth < 380) {
      baseFontSize = 10.0;
    } else if (screenWidth < 420) {
      baseFontSize = 10.5;
    } else {
      baseFontSize = 11.0;
    }
    
    return GestureDetector(
      onTap: () => onItemSelected(item.index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: BoxConstraints(maxWidth: itemWidth),
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon - hidden when selected (shown in floating circle)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isSelected ? 0.0 : 1.0,
              child: Icon(
                item.outlinedIcon,
                color: inactiveColor,
                size: 23,
              ),
            ),
            const SizedBox(height: 4),
            // Label - only shown for selected item
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: isSelected ? 16 : 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isSelected ? 1.0 : 0.0,
                child: isSelected
                    ? FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          item.label,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          style: context.textStyle(
                            fontSize: baseFontSize,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : const SizedBox(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Bottom nav item data model
class BottomNavItem {
  final int index;
  final IconData outlinedIcon;
  final IconData filledIcon;
  final String label;

  const BottomNavItem({
    required this.index,
    required this.outlinedIcon,
    required this.filledIcon,
    required this.label,
  });
}

// Custom painter for curved bottom navigation bar with notch
class _CurvedNavBarPainter extends CustomPainter {
  final double notchCenterX;
  final double notchRadius;
  final Color backgroundColor;
  final Color shadowColor;

  _CurvedNavBarPainter({
    required this.notchCenterX,
    required this.notchRadius,
    required this.backgroundColor,
    required this.shadowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final path = _createPath(size);

    // Multi-layered shadow for professional depth
    // Outer soft shadow
    canvas.drawShadow(path, shadowColor.withValues(alpha: 0.04), 16, false);
    // Middle shadow for definition
    canvas.drawShadow(path, shadowColor.withValues(alpha: 0.06), 8, false);
    // Inner shadow for subtle elevation
    canvas.drawShadow(path, shadowColor.withValues(alpha: 0.08), 4, false);
    
    // Draw the main background
    canvas.drawPath(path, paint);
  }

  Path _createPath(Size size) {
    final path = Path();
    final curveDepth = notchRadius + 8;
    final cornerRadius = 10.0;
    
    // Use the exact notch position - no clamping to maintain alignment
    final notchX = notchCenterX;
    
    // Calculate curve control points
    final curveWidth = notchRadius + 8;
    
    // Start from bottom left
    path.moveTo(0, size.height);
    path.lineTo(0, cornerRadius);
    
    // Round top left corner
    path.quadraticBezierTo(0, 0, cornerRadius, 0);
    
    // Line to start of notch curve (left side)
    final notchLeftStart = notchX - curveWidth - notchRadius;
    if (notchLeftStart > cornerRadius) {
      path.lineTo(notchLeftStart, 0);
    }
    
    // Smooth curve into notch from left
    path.quadraticBezierTo(
      notchX - notchRadius - 4, 0,
      notchX - notchRadius + 5, curveDepth * 0.35,
    );
    
    // Main notch arc
    path.arcToPoint(
      Offset(notchX + notchRadius - 5, curveDepth * 0.35),
      radius: Radius.circular(notchRadius + 4),
      clockwise: false,
    );
    
    // Smooth curve out of notch to right
    final notchRightEnd = notchX + curveWidth + notchRadius;
    path.quadraticBezierTo(
      notchX + notchRadius + 4, 0,
      notchRightEnd < size.width - cornerRadius ? notchRightEnd : size.width - cornerRadius, 0,
    );
    
    // Line to top right corner
    if (notchRightEnd < size.width - cornerRadius) {
      path.lineTo(size.width - cornerRadius, 0);
    }
    
    // Round top right corner
    path.quadraticBezierTo(size.width, 0, size.width, cornerRadius);
    
    // Right side and bottom
    path.lineTo(size.width, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldRepaint(_CurvedNavBarPainter oldDelegate) {
    return oldDelegate.notchCenterX != notchCenterX ||
           oldDelegate.notchRadius != notchRadius;
  }
}
