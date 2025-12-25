import 'dart:io';
import 'package:flutter/material.dart';
import '../services/app_content_service.dart';
import '../models/app_content_models.dart';
import '../themes/app_theme.dart';

/// Splash screen that displays cached image from API (full screen)
/// Only shows API image, no default mockup
class SplashScreen extends StatefulWidget {
  final VoidCallback onInitializationComplete;
  final Duration minimumDisplayDuration;

  const SplashScreen({
    super.key,
    required this.onInitializationComplete,
    this.minimumDisplayDuration = const Duration(seconds: 2),
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final AppContentService _apiService = AppContentService();
  SplashScreenData? _splashData;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _initialize();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    final startTime = DateTime.now();

    try {
      // Load splash screen data (from cache or API)
      final splashData = await _apiService.getSplashScreen();

      if (mounted) {
        setState(() {
          _splashData = splashData;
        });
        _fadeController.forward();
      }

      // Ensure minimum display duration for UX
      final elapsedTime = DateTime.now().difference(startTime);
      if (elapsedTime < widget.minimumDisplayDuration) {
        await Future.delayed(widget.minimumDisplayDuration - elapsedTime);
      }

      // Complete initialization
      if (mounted) {
        widget.onInitializationComplete();
      }
    } catch (e) {
      debugPrint('❌ Splash initialization error: $e');
      // On error, proceed quickly
      if (mounted) {
        widget.onInitializationComplete();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only show splash if API image exists
    if (_splashData != null &&
        _splashData!.hasSplashScreen &&
        _splashData!.imageDownloadUrl != null) {
      return Scaffold(
        backgroundColor: AppTheme.primaryGreen,
        body: _buildSplashImage(),
      );
    }

    // No splash image - just show simple loading with green background
    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      body: Center(
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withValues(alpha: 0.8)),
        ),
      ),
    );
  }

  Widget _buildSplashImage() {
    final imagePath = _splashData!.imageDownloadUrl!;

    // Check if it's a local file path
    if (imagePath.startsWith('/')) {
      final file = File(imagePath);
      return FadeTransition(
        opacity: _fadeAnimation,
        child: Image.file(
          file,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return const SizedBox.shrink();
          },
        ),
      );
    }

    // Network image (fallback)
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Image.network(
        imagePath,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withValues(alpha: 0.8)),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

