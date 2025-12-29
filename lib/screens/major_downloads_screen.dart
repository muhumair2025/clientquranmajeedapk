import '../widgets/app_text.dart';
import 'package:flutter/material.dart';
import '../themes/app_theme.dart';
import '../localization/app_localizations_extension.dart';
import 'audio_downloads_screen.dart';
import 'video_downloads_screen.dart';
import '../utils/theme_extensions.dart';

class MajorDownloadsScreen extends StatefulWidget {
  const MajorDownloadsScreen({super.key});

  @override
  State<MajorDownloadsScreen> createState() => _MajorDownloadsScreenState();
}

class _MajorDownloadsScreenState extends State<MajorDownloadsScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? context.backgroundColor : Colors.grey.shade50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              AppText(
                context.l.downloads,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : context.backgroundColor,
                ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 4),
              AppText(
                context.l.downloadContent,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.grey.shade600,
                ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 20),
              
              // Download Cards
              Expanded(
                child: ListView(
                  children: [
                    // Ayah Lughat Tashreeh Card
                    _buildDownloadCard(
                      context: context,
                      isDark: isDark,
                      title: context.l.verseVocabulary,
                      subtitle: context.l.vocabularyDescription,
                      icon: Icons.school_rounded,
                      gradientColors: [
                        context.primaryColor,
                        context.primaryColor.withValues(alpha: 0.8),
                      ],
                      onAudioTap: () => _navigateToAudioDownloads('lughat'),
                      onVideoTap: () => _navigateToVideoDownloads('lughat'),
                      isAvailable: true,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Ayah Lughat Tarjuma Tafseer Card
                    _buildDownloadCard(
                      context: context,
                      isDark: isDark,
                      title: context.l.verseCommentary,
                      subtitle: context.l.commentaryDescription,
                      icon: Icons.library_books_rounded,
                      gradientColors: [
                        context.primaryColor.withValues(alpha: 0.8),
                        context.primaryColor.withValues(alpha: 0.6),
                      ],
                      onAudioTap: () => _navigateToAudioDownloads('tafseer'),
                      onVideoTap: () => _navigateToVideoDownloads('tafseer'),
                      isAvailable: true,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Ayah Lughat Faidi Card
                    _buildDownloadCard(
                      context: context,
                      isDark: isDark,
                      title: context.l.verseBenefits,
                      subtitle: context.l.benefitsDescription,
                      icon: Icons.star_rounded,
                      gradientColors: [
                        context.primaryColor.withValues(alpha: 0.7),
                        context.primaryColor.withValues(alpha: 0.5),
                      ],
                      onAudioTap: () => _navigateToAudioDownloads('faidi'),
                      onVideoTap: () => _navigateToVideoDownloads('faidi'),
                      isAvailable: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadCard({
    required BuildContext context,
    required bool isDark,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback? onAudioTap,
    required VoidCallback? onVideoTap,
    required bool isAvailable,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 2),
                      AppText(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context: context,
                    label: context.l.audio,
                    icon: Icons.play_circle_rounded,
                    onTap: onAudioTap,
                    isEnabled: isAvailable,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    context: context,
                    label: context.l.video,
                    icon: Icons.videocam_rounded,
                    onTap: onVideoTap,
                    isEnabled: isAvailable,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
    required bool isEnabled,
  }) {
    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isEnabled 
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEnabled 
                ? Colors.white.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isEnabled 
                  ? Colors.white 
                  : Colors.white.withValues(alpha: 0.5),
              size: 20,
            ),
            const SizedBox(width: 8),
            AppText(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isEnabled 
                    ? Colors.white 
                    : Colors.white.withValues(alpha: 0.5),
              ),
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAudioDownloads(String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AudioDownloadsScreen(sectionType: type),
      ),
    );
  }

  void _navigateToVideoDownloads(String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoDownloadsScreen(sectionType: type),
      ),
    );
  }
}
