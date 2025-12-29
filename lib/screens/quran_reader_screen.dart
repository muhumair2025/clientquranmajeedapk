import '../widgets/app_text.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xml/xml.dart';
import 'package:provider/provider.dart';
import '../themes/app_theme.dart';
import '../services/lughat_service.dart';
import '../services/tafseer_service.dart';
import '../services/faidi_service.dart';
import '../services/favorites_service.dart';
import '../services/reading_progress_service.dart';
import '../services/quran_api_service.dart';
import '../services/mushaf_database_service.dart';
import '../services/mushaf_download_service.dart';
import '../widgets/media_viewers.dart';
import '../providers/font_provider.dart';
import '../providers/language_provider.dart';
import '../utils/font_manager.dart';
import '../localization/app_localizations_extension.dart';
import 'bulk_audio_player_screen.dart';
import 'dart:async';
import 'package:share_plus/share_plus.dart';

class QuranReaderScreen extends StatefulWidget {
  final int surahIndex;
  final String surahName;
  final int? paraIndex;
  final String? paraName;
  final int? initialAyahIndex;
  final bool highlightInitialAyah; // Whether to highlight the initial ayah on load

  const QuranReaderScreen({
    super.key,
    this.surahIndex = 0,
    this.surahName = '',
    this.paraIndex,
    this.paraName,
    this.initialAyahIndex,
    this.highlightInitialAyah = false,
  });

  @override
  State<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends State<QuranReaderScreen> {
  late PageController _pageController;
  int currentPageNumber = 1; // Mushaf page number (1-604)
  bool isLoading = true;
  Map<int, SurahData> surahsData = {};
  Map<int, Map<int, String>> translationsData = {}; // surahIndex -> ayahIndex -> translation
  
  // Ayah highlighting state
  String? highlightedAyah;
  Timer? highlightTimer;
  List<GlyphInfo> highlightedGlyphs = [];

  // Image dimensions (original Mushaf page size)
  // Pages 1-2 have different dimensions than pages 3-604
  static const double mushafPageWidthSmall = 1014.0;  // Pages 1-2
  static const double mushafPageHeightSmall = 1628.0; // Pages 1-2
  static const double mushafPageWidthLarge = 1352.0;  // Pages 3-604
  static const double mushafPageHeightLarge = 2170.0; // Pages 3-604
  
  /// Get page dimensions based on page number
  static (double width, double height) getPageDimensions(int pageNumber) {
    if (pageNumber <= 2) {
      return (mushafPageWidthSmall, mushafPageHeightSmall);
    }
    return (mushafPageWidthLarge, mushafPageHeightLarge);
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initializeQuranReader();
  }

  Future<void> _initializeQuranReader() async {
    try {
      // Load initial page based on surah or para
      int initialPage = 1;
      
      if (widget.paraIndex != null) {
        // Load page for para
        final page = await MushafDatabaseService.getPageForPara(widget.paraIndex!);
        if (page != null) {
          initialPage = page;
        }
      } else if (widget.surahIndex > 0) {
        // Load page for surah
        final page = await MushafDatabaseService.getPageForSurah(widget.surahIndex);
        if (page != null) {
          initialPage = page;
        }
      }
      
      setState(() {
        currentPageNumber = initialPage;
      });
      
      // Initialize page controller
      _pageController = PageController(initialPage: initialPage - 1);
      
      // Load Quran data for modal functionality
      await _loadQuranData();
      
    } catch (e) {
      debugPrint('Error initializing Quran reader: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadQuranData() async {
    try {
      // Load Arabic text for modal functionality
      final String arabicData = await rootBundle.loadString('assets/quran_data/quran_arabic.xml');
      final arabicDocument = XmlDocument.parse(arabicData);
      
      // Load Pashto translation for modal functionality
      final String translationData = await rootBundle.loadString('assets/quran_data/quran_tr_ps.xml');
      final translationDocument = XmlDocument.parse(translationData);
      
      // Parse Arabic text (minimal data for modal functionality)
      for (var suraElement in arabicDocument.findAllElements('sura')) {
        int surahIndex = int.parse(suraElement.getAttribute('index')!);
        String surahName = suraElement.getAttribute('name')!;
        
        List<AyahData> ayahs = [];
        for (var ayaElement in suraElement.findAllElements('aya')) {
          int ayahIndex = int.parse(ayaElement.getAttribute('index')!);
          String text = ayaElement.getAttribute('text')!;
          
          ayahs.add(AyahData(
            ayahIndex: ayahIndex,
            text: text,
          ));
        }
        
        surahsData[surahIndex] = SurahData(
          index: surahIndex,
          name: surahName,
          ayahs: ayahs,
        );
      }
      
      // Parse translations
      for (var suraElement in translationDocument.findAllElements('sura')) {
        int surahIndex = int.parse(suraElement.getAttribute('index')!);
        Map<int, String> surahTranslations = {};
        
        for (var ayaElement in suraElement.findAllElements('aya')) {
          int ayahIndex = int.parse(ayaElement.getAttribute('index')!);
          String translation = ayaElement.getAttribute('text')!;
          
          surahTranslations[ayahIndex] = translation;
        }
        
        translationsData[surahIndex] = surahTranslations;
      }
      
      setState(() {
        isLoading = false;
      });
      
      // Highlight initial ayah if requested
      _highlightInitialAyahIfNeeded();
      
    } catch (e) {
      debugPrint('Error loading Quran data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Highlight the initial ayah if highlightInitialAyah is true
  void _highlightInitialAyahIfNeeded() async {
    if (!widget.highlightInitialAyah) return;
    
    // Determine which ayah to highlight
    int? surahToHighlight;
    int? ayahToHighlight;
    
    if (widget.initialAyahIndex != null && widget.surahIndex > 0) {
      // Specific ayah was passed
      surahToHighlight = widget.surahIndex;
      ayahToHighlight = widget.initialAyahIndex;
    } else if (widget.surahIndex > 0) {
      // Surah was passed - highlight first ayah
      surahToHighlight = widget.surahIndex;
      ayahToHighlight = 1;
    } else if (widget.paraIndex != null) {
      // Para was passed - get first surah and ayah of the para
      final paraInfo = await MushafDatabaseService.getParaInfo(widget.paraIndex!);
      if (paraInfo != null) {
        surahToHighlight = paraInfo['startSurah'];
        ayahToHighlight = paraInfo['startAyah'];
      }
    }
    
    if (surahToHighlight != null && ayahToHighlight != null && mounted) {
      // Load glyphs for highlighting
      final glyphs = await MushafDatabaseService.getGlyphsForAyah(surahToHighlight, ayahToHighlight);
      
      setState(() {
        highlightedAyah = '${surahToHighlight}_$ayahToHighlight';
        highlightedGlyphs = glyphs;
      });
      
      // Auto-remove highlight after 5 seconds
      highlightTimer?.cancel();
      highlightTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            highlightedAyah = null;
            highlightedGlyphs = [];
          });
        }
      });
    }
  }

  String _convertToArabicNumeral(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((digit) => arabicDigits[int.parse(digit)]).join();
  }

  void _onAyahTap(int surahIndex, int ayahIndex, String ayahText) async {
    // Highlight the ayah
    setState(() {
      highlightedAyah = '${surahIndex}_$ayahIndex';
    });
    
    // Load glyphs for highlighting
    final glyphs = await MushafDatabaseService.getGlyphsForAyah(surahIndex, ayahIndex);
    setState(() {
      highlightedGlyphs = glyphs;
    });
    
    // Cancel any existing timer
    highlightTimer?.cancel();
    
    // Set timer to remove highlight
    highlightTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          highlightedAyah = null;
          highlightedGlyphs = [];
        });
      }
    });
    
    // Update reading progress
    _updateReadingProgress(surahIndex, ayahIndex);
    
    // Show translation modal
    _showTranslationModal(surahIndex, ayahIndex, ayahText);
  }

  void _updateReadingProgress(int surahIndex, int ayahIndex) {
    try {
      final surahName = surahsData[surahIndex]?.name ?? 'Unknown';
      ReadingProgressService.updateProgress(
        surahIndex: surahIndex,
        ayahIndex: ayahIndex,
        surahName: surahName,
        paraIndex: widget.paraIndex,
        paraName: widget.paraName,
      );
    } catch (e) {
      debugPrint('Error saving reading progress: $e');
    }
  }

  Map<String, int>? _getPreviousAyah(int surahIndex, int ayahIndex) {
    if (ayahIndex > 1) {
      return {'surahIndex': surahIndex, 'ayahIndex': ayahIndex - 1};
    } else if (surahIndex > 1) {
      final previousSurah = surahsData[surahIndex - 1];
      if (previousSurah != null) {
        return {'surahIndex': surahIndex - 1, 'ayahIndex': previousSurah.ayahs.length};
      }
    }
    return null;
  }

  Map<String, int>? _getNextAyah(int surahIndex, int ayahIndex) {
    final currentSurah = surahsData[surahIndex];
    if (currentSurah != null) {
      if (ayahIndex < currentSurah.ayahs.length) {
        return {'surahIndex': surahIndex, 'ayahIndex': ayahIndex + 1};
      } else if (surahIndex < 114) {
        return {'surahIndex': surahIndex + 1, 'ayahIndex': 1};
      }
    }
    return null;
  }

  String _getAyahAppText(int surahIndex, int ayahIndex) {
    final surah = surahsData[surahIndex];
    if (surah != null) {
      final ayah = surah.ayahs.firstWhere(
        (a) => a.ayahIndex == ayahIndex,
        orElse: () => AyahData(ayahIndex: ayahIndex, text: ''),
      );
      return ayah.text;
    }
    return '';
  }

  void _navigateToAyah(int newSurahIndex, int newAyahIndex) {
    Navigator.pop(context); // Close current modal
    
    // If navigating to different surah, navigate to new screen
    if (newSurahIndex != widget.surahIndex) {
      final newSurah = surahsData[newSurahIndex];
      if (newSurah != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => QuranReaderScreen(
              surahIndex: newSurahIndex,
              surahName: newSurah.name,
              initialAyahIndex: newAyahIndex,
            ),
          ),
        );
      }
    } else {
      // Same surah, just show the new ayah's modal
      final ayahText = _getAyahAppText(newSurahIndex, newAyahIndex);
      _showTranslationModal(newSurahIndex, newAyahIndex, ayahText);
    }
  }

  void _showTranslationModal(int surahIndex, int ayahIndex, String ayahText) {
    final fontProvider = Provider.of<FontProvider>(context, listen: false);
    final translation = translationsData[surahIndex]?[ayahIndex];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildAsyncTranslationModal(surahIndex, ayahIndex, ayahText, translation, fontProvider),
    );
  }

  Widget _buildAsyncTranslationModal(int surahIndex, int ayahIndex, String ayahText, String? translation, FontProvider fontProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isRTL = FontManager.isRTL(languageProvider.currentLanguage);
    final uiTextDirection = isRTL ? TextDirection.rtl : TextDirection.ltr;

    return FutureBuilder<Map<String, bool>>(
      future: _loadAvailabilityData(surahIndex, ayahIndex),
      builder: (context, snapshot) {
        final availabilityData = snapshot.data ?? {};
        final isLughatAppTextAvailable = availabilityData['lughat_text'] ?? false;
        final isLughatAudioAvailable = availabilityData['lughat_audio'] ?? false;
        final isLughatVideoAvailable = availabilityData['lughat_video'] ?? false;
        final isTafseerAppTextAvailable = availabilityData['tafseer_text'] ?? false;
        final isTafseerAudioAvailable = availabilityData['tafseer_audio'] ?? false;
        final isTafseerVideoAvailable = availabilityData['tafseer_video'] ?? false;
        final isFaidiAppTextAvailable = availabilityData['faidi_text'] ?? false;
        final isFaidiAudioAvailable = availabilityData['faidi_audio'] ?? false;
        final isFaidiVideoAvailable = availabilityData['faidi_video'] ?? false;

        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCardBackground : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Directionality(
                textDirection: uiTextDirection,
                child: Column(
                  children: [
                    // Header with drag handle and actions
                    _buildModalHeader(surahIndex, ayahIndex, ayahText, translation, isDark, languageProvider.currentLanguage),
                  
                  // Content
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [
                        // Arabic Quranic text - uses Text widget to preserve Noorehuda font
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F0E6),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark ? Colors.grey[700]! : AppTheme.primaryGold.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            ayahText,
                            style: TextStyle(
                              fontSize: 22,
                              fontFamily: 'Noorehuda',
                              color: isDark ? Colors.white : const Color(0xFF1A4D2E),
                              height: 1.6,
                            ),
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.center,
                          ),
                        ),

                        // Pashto translation
                        if (translation != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[850] : Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: AppText(
                              translation,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white70 : Colors.black87,
                                height: 1.5,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                        ],

                        const SizedBox(height: 12),

                        // Lughat Section - Inline
                        _buildInlineOptionRow(
                          title: context.l.verseVocabulary,
                          isTextAvailable: isLughatAppTextAvailable,
                          isAudioAvailable: isLughatAudioAvailable,
                          isVideoAvailable: isLughatVideoAvailable,
                          onTextTap: () => _handleOptionTap('lughat_text', surahIndex, ayahIndex),
                          onAudioTap: () => _handleOptionTap('lughat_audio', surahIndex, ayahIndex),
                          onVideoTap: () => _handleOptionTap('lughat_video', surahIndex, ayahIndex),
                          isDark: isDark,
                          languageCode: languageProvider.currentLanguage,
                        ),

                        const SizedBox(height: 8),

                        // Tafseer Section - Inline
                        _buildInlineOptionRow(
                          title: context.l.verseCommentary,
                          isTextAvailable: isTafseerAppTextAvailable,
                          isAudioAvailable: isTafseerAudioAvailable,
                          isVideoAvailable: isTafseerVideoAvailable,
                          onTextTap: () => _handleOptionTap('tafseer_text', surahIndex, ayahIndex),
                          onAudioTap: () => _handleOptionTap('tafseer_audio', surahIndex, ayahIndex),
                          onVideoTap: () => _handleOptionTap('tafseer_video', surahIndex, ayahIndex),
                          isDark: isDark,
                          languageCode: languageProvider.currentLanguage,
                        ),

                        const SizedBox(height: 8),

                        // Faidi Section - Inline
                        _buildInlineOptionRow(
                          title: context.l.verseBenefits,
                          isTextAvailable: isFaidiAppTextAvailable,
                          isAudioAvailable: isFaidiAudioAvailable,
                          isVideoAvailable: isFaidiVideoAvailable,
                          onTextTap: () => _handleOptionTap('faidi_text', surahIndex, ayahIndex),
                          onAudioTap: () => _handleOptionTap('faidi_audio', surahIndex, ayahIndex),
                          onVideoTap: () => _handleOptionTap('faidi_video', surahIndex, ayahIndex),
                          isDark: isDark,
                          languageCode: languageProvider.currentLanguage,
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Builds modal header with navigation, title, and action buttons
  Widget _buildModalHeader(int surahIndex, int ayahIndex, String ayahText, String? translation, bool isDark, String languageCode) {
    final isRTL = FontManager.isRTL(languageCode);
    final uiFont = FontManager.getRegularFont(languageCode);
    
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBackground : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header row with navigation and actions
          Row(
            children: [
              // Navigation buttons - direction aware
              _buildHeaderIconButton(
                icon: isRTL ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                onPressed: () {
                  final nextAyah = _getNextAyah(surahIndex, ayahIndex);
                  if (nextAyah != null) {
                    _navigateToAyah(nextAyah['surahIndex']!, nextAyah['ayahIndex']!);
                  }
                },
                isEnabled: _getNextAyah(surahIndex, ayahIndex) != null,
                isDark: isDark,
              ),
              
              // Title section
              Expanded(
                child: Column(
                  children: [
                    AppText(
                      surahsData[surahIndex]?.name ?? '',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    AppText(
                      '${context.l.verse} ${_convertToArabicNumeral(ayahIndex)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: uiFont,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              _buildHeaderIconButton(
                icon: isRTL ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
                onPressed: () {
                  final previousAyah = _getPreviousAyah(surahIndex, ayahIndex);
                  if (previousAyah != null) {
                    _navigateToAyah(previousAyah['surahIndex']!, previousAyah['ayahIndex']!);
                  }
                },
                isEnabled: _getPreviousAyah(surahIndex, ayahIndex) != null,
                isDark: isDark,
              ),
              
              // Divider
              Container(
                width: 1,
                height: 24,
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                margin: const EdgeInsets.symmetric(horizontal: 4),
              ),
              
              // Action buttons
              _buildHeaderFavoriteButton(surahIndex, ayahIndex, isDark),
              _buildHeaderIconButton(
                icon: Icons.share_outlined,
                onPressed: () => _shareAyah(surahIndex, ayahIndex, ayahText, translation),
                isEnabled: true,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Header icon button - compact
  Widget _buildHeaderIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isEnabled,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onPressed : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            color: isEnabled 
              ? (isDark ? Colors.white70 : AppTheme.primaryGreen)
              : Colors.grey[400],
            size: 22,
          ),
        ),
      ),
    );
  }

  /// Header favorite button with filled/outline states - uses StatefulBuilder for real-time update
  Widget _buildHeaderFavoriteButton(int surahIndex, int ayahIndex, bool isDark) {
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return FutureBuilder<bool>(
          future: FavoritesService.isFavorite(surahIndex, ayahIndex),
          builder: (context, snapshot) {
            final isFavorite = snapshot.data ?? false;
            
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  // Optimistic UI update - change icon immediately
                  setLocalState(() {});
                  
                  if (isFavorite) {
                    await FavoritesService.removeFromFavorites(surahIndex, ayahIndex);
                  } else {
                    await FavoritesService.addToFavorites(surahIndex, ayahIndex);
                  }
                  
                  // Refresh local state to show new status
                  setLocalState(() {});
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    isFavorite ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                    color: isFavorite ? Colors.red : (isDark ? Colors.white70 : Colors.grey[600]),
                    size: 22,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Inline option row - title and 3 icons in same line
  Widget _buildInlineOptionRow({
    required String title,
    required bool isTextAvailable,
    required bool isAudioAvailable,
    required bool isVideoAvailable,
    required VoidCallback onTextTap,
    required VoidCallback onAudioTap,
    required VoidCallback onVideoTap,
    required bool isDark,
    required String languageCode,
  }) {
    final bgColor = isDark ? const Color(0xFFF5F0E6).withOpacity(0.08) : const Color(0xFFF5F0E6);
    final borderColor = isDark ? Colors.grey[700]! : AppTheme.primaryGold.withOpacity(0.4);
    final isRTL = FontManager.isRTL(languageCode);
    final uiFont = FontManager.getRegularFont(languageCode);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          // Title
          Expanded(
            child: AppText(
              '$title:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1A4D2E),
                fontFamily: uiFont,
              ),
              textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
              textAlign: isRTL ? TextAlign.right : TextAlign.left,
            ),
          ),
          
          // Icon buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInlineIconButton(
                icon: Icons.description_outlined,
                isAvailable: isTextAvailable,
                onTap: onTextTap,
                isDark: isDark,
              ),
              const SizedBox(width: 6),
              _buildInlineIconButton(
                icon: Icons.play_circle_outline_rounded,
                isAvailable: isAudioAvailable,
                onTap: onAudioTap,
                isDark: isDark,
              ),
              const SizedBox(width: 6),
              _buildInlineIconButton(
                icon: Icons.videocam_outlined,
                isAvailable: isVideoAvailable,
                onTap: onVideoTap,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Inline icon button - compact circle
  Widget _buildInlineIconButton({
    required IconData icon,
    required bool isAvailable,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final activeColor = isDark ? AppTheme.primaryGold : AppTheme.primaryGreen;
    final inactiveColor = isDark ? Colors.grey[600]! : Colors.grey[400]!;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isAvailable ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isAvailable 
              ? activeColor.withOpacity(0.15) 
              : (isDark ? Colors.grey[800] : Colors.grey[200]),
            border: Border.all(
              color: isAvailable ? activeColor : inactiveColor,
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            color: isAvailable ? activeColor : inactiveColor,
            size: 18,
          ),
        ),
      ),
    );
  }

  Future<Map<String, bool>> _loadAvailabilityData(int surahIndex, int ayahIndex, {bool refresh = false}) async {
    try {
      // Use existing service methods to check availability
      final List<dynamic> results = await Future.wait([
        Future.value(LughatService.getTextData(surahIndex, ayahIndex) != null),
        LughatService.hasAudioData(surahIndex, ayahIndex),
        LughatService.hasVideoData(surahIndex, ayahIndex),
        Future.value(TafseerService.getTextData(surahIndex, ayahIndex) != null),
        TafseerService.hasAudioData(surahIndex, ayahIndex),
        TafseerService.hasVideoData(surahIndex, ayahIndex),
        Future.value(FaidiService.getTextData(surahIndex, ayahIndex) != null),
        FaidiService.hasAudioData(surahIndex, ayahIndex),
        FaidiService.hasVideoData(surahIndex, ayahIndex),
      ]);

      return {
        'lughat_text': results[0] as bool,
        'lughat_audio': results[1] as bool,
        'lughat_video': results[2] as bool,
        'tafseer_text': results[3] as bool,
        'tafseer_audio': results[4] as bool,
        'tafseer_video': results[5] as bool,
        'faidi_text': results[6] as bool,
        'faidi_audio': results[7] as bool,
        'faidi_video': results[8] as bool,
      };
    } catch (e) {
      debugPrint('Error loading availability data: $e');
      return {};
    }
  }

  void _handleOptionTap(String type, int surahIndex, int ayahIndex) {
    switch (type) {
      case 'lughat_text':
        _showLughatText(surahIndex, ayahIndex);
        break;
      case 'lughat_audio':
        _showLughatAudio(surahIndex, ayahIndex);
        break;
      case 'lughat_video':
        _showLughatVideo(surahIndex, ayahIndex);
        break;
      case 'tafseer_text':
        _showTafseerText(surahIndex, ayahIndex);
        break;
      case 'tafseer_audio':
        _showTafseerAudio(surahIndex, ayahIndex);
        break;
      case 'tafseer_video':
        _showTafseerVideo(surahIndex, ayahIndex);
        break;
      case 'faidi_text':
        _showFaidiText(surahIndex, ayahIndex);
        break;
      case 'faidi_audio':
        _showFaidiAudio(surahIndex, ayahIndex);
        break;
      case 'faidi_video':
        _showFaidiVideo(surahIndex, ayahIndex);
        break;
    }
  }

  void _showLughatText(int surahIndex, int ayahIndex) {
    final textData = LughatService.getTextData(surahIndex, ayahIndex);
    if (textData != null) {
      _showTextModal(context.l.verseVocabulary, textData.content);
    } else {
      _showError(context.l.notAvailable);
    }
  }

  void _showLughatAudio(int surahIndex, int ayahIndex) async {
    try {
      final hasAudio = await LughatService.hasAudioData(surahIndex, ayahIndex);
      
      if (hasAudio) {
        if (!mounted) return;
        final surahName = surahsData[surahIndex]?.name ?? '';
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BulkAudioPlayerScreen(
              initialSurahIndex: surahIndex,
              initialAyahIndex: ayahIndex,
              surahName: surahName,
              sectionType: 'lughat',
            ),
          ),
        );
      } else {
        _showError(context.l.notAvailable);
      }
    } catch (e) {
      _showError(context.l.error);
    }
  }

  void _showLughatVideo(int surahIndex, int ayahIndex) async {
    try {
      final videoUrl = await QuranApiService.getVideoUrl(surahIndex, ayahIndex, 'lughat');
      
      if (videoUrl != null && videoUrl.isNotEmpty) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FullScreenVideoPlayer(
              videoUrl: videoUrl,
              title: '${context.l.verseVocabulary} - ${context.l.verse} ${_convertToArabicNumeral(ayahIndex)}',
              surahIndex: surahIndex,
              ayahIndex: ayahIndex,
              sectionType: 'lughat',
            ),
          ),
        );
      } else {
        _showError(context.l.notAvailable);
      }
    } catch (e) {
      _showError(context.l.error);
    }
  }

  void _showTafseerText(int surahIndex, int ayahIndex) {
    final textData = TafseerService.getTextData(surahIndex, ayahIndex);
    if (textData != null) {
      _showTextModal(context.l.verseCommentary, textData.content);
    } else {
      _showError(context.l.notAvailable);
    }
  }

  void _showTafseerAudio(int surahIndex, int ayahIndex) async {
    try {
      final hasAudio = await TafseerService.hasAudioData(surahIndex, ayahIndex);
      
      if (hasAudio) {
        if (!mounted) return;
        final surahName = surahsData[surahIndex]?.name ?? '';
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BulkAudioPlayerScreen(
              initialSurahIndex: surahIndex,
              initialAyahIndex: ayahIndex,
              surahName: surahName,
              sectionType: 'tafseer',
            ),
          ),
        );
      } else {
        _showError(context.l.notAvailable);
      }
    } catch (e) {
      _showError(context.l.error);
    }
  }

  void _showTafseerVideo(int surahIndex, int ayahIndex) async {
    try {
      final videoUrl = await QuranApiService.getVideoUrl(surahIndex, ayahIndex, 'tafseer');
      
      if (videoUrl != null && videoUrl.isNotEmpty) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FullScreenVideoPlayer(
              videoUrl: videoUrl,
              title: '${context.l.verseCommentary} - ${context.l.verse} ${_convertToArabicNumeral(ayahIndex)}',
              surahIndex: surahIndex,
              ayahIndex: ayahIndex,
              sectionType: 'tafseer',
            ),
          ),
        );
      } else {
        _showError(context.l.notAvailable);
      }
    } catch (e) {
      _showError(context.l.error);
    }
  }

  void _showFaidiText(int surahIndex, int ayahIndex) {
    final textData = FaidiService.getTextData(surahIndex, ayahIndex);
    if (textData != null) {
      _showTextModal(context.l.verseBenefits, textData.content);
    } else {
      _showError(context.l.notAvailable);
    }
  }

  void _showFaidiAudio(int surahIndex, int ayahIndex) async {
    try {
      final hasAudio = await FaidiService.hasAudioData(surahIndex, ayahIndex);
      
      if (hasAudio) {
        if (!mounted) return;
        final surahName = surahsData[surahIndex]?.name ?? '';
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BulkAudioPlayerScreen(
              initialSurahIndex: surahIndex,
              initialAyahIndex: ayahIndex,
              surahName: surahName,
              sectionType: 'faidi',
            ),
          ),
        );
      } else {
        _showError(context.l.notAvailable);
      }
    } catch (e) {
      _showError(context.l.error);
    }
  }

  void _showFaidiVideo(int surahIndex, int ayahIndex) async {
    try {
      final videoUrl = await QuranApiService.getVideoUrl(surahIndex, ayahIndex, 'faidi');
      
      if (videoUrl != null && videoUrl.isNotEmpty) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FullScreenVideoPlayer(
              videoUrl: videoUrl,
              title: '${context.l.verseBenefits} - ${context.l.verse} ${_convertToArabicNumeral(ayahIndex)}',
              surahIndex: surahIndex,
              ayahIndex: ayahIndex,
              sectionType: 'faidi',
            ),
          ),
        );
      } else {
        _showError(context.l.notAvailable);
      }
    } catch (e) {
      _showError(context.l.error);
    }
  }

  void _showTextModal(String title, String content) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fontProvider = Provider.of<FontProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCardBackground : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: AppText(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  const Divider(),
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      child: AppText(
                        content,
                        style: TextStyle(
                          fontSize: fontProvider.arabicFontSize * 0.7,
                          color: isDark ? Colors.white : Colors.black87,
                          height: 1.8,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _shareAyah(int surahIndex, int ayahIndex, String ayahText, String? translation) {
    final surahName = surahsData[surahIndex]?.name ?? '';
    final shareText = '''
$surahName - ${context.l.verse} $ayahIndex

$ayahText

${translation ?? ''}

Shared from Quran Majeed App
''';
    Share.share(shareText);
  }

  void _showError(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: AppText(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: context.l.ok,
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        body: isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                    ),
                    const SizedBox(height: 16),
                    AppText(
                      context.l.loading,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              )
            : Stack(
                children: [
                  // Main Mushaf PageView with images
                  PageView.builder(
                    controller: _pageController,
                    itemCount: 604, // Total Mushaf pages
                    onPageChanged: (index) {
                      setState(() {
                        currentPageNumber = index + 1;
                        // Clear highlights when page changes
                        highlightedAyah = null;
                        highlightedGlyphs = [];
                      });
                    },
                    itemBuilder: (context, index) {
                      final pageNumber = index + 1;
                      return _buildMushafPage(pageNumber, isDark);
                    },
                  ),
                  
                  // Minimal header overlay
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: Container(
                        padding: const EdgeInsets.only(
                          left: 12,
                          right: 12,
                          top: 4,
                          bottom: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              (isDark ? Colors.black : Colors.white).withValues(alpha: 0.8),
                              (isDark ? Colors.black : Colors.white).withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Back button
                            IconButton(
                              onPressed: () {
                                SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                                Navigator.pop(context);
                              },
                              icon: Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: isDark ? Colors.white60 : Colors.black54,
                                size: 18,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            
                            // Page number display
                            AppText(
                              _convertToArabicNumeral(currentPageNumber),
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white60 : Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            
                            // Placeholder for symmetry
                            const SizedBox(width: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// Build a single Mushaf page with image and tap detection
  Widget _buildMushafPage(int pageNumber, bool isDark) {
    // Format page number with leading zeros (e.g., page001.png)
    final pageFileName = 'page${pageNumber.toString().padLeft(3, '0')}.png';
    
    // Get correct dimensions for this page (pages 1-2 have different size)
    final (pageWidth, pageHeight) = getPageDimensions(pageNumber);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final containerWidth = constraints.maxWidth;
        final containerHeight = constraints.maxHeight;
        
        // Calculate actual displayed image size with BoxFit.contain
        // Image maintains aspect ratio and fits within container
        final imageAspectRatio = pageWidth / pageHeight;
        final containerAspectRatio = containerWidth / containerHeight;
        
        double displayedWidth, displayedHeight, offsetX, offsetY;
        
        if (containerAspectRatio > imageAspectRatio) {
          // Container is wider than image aspect ratio
          // Image fills height, centered horizontally
          displayedHeight = containerHeight;
          displayedWidth = containerHeight * imageAspectRatio;
          offsetX = (containerWidth - displayedWidth) / 2;
          offsetY = 0;
        } else {
          // Container is taller than image aspect ratio
          // Image fills width, centered vertically
          displayedWidth = containerWidth;
          displayedHeight = containerWidth / imageAspectRatio;
          offsetX = 0;
          offsetY = (containerHeight - displayedHeight) / 2;
        }
        
        // Scale factor (same for both X and Y since aspect ratio is maintained)
        final scale = displayedWidth / pageWidth;
        
        return GestureDetector(
          onTapUp: (details) => _handlePageTap(
            details, 
            pageNumber, 
            scale, 
            offsetX, 
            offsetY,
            displayedWidth,
            displayedHeight,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Mushaf page image - try downloaded first, then fallback to assets
              Center(
                child: FutureBuilder<String?>(
                  future: MushafDownloadService.getPageImagePath(pageNumber),
                  builder: (context, snapshot) {
                    final downloadedPath = snapshot.data;
                    
                    // Use downloaded image if available
                    if (downloadedPath != null) {
                      return ColorFiltered(
                        colorFilter: isDark
                            ? const ColorFilter.matrix(<double>[
                                -1,  0,  0, 0, 255, // Invert red
                                 0, -1,  0, 0, 255, // Invert green
                                 0,  0, -1, 0, 255, // Invert blue
                                 0,  0,  0, 1,   0, // Keep alpha
                              ])
                            : const ColorFilter.mode(
                                Colors.transparent,
                                BlendMode.multiply,
                              ),
                        child: Image.file(
                          File(downloadedPath),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint('Error loading downloaded image: $downloadedPath - $error');
                            // Fallback to asset
                            return _buildAssetImage(pageFileName, pageNumber, isDark);
                          },
                        ),
                      );
                    }
                    
                    // Fallback to bundled asset
                    return _buildAssetImage(pageFileName, pageNumber, isDark);
                  },
                ),
              ),
              
              // Highlight overlay (drawn on top with correct positioning)
              if (highlightedGlyphs.isNotEmpty)
                Positioned(
                  left: offsetX,
                  top: offsetY,
                  width: displayedWidth,
                  height: displayedHeight,
                  child: CustomPaint(
                    painter: AyahHighlightPainter(
                      glyphs: highlightedGlyphs.where((g) => g.pageNumber == pageNumber).toList(),
                      scale: scale,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Build image from bundled assets
  Widget _buildAssetImage(String pageFileName, int pageNumber, bool isDark) {
    final imagePath = 'assets/Mushaf/1441/width_1352/$pageFileName';
    return ColorFiltered(
      colorFilter: isDark
          ? const ColorFilter.matrix(<double>[
              -1,  0,  0, 0, 255, // Invert red
               0, -1,  0, 0, 255, // Invert green
               0,  0, -1, 0, 255, // Invert blue
               0,  0,  0, 1,   0, // Keep alpha
            ])
          : const ColorFilter.mode(
              Colors.transparent,
              BlendMode.multiply,
            ),
      child: Image.asset(
        imagePath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Error loading image: $imagePath - $error');
          return Container(
            color: isDark ? AppTheme.darkBackground : Colors.white,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  AppText(
                    'Page $pageNumber not found',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Handle tap on Mushaf page to detect which ayah was tapped
  Future<void> _handlePageTap(
    TapUpDetails details, 
    int pageNumber, 
    double scale, 
    double offsetX, 
    double offsetY,
    double displayedWidth,
    double displayedHeight,
  ) async {
    // Get tap position relative to container
    final tapLocalX = details.localPosition.dx;
    final tapLocalY = details.localPosition.dy;
    
    // Check if tap is within the image bounds
    if (tapLocalX < offsetX || 
        tapLocalX > offsetX + displayedWidth ||
        tapLocalY < offsetY || 
        tapLocalY > offsetY + displayedHeight) {
      debugPrint('Tap outside image bounds');
      return;
    }
    
    // Convert screen coordinates to original image coordinates
    // First subtract offset to get position relative to image
    // Then divide by scale to get original coordinates
    final imageX = (tapLocalX - offsetX) / scale;
    final imageY = (tapLocalY - offsetY) / scale;
    
    debugPrint('Tap at screen: (${tapLocalX.toStringAsFixed(1)}, ${tapLocalY.toStringAsFixed(1)})');
    debugPrint('Tap at image coords: (${imageX.toStringAsFixed(1)}, ${imageY.toStringAsFixed(1)}) on page $pageNumber');
    
    // Find which ayah was tapped
    final ayahLocation = await MushafDatabaseService.findAyahByCoordinates(
      pageNumber,
      imageX,
      imageY,
    );
    
    if (ayahLocation != null) {
      debugPrint('Ayah found: Surah ${ayahLocation.surahNumber}, Ayah ${ayahLocation.ayahNumber}');
      
      // Get ayah text from database or surahsData
      String? ayahText = await MushafDatabaseService.getArabicText(
        ayahLocation.surahNumber,
        ayahLocation.ayahNumber,
      );
      
      // Fallback to XML data if database query fails
      ayahText ??= _getAyahAppText(ayahLocation.surahNumber, ayahLocation.ayahNumber);
      
      if (ayahText.isNotEmpty) {
        _onAyahTap(ayahLocation.surahNumber, ayahLocation.ayahNumber, ayahText);
      }
    } else {
      debugPrint('No ayah found at this location');
    }
  }

  @override
  void dispose() {
    highlightTimer?.cancel();
    _pageController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }
}

/// Custom painter for drawing ayah highlights
class AyahHighlightPainter extends CustomPainter {
  final List<GlyphInfo> glyphs;
  final double scale;
  
  AyahHighlightPainter({
    required this.glyphs,
    required this.scale,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    if (glyphs.isEmpty) return;
    
    // Transparent green fill only (no border as per user request)
    final paint = Paint()
      ..color = AppTheme.primaryGreen.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    
    // Draw highlight for each glyph segment
    for (var glyph in glyphs) {
      // Scale coordinates from original image size to displayed size
      final rect = Rect.fromLTRB(
        glyph.minX * scale,
        glyph.minY * scale,
        glyph.maxX * scale,
        glyph.maxY * scale,
      );
      
      // Draw filled rectangle only (no border)
      canvas.drawRect(rect, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant AyahHighlightPainter oldDelegate) {
    return glyphs != oldDelegate.glyphs || scale != oldDelegate.scale;
  }
}

// Data models
class SurahData {
  final int index;
  final String name;
  final List<AyahData> ayahs;

  SurahData({
    required this.index,
    required this.name,
    required this.ayahs,
  });
}

class AyahData {
  final int ayahIndex;
  final String text;

  AyahData({
    required this.ayahIndex,
    required this.text,
  });
}
