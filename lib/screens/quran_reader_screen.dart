import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xml/xml.dart';
import 'package:provider/provider.dart';
import '../themes/app_theme.dart';
import '../services/lughat_service.dart';
import '../widgets/media_viewers.dart';
import '../providers/font_provider.dart';
import 'dart:async';

class QuranReaderScreen extends StatefulWidget {
  final int surahIndex;
  final String surahName;
  final int? paraIndex;
  final String? paraName;

  const QuranReaderScreen({
    super.key,
    this.surahIndex = 0,
    this.surahName = '',
    this.paraIndex,
    this.paraName,
  });

  @override
  State<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends State<QuranReaderScreen> {
  late PageController _pageController;
  List<QuranPage> pages = [];
  int currentPage = 0;
  bool isLoading = true;
  Map<int, SurahData> surahsData = {};
  Map<int, Map<int, String>> translationsData = {}; // surahIndex -> ayahIndex -> translation
  
  // Ayah highlighting state
  String? highlightedAyah;
  Timer? highlightTimer;
  
  // Standard Quran constants
  static const int linesPerPage = 15;
  static const double wordSpacing = 1.0; // Reduced word spacing

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _pageController = PageController();
    _loadQuranData();
    
    // Listen to font changes and regenerate pages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FontProvider>(context, listen: false).addListener(_onFontChanged);
    });
  }
  
  void _onFontChanged() {
    if (mounted && surahsData.isNotEmpty) {
      _generateQuranPages();
    }
  }

  Future<void> _loadQuranData() async {
    try {
      // Load Arabic text
      final String arabicData = await rootBundle.loadString('assets/quran_data/quran_arabic.xml');
      final arabicDocument = XmlDocument.parse(arabicData);
      
      // Load Pashto translation
      final String translationData = await rootBundle.loadString('assets/quran_data/quran_tr_ps.xml');
      final translationDocument = XmlDocument.parse(translationData);
      
      // Parse Arabic text
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
      
      // Wait for next frame to ensure widget is built before generating pages
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _generateQuranPages();
      });
      
    } catch (e) {
      debugPrint('Error loading Quran data: $e');
    }
  }

  void _generateQuranPages() {
    pages.clear();
    
    // Handle both Surah and Para navigation
    if (widget.paraIndex != null) {
      // TODO: Load para data when para structure is available
      // For now, we'll handle surah only
    }
    
    if (surahsData.containsKey(widget.surahIndex)) {
      SurahData currentSurah = surahsData[widget.surahIndex]!;
      
      // Get current font size to determine layout type
      FontSize currentFontSize = Provider.of<FontProvider>(context, listen: false).selectedFontSize;
      
      List<QuranPageData> pageDataList;
      if (currentFontSize.needsFlexibleLayout) {
        // For XL font, use flexible layout with more lines and scrolling
        pageDataList = _generateFlexibleQuranPages(currentSurah, currentFontSize.size);
      } else {
        // For other fonts, use standard 15-line layout
        pageDataList = _generateStandardQuranPages(currentSurah);
      }
      
      for (int i = 0; i < pageDataList.length; i++) {
        pages.add(QuranPage(
          pageNumber: i + 1,
          lines: pageDataList[i].lines,
          surahName: currentSurah.name,
          isFirstPage: i == 0,
          ayahSegments: pageDataList[i].ayahSegments,
        ));
      }
    }
    
    setState(() {
      isLoading = false;
    });
  }

  String _convertToArabicNumeral(int number) {
    const arabicNumerals = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((digit) => arabicNumerals[int.parse(digit)]).join();
  }

  List<QuranPageData> _generateStandardQuranPages(SurahData surahData) {
    List<QuranPageData> pages = [];
    
    // Get screen dimensions
    final screenSize = MediaQuery.of(context).size;
    final double availableWidth = screenSize.width - 16; // 8px padding on each side
    
    // Build continuous text with ayah tracking
    List<AyahSegment> allSegments = [];
    
    for (var ayah in surahData.ayahs) {
      String ayahText = '${ayah.text} ﴿${_convertToArabicNumeral(ayah.ayahIndex)}﴾';
      List<String> words = ayahText.split(' ').where((word) => word.trim().isNotEmpty).toList();
      
      for (String word in words) {
        allSegments.add(AyahSegment(
          text: word,
          surahIndex: surahData.index,
          ayahIndex: ayah.ayahIndex,
          ayahFullText: ayah.text,
        ));
      }
    }
    
    if (allSegments.isEmpty) return pages;
    
    // Calculate words per line dynamically based on screen width
    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.justify,
    );
    
    // Generate pages with exactly 15 lines each
    int segmentIndex = 0;
    int pageNumber = 0;
    
    while (segmentIndex < allSegments.length) {
      List<String> pageLines = [];
      List<List<AyahSegment>> pageAyahSegments = [];
      int startingSegmentIndex = segmentIndex;
      
      // Add Surah header for first page
      if (pageNumber == 0) {
        pageLines.add('سُورَةُ ${surahData.name}');
        pageAyahSegments.add([]); // Empty segments for header
        
        // Add Bismillah (except for Surah At-Tawbah)
        if (widget.surahIndex != 9) {
          pageLines.add('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ');
          pageAyahSegments.add([]); // Empty segments for Bismillah
        }
      }
      
      // Fill remaining lines with content
      while (pageLines.length < linesPerPage && segmentIndex < allSegments.length) {
        List<AyahSegment> lineSegments = [];
        double currentLineWidth = 0;
        
        // First, add segments until we reach about 90% of line width
        while (segmentIndex < allSegments.length) {
          AyahSegment testSegment = allSegments[segmentIndex];
          
          // Create test line
          List<String> testWords = lineSegments.map((s) => s.text).toList();
          testWords.add(testSegment.text);
          String testLine = testWords.join(' ');
          
          // Measure the line with the new word
          textPainter.text = TextSpan(
            text: testLine,
            style: TextStyle(
              fontFamily: 'Al Qalam Quran Majeed', // Keep default for measurement
              fontSize: Provider.of<FontProvider>(context, listen: false).arabicFontSize,
              wordSpacing: wordSpacing,
            ),
          );
          textPainter.layout();
          currentLineWidth = textPainter.width;
          
          // Add segment if it fits
          if (currentLineWidth <= availableWidth) {
            lineSegments.add(testSegment);
            segmentIndex++;
            
            // Only check for break points after we have substantial content
            if (currentLineWidth >= availableWidth * 0.85) {
              String currentWord = testSegment.text;
              
              // Check if we're at a natural break point
              if (currentWord.contains('﴾')) {
                // Ayah ending - good place to break
                break;
              } else if (currentWord.contains('ۚ') || currentWord.contains('ۖ') || 
                         currentWord.contains('ۗ') || currentWord.contains('ۘ') ||
                         currentWord.contains('ۙ') || currentWord.contains('ۛ')) {
                // Waqf marks - also good places to break
                if (currentLineWidth >= availableWidth * 0.9) {
                  break;
                }
              }
            }
          } else {
            // Word doesn't fit, but check if line is too short
            if (lineSegments.length < 3) {
              // Force add the segment if line has too few words
              lineSegments.add(testSegment);
              segmentIndex++;
            }
            break;
          }
        }
        
        // Ensure we have at least some content on each line
        if (lineSegments.isEmpty && segmentIndex < allSegments.length) {
          // Force at least one segment
          lineSegments.add(allSegments[segmentIndex]);
          segmentIndex++;
        }
        
        if (lineSegments.isNotEmpty) {
          pageLines.add(lineSegments.map((s) => s.text).join(' '));
          pageAyahSegments.add(lineSegments);
        }
      }
      
      // If we couldn't fit any new segments on this page, force at least one segment
      if (segmentIndex == startingSegmentIndex && segmentIndex < allSegments.length) {
        if (pageLines.length < linesPerPage) {
          pageLines.add(allSegments[segmentIndex].text);
          pageAyahSegments.add([allSegments[segmentIndex]]);
          segmentIndex++;
        }
      }
      
      // Pad with empty lines if needed
      while (pageLines.length < linesPerPage) {
        pageLines.add('');
        pageAyahSegments.add([]);
      }
      
      // Trim to exactly 15 lines
      if (pageLines.length > linesPerPage) {
        pageLines = pageLines.take(linesPerPage).toList();
        pageAyahSegments = pageAyahSegments.take(linesPerPage).toList();
      }
      
      pages.add(QuranPageData(
        lines: pageLines,
        ayahSegments: pageAyahSegments,
      ));
      pageNumber++;
    }
    
    return pages;
  }

  List<QuranPageData> _generateFlexibleQuranPages(SurahData surahData, double fontSize) {
    List<QuranPageData> pages = [];
    
    // Get screen dimensions
    final screenSize = MediaQuery.of(context).size;
    final double availableWidth = screenSize.width - 16; // 8px padding on each side
    final double availableHeight = screenSize.height - 120; // More space for header/footer
    
    // Calculate how many lines can fit with XL font
    final double lineHeight = fontSize * 1.6; // More generous spacing for XL
    final int maxLinesPerPage = (availableHeight / lineHeight).floor().clamp(8, 20); // Min 8, max 20 lines
    
    // Build continuous text with ayah tracking
    List<AyahSegment> allSegments = [];
    
    for (var ayah in surahData.ayahs) {
      String ayahText = '${ayah.text} ﴿${_convertToArabicNumeral(ayah.ayahIndex)}﴾';
      List<String> words = ayahText.split(' ').where((word) => word.trim().isNotEmpty).toList();
      
      for (String word in words) {
        allSegments.add(AyahSegment(
          text: word,
          surahIndex: surahData.index,
          ayahIndex: ayah.ayahIndex,
          ayahFullText: ayah.text,
        ));
      }
    }
    
    if (allSegments.isEmpty) return pages;
    
    // Calculate words per line dynamically based on screen width
    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.justify,
    );
    
    // Generate flexible pages
    int segmentIndex = 0;
    int pageNumber = 0;
    
    while (segmentIndex < allSegments.length) {
      List<String> pageLines = [];
      List<List<AyahSegment>> pageAyahSegments = [];
      int startingSegmentIndex = segmentIndex;
      
      // Add Surah header for first page
      if (pageNumber == 0) {
        pageLines.add('سُورَةُ ${surahData.name}');
        pageAyahSegments.add([]); // Empty segments for header
        
        // Add Bismillah (except for Surah At-Tawbah)
        if (widget.surahIndex != 9) {
          pageLines.add('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ');
          pageAyahSegments.add([]); // Empty segments for Bismillah
        }
      }
      
      // Fill remaining lines with content
      while (pageLines.length < maxLinesPerPage && segmentIndex < allSegments.length) {
        List<AyahSegment> lineSegments = [];
        double currentLineWidth = 0;
        
        // Add segments until we reach about 90% of line width
        while (segmentIndex < allSegments.length) {
          AyahSegment testSegment = allSegments[segmentIndex];
          
          // Create test line
          List<String> testWords = lineSegments.map((s) => s.text).toList();
          testWords.add(testSegment.text);
          String testLine = testWords.join(' ');
          
          // Measure the line with the new word
          textPainter.text = TextSpan(
            text: testLine,
            style: TextStyle(
              fontFamily: 'Al Qalam Quran Majeed',
              fontSize: fontSize,
              wordSpacing: wordSpacing,
            ),
          );
          textPainter.layout();
          currentLineWidth = textPainter.width;
          
          // Add segment if it fits
          if (currentLineWidth <= availableWidth) {
            lineSegments.add(testSegment);
            segmentIndex++;
            
            // Check for natural break points at 85% width
            if (currentLineWidth >= availableWidth * 0.85) {
              String currentWord = testSegment.text;
              
              if (currentWord.contains('﴾')) {
                break; // Ayah ending
              } else if (currentWord.contains('ۚ') || currentWord.contains('ۖ') || 
                         currentWord.contains('ۗ') || currentWord.contains('ۘ') ||
                         currentWord.contains('ۙ') || currentWord.contains('ۛ')) {
                if (currentLineWidth >= availableWidth * 0.9) {
                  break; // Waqf marks
                }
              }
            }
          } else {
            // Word doesn't fit
            if (lineSegments.length < 2) {
              // Force add if line has too few words
              lineSegments.add(testSegment);
              segmentIndex++;
            }
            break;
          }
        }
        
        // Ensure we have content on each line
        if (lineSegments.isEmpty && segmentIndex < allSegments.length) {
          lineSegments.add(allSegments[segmentIndex]);
          segmentIndex++;
        }
        
        if (lineSegments.isNotEmpty) {
          pageLines.add(lineSegments.map((s) => s.text).join(' '));
          pageAyahSegments.add(lineSegments);
        }
      }
      
      // Force at least one segment if we couldn't fit any
      if (segmentIndex == startingSegmentIndex && segmentIndex < allSegments.length) {
        if (pageLines.length < maxLinesPerPage) {
          pageLines.add(allSegments[segmentIndex].text);
          pageAyahSegments.add([allSegments[segmentIndex]]);
          segmentIndex++;
        }
      }
      
      // No need to pad to fixed number of lines for flexible layout
      pages.add(QuranPageData(
        lines: pageLines,
        ayahSegments: pageAyahSegments,
      ));
      pageNumber++;
    }
    
    return pages;
  }

  void _onAyahTap(int surahIndex, int ayahIndex, String ayahText) {
    // Highlight the ayah
    setState(() {
      highlightedAyah = '${surahIndex}_$ayahIndex';
    });
    
    // Cancel any existing timer
    highlightTimer?.cancel();
    
    // Show translation modal
    _showTranslationModal(surahIndex, ayahIndex, ayahText);
  }

  void _showTranslationModal(int surahIndex, int ayahIndex, String ayahText) {
    String? translation = translationsData[surahIndex]?[ayahIndex];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _buildTranslationModal(surahIndex, ayahIndex, ayahText, translation),
    ).then((_) {
      // Remove highlight after 1 second when modal is closed
      highlightTimer?.cancel();
      highlightTimer = Timer(const Duration(seconds: 1), () {
        setState(() {
          highlightedAyah = null;
        });
      });
    });
  }

  Widget _buildTranslationModal(int surahIndex, int ayahIndex, String ayahText, String? translation) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Container(
      margin: const EdgeInsets.all(16),
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.9, // Limit to 90% of screen height
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with ayah number
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'آیت ${_convertToArabicNumeral(ayahIndex)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                    fontFamily: 'Bahij Badr Bold',
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Arabic text
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      ayahText,
                      style: TextStyle(
                        fontFamily: 'Al Qalam Quran Majeed',
                        fontSize: 24, // Slightly reduced for better fit
                        color: isDark ? Colors.white : Colors.black,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                  
                  // Translation
                  if (translation != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          translation,
                          style: TextStyle(
                            fontFamily: 'Bahij Badr Light', // Keep Pashto font for translation
                            fontSize: 15, // Slightly reduced
                            color: isDark ? Colors.white70 : Colors.black87,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                    ),
                  
                  // Options sections
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Lughat Tashreeh section
                        _buildOptionSection(
                          title: 'د آیت د لغاتو تشریح:',
                          options: [
                            OptionData(
                              icon: Icons.text_fields_rounded, 
                              label: 'متن', 
                              type: 'lughat_text',
                              isAvailable: LughatService.hasTextData(surahIndex, ayahIndex),
                            ),
                            OptionData(
                              icon: Icons.play_circle_outline_rounded, 
                              label: 'غږ', 
                              type: 'lughat_audio',
                              isAvailable: LughatService.hasAudioData(surahIndex, ayahIndex),
                            ),
                            OptionData(
                              icon: Icons.videocam_outlined, 
                              label: 'ویډیو', 
                              type: 'lughat_video',
                              isAvailable: LughatService.hasVideoData(surahIndex, ayahIndex),
                            ),
                          ],
                          surahIndex: surahIndex,
                          ayahIndex: ayahIndex,
                          isDark: isDark,
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Tarjuma/Tafseer section
                        _buildOptionSection(
                          title: 'د آیت ترجمه او تفسیر:',
                          options: [
                            OptionData(
                              icon: Icons.text_fields_rounded, 
                              label: 'متن', 
                              type: 'tafseer_text',
                              isAvailable: false, // TODO: Add tafseer data
                            ),
                            OptionData(
                              icon: Icons.play_circle_outline_rounded, 
                              label: 'غږ', 
                              type: 'tafseer_audio',
                              isAvailable: false, // TODO: Add tafseer data
                            ),
                            OptionData(
                              icon: Icons.videocam_outlined, 
                              label: 'ویډیو', 
                              type: 'tafseer_video',
                              isAvailable: false, // TODO: Add tafseer data
                            ),
                          ],
                          surahIndex: surahIndex,
                          ayahIndex: ayahIndex,
                          isDark: isDark,
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Faidi section
                        _buildOptionSection(
                          title: 'د آیت فایدی:',
                          options: [
                            OptionData(
                              icon: Icons.text_fields_rounded, 
                              label: 'متن', 
                              type: 'faidi_text',
                              isAvailable: false, // TODO: Add faidi data
                            ),
                            OptionData(
                              icon: Icons.play_circle_outline_rounded, 
                              label: 'غږ', 
                              type: 'faidi_audio',
                              isAvailable: false, // TODO: Add faidi data
                            ),
                            OptionData(
                              icon: Icons.videocam_outlined, 
                              label: 'ویډیو', 
                              type: 'faidi_video',
                              isAvailable: false, // TODO: Add faidi data
                            ),
                          ],
                          surahIndex: surahIndex,
                          ayahIndex: ayahIndex,
                          isDark: isDark,
                        ),
                        
                        // Add some bottom padding for scroll
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionSection({
    required String title,
    required List<OptionData> options,
    required int surahIndex,
    required int ayahIndex,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface.withValues(alpha: 0.5) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGreen,
                fontFamily: 'Bahij Badr Bold',
              ),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
          ),
          
          // Options row
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: options.map((option) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _buildOptionButton(
                    icon: option.icon,
                    label: option.label,
                    onTap: option.isAvailable 
                        ? () => _handleOptionTap(option.type, surahIndex, ayahIndex)
                        : null,
                    isDark: isDark,
                    isAvailable: option.isAvailable,
                  ),
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _handleOptionTap(String type, int surahIndex, int ayahIndex) {
    // Handle different option types without closing the modal
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
        _showComingSoon('تفسیر - متن');
        break;
      case 'tafseer_audio':
        _showComingSoon('تفسیر - غږ');
        break;
      case 'tafseer_video':
        _showComingSoon('تفسیر - ویډیو');
        break;
      case 'faidi_text':
        _showComingSoon('فایدی - متن');
        break;
      case 'faidi_audio':
        _showComingSoon('فایدی - غږ');
        break;
      case 'faidi_video':
        _showComingSoon('فایدی - ویډیو');
        break;
    }
  }

  void _showLughatText(int surahIndex, int ayahIndex) {
    final textData = LughatService.getTextData(surahIndex, ayahIndex);
    if (textData != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FullScreenTextViewer(
            content: textData.content,
            title: 'د آیت ${_convertToArabicNumeral(ayahIndex)} د لغاتو تشریح',
          ),
        ),
      );
    } else {
      _showError('د دې آیت لپاره د لغاتو تشریح شتون نلري');
    }
  }

  void _showLughatAudio(int surahIndex, int ayahIndex) {
    final audioData = LughatService.getAudioData(surahIndex, ayahIndex);
    if (audioData != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FullScreenAudioPlayer(
            audioUrl: audioData.content,
            title: 'د آیت ${_convertToArabicNumeral(ayahIndex)} د لغاتو تشریح',
            surahIndex: surahIndex,
            ayahIndex: ayahIndex,
          ),
        ),
      );
    } else {
      _showError('د دې آیت لپاره د لغاتو تشریح غږ شتون نلري');
    }
  }

  void _showLughatVideo(int surahIndex, int ayahIndex) {
    final videoData = LughatService.getVideoData(surahIndex, ayahIndex);
    if (videoData != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FullScreenVideoPlayer(
            videoUrl: videoData.content,
            title: 'د آیت ${_convertToArabicNumeral(ayahIndex)} د لغاتو تشریح',
            surahIndex: surahIndex,
            ayahIndex: ayahIndex,
          ),
        ),
      );
    } else {
      _showError('د دې آیت لپاره د لغاتو تشریح ویډیو شتون نلري');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Bahij Badr Light'),
          textDirection: TextDirection.rtl,
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$feature - ژر راځي',
          style: const TextStyle(fontFamily: 'Bahij Badr Light'),
          textDirection: TextDirection.rtl,
        ),
        backgroundColor: AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showFontSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _buildFontSettingsModal(),
    );
  }

  Widget _buildFontSettingsModal() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.all(16),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
        minWidth: 0,
        maxWidth: double.infinity,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'د عربي متن فونټ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                    fontFamily: 'Bahij Badr Bold',
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          
          // Font options
          Expanded(
            child: Consumer<FontProvider>(
              builder: (context, fontProvider, child) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Font size section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkSurface.withValues(alpha: 0.5) : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'د متن اندازه',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                                fontFamily: 'Bahij Badr Bold',
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                            const SizedBox(height: 12),
                            
                            // Font size preview
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? AppTheme.darkSurface.withValues(alpha: 0.7) : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade300,
                                ),
                              ),
                              child: Text(
                                'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                                style: TextStyle(
                                  fontFamily: fontProvider.selectedArabicFont,
                                  fontSize: fontProvider.arabicFontSize,
                                  color: isDark ? Colors.white : Colors.black,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                                textDirection: TextDirection.rtl,
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // Font size options
                            ...FontSize.values.map((fontSize) {
                              final isSelected = fontProvider.selectedFontSize == fontSize;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: InkWell(
                                  onTap: () {
                                    fontProvider.setArabicFontSize(fontSize);
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: isSelected 
                                          ? AppTheme.primaryGreen.withValues(alpha: 0.1)
                                          : (isDark ? AppTheme.darkSurface.withValues(alpha: 0.7) : Colors.white),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSelected 
                                            ? AppTheme.primaryGreen
                                            : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade300),
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        if (isSelected)
                                          Icon(
                                            Icons.check_circle_rounded,
                                            color: AppTheme.primaryGreen,
                                            size: 18,
                                          ),
                                        if (isSelected) const SizedBox(width: 8),
                                        Text(
                                          fontSize.displayName,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected 
                                                ? AppTheme.primaryGreen
                                                : (isDark ? Colors.white : Colors.black),
                                            fontFamily: 'Bahij Badr Bold',
                                          ),
                                          textDirection: TextDirection.rtl,
                                        ),
                                        const Spacer(),
                                        Text(
                                          '${fontSize.size.round()}px',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? Colors.white70 : Colors.black54,
                                            fontFamily: 'Bahij Badr Light',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Font family section
                      Text(
                        'د فونټ ډول',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                          fontFamily: 'Bahij Badr Bold',
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 12),
                      
                      // Font family options
                      ...List.generate(fontProvider.availableFonts.length, (index) {
                    final fontOption = fontProvider.availableFonts[index];
                    final isSelected = fontProvider.selectedArabicFont == fontOption.family;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () {
                          fontProvider.setArabicFont(fontOption.family);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? AppTheme.primaryGreen.withValues(alpha: 0.1)
                                : (isDark ? AppTheme.darkSurface.withValues(alpha: 0.5) : Colors.grey.shade50),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected 
                                  ? AppTheme.primaryGreen
                                  : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Font name
                              Row(
                                children: [
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: AppTheme.primaryGreen,
                                      size: 20,
                                    ),
                                  if (isSelected) const SizedBox(width: 8),
                                  Text(
                                    fontOption.displayName,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected 
                                          ? AppTheme.primaryGreen
                                          : (isDark ? Colors.white : Colors.black),
                                      fontFamily: 'Bahij Badr Bold',
                                    ),
                                    textDirection: TextDirection.rtl,
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // Sample text
                              Text(
                                'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                                style: TextStyle(
                                  fontFamily: fontOption.family,
                                  fontSize: 20,
                                  color: isDark ? Colors.white : Colors.black,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                                textDirection: TextDirection.rtl,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    required bool isDark,
    required bool isAvailable,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isAvailable 
              ? (isDark ? AppTheme.darkSurface.withValues(alpha: 0.7) : Colors.white)
              : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isAvailable 
                ? (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade300)
                : (isDark ? Colors.grey.shade700 : Colors.grey.shade400),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isAvailable ? AppTheme.primaryGreen : Colors.grey,
              size: 18,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isAvailable 
                    ? (isDark ? Colors.white70 : Colors.black87)
                    : Colors.grey,
                fontFamily: 'Bahij Badr Light',
              ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
          ],
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
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                ),
              )
            : Consumer<FontProvider>(
                builder: (context, fontProvider, child) {
                  return Stack(
                    children: [
                      // Main content - Full screen Quran pages
                      PageView.builder(
                        controller: _pageController,
                        itemCount: pages.length,
                        onPageChanged: (index) {
                          setState(() {
                            currentPage = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          return _buildQuranPage(pages[index], isDark, fontProvider.selectedArabicFont, fontProvider.arabicFontSize);
                        },
                      ),
                  
                  // Minimal header overlay with fade effect
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
                            
                            // Page indicator
                            Text(
                              _convertToArabicNumeral(currentPage + 1),
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white60 : Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            
                            // Settings button
                            IconButton(
                              onPressed: () => _showFontSettings(context),
                              icon: Icon(
                                Icons.settings_rounded,
                                color: isDark ? Colors.white60 : Colors.black54,
                                size: 18,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildQuranPage(QuranPage page, bool isDark, String selectedFont, double fontSize) {
    final screenHeight = MediaQuery.of(context).size.height;
    final availableHeight = screenHeight - 80;
    
    // Check if we're using flexible layout (XL font)
    final fontProvider = Provider.of<FontProvider>(context, listen: false);
    final isFlexibleLayout = fontProvider.selectedFontSize.needsFlexibleLayout;
    
    if (isFlexibleLayout) {
      // For XL font, use scrollable layout
      final lineHeight = fontSize * 1.6;
      
      return Container(
        padding: const EdgeInsets.only(
          left: 8,
          right: 8,
          top: 45,
          bottom: 5,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(page.lines.length, (index) {
              String line = page.lines[index];
              List<AyahSegment> lineSegments = index < page.ayahSegments.length ? page.ayahSegments[index] : [];
              bool isHeader = page.isFirstPage && index < 2 && line.isNotEmpty;
              bool isBismillah = line.contains('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ');
              bool isSurahHeader = line.startsWith('سُورَةُ');
              
              return Container(
                width: double.infinity,
                constraints: BoxConstraints(minHeight: lineHeight),
                alignment: isHeader ? Alignment.center : Alignment.centerRight,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: line.isEmpty ? const SizedBox() : (isHeader ? Text(
                  line,
                  style: TextStyle(
                    fontFamily: isSurahHeader ? 'Bahij Badr Bold' : selectedFont,
                    fontSize: isHeader ? (isBismillah ? fontSize * 0.9 : fontSize * 0.75) : fontSize,
                    color: isSurahHeader ? AppTheme.primaryGreen : (isDark ? Colors.white : Colors.black),
                    height: 1.4,
                    fontWeight: isSurahHeader ? FontWeight.bold : FontWeight.normal,
                    wordSpacing: 0,
                    letterSpacing: 0,
                  ),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                ) : _buildClickableLine(line, lineSegments, isDark, selectedFont, fontSize)),
              );
            }),
          ),
        ),
      );
    } else {
      // For standard fonts, use fixed layout
      final calculatedLineHeight = availableHeight / linesPerPage;
      
      return Container(
        padding: const EdgeInsets.only(
          left: 8,
          right: 8,
          top: 45,
          bottom: 5,
        ),
        child: SizedBox(
          height: availableHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: List.generate(linesPerPage, (index) {
              String line = index < page.lines.length ? page.lines[index] : '';
              List<AyahSegment> lineSegments = index < page.ayahSegments.length ? page.ayahSegments[index] : [];
              bool isHeader = page.isFirstPage && index < 2 && line.isNotEmpty;
              bool isBismillah = line.contains('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ');
              bool isSurahHeader = line.startsWith('سُورَةُ');
              
              return Container(
                height: calculatedLineHeight,
                alignment: Alignment.center,
                padding: EdgeInsets.zero,
                child: line.isEmpty ? const SizedBox() : Container(
                  width: double.infinity,
                  alignment: isHeader ? Alignment.center : Alignment.centerRight,
                  child: isHeader ? Text(
                    line,
                    style: TextStyle(
                      fontFamily: isSurahHeader ? 'Bahij Badr Bold' : selectedFont,
                      fontSize: isHeader ? (isBismillah ? 22 : 18) : fontSize,
                      color: isSurahHeader ? AppTheme.primaryGreen : (isDark ? Colors.white : Colors.black),
                      height: 1.0,
                      fontWeight: isSurahHeader ? FontWeight.bold : FontWeight.normal,
                      wordSpacing: 0,
                      letterSpacing: 0,
                    ),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                  ) : _buildClickableLine(line, lineSegments, isDark, selectedFont, fontSize),
                ),
              );
            }),
          ),
        ),
      );
    }
  }

  Widget _buildClickableLine(String line, List<AyahSegment> lineSegments, bool isDark, String selectedFont, double fontSize) {
    if (lineSegments.isEmpty) {
      return _buildJustifiedLine(line, isDark, selectedFont, fontSize);
    }
    
    return SizedBox(
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          List<String> words = line.split(' ').where((word) => word.trim().isNotEmpty).toList();
          
          if (words.isEmpty) return const SizedBox();
          
          // Check if this is a verse ending line (contains ayah number)
          bool isVerseEnding = line.contains('﴾');
          
          // For single word, very short lines, or verse endings, align right
          if (words.length <= 2 || (isVerseEnding && words.length <= 4)) {
            return Container(
              width: double.infinity,
              alignment: Alignment.centerRight,
              child: _buildClickableTextWithAyahHighlight(lineSegments, isDark, TextAlign.right, selectedFont, fontSize),
            );
          }
          
          // Calculate total width of all words without spacing
          double totalWordsWidth = 0;
          final textPainter = TextPainter(textDirection: TextDirection.rtl);
          List<double> wordWidths = [];
          
          for (String word in words) {
            textPainter.text = TextSpan(
              text: word,
              style: TextStyle(
                fontFamily: selectedFont,
                fontSize: fontSize,
                letterSpacing: 0,
              ),
            );
            textPainter.layout();
            wordWidths.add(textPainter.width);
            totalWordsWidth += textPainter.width;
          }
          
          // Calculate required spacing between words
          double availableWidth = constraints.maxWidth;
          double totalSpacingNeeded = availableWidth - totalWordsWidth;
          
          // If spacing would be too large or negative, use right alignment instead
          if (totalSpacingNeeded <= 0 || totalSpacingNeeded / (words.length - 1) > 50) {
            return Container(
              width: double.infinity,
              alignment: Alignment.centerRight,
              child: Text(
                line,
                style: TextStyle(
                  fontFamily: selectedFont,
                  fontSize: fontSize,
                  color: isDark ? Colors.white : Colors.black,
                  height: 1.0,
                  wordSpacing: 3.0, // Use standard word spacing
                  letterSpacing: 0,
                ),
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
              ),
            );
          }
          
          double spacePerGap = totalSpacingNeeded / (words.length - 1);
          
          // Additional safety check for negative spacing
          if (spacePerGap < 0) {
            return Container(
              width: double.infinity,
              alignment: Alignment.centerRight,
              child: Text(
                line,
                style: TextStyle(
                  fontFamily: selectedFont,
                  fontSize: fontSize,
                  color: isDark ? Colors.white : Colors.black,
                  height: 1.0,
                  wordSpacing: 3.0,
                  letterSpacing: 0,
                ),
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
              ),
            );
          }
          
          // Build the justified line with ayah-level highlighting
          return SizedBox(
            width: double.infinity,
            child: _buildJustifiedLineWithAyahHighlight(lineSegments, spacePerGap, isDark, selectedFont, fontSize),
          );
        },
      ),
    );
  }

  Widget _buildJustifiedLineWithAyahHighlight(List<AyahSegment> segments, double spacePerGap, bool isDark, String selectedFont, double fontSize) {
    // Group segments by ayah
    Map<String, List<AyahSegment>> ayahGroups = {};
    for (var segment in segments) {
      String ayahKey = '${segment.surahIndex}_${segment.ayahIndex}';
      ayahGroups[ayahKey] = ayahGroups[ayahKey] ?? [];
      ayahGroups[ayahKey]!.add(segment);
    }
    
    List<Widget> widgets = [];
    int segmentIndex = 0;
    
    for (var ayahKey in ayahGroups.keys) {
      List<AyahSegment> ayahSegments = ayahGroups[ayahKey]!;
      bool isHighlighted = highlightedAyah == ayahKey;
      
      // Create a container for the entire ayah
      Widget ayahWidget = GestureDetector(
        onTap: () => _onAyahTap(ayahSegments.first.surahIndex, ayahSegments.first.ayahIndex, ayahSegments.first.ayahFullText),
        child: Container(
          decoration: isHighlighted ? BoxDecoration(
            color: AppTheme.primaryGreen.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ) : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.rtl,
            children: List.generate(ayahSegments.length * 2 - 1, (index) {
              if (index.isEven) {
                // Word
                int wordIndex = index ~/ 2;
                return Text(
                  ayahSegments[wordIndex].text,
                  style: TextStyle(
                    fontFamily: selectedFont,
                    fontSize: fontSize,
                    color: isDark ? Colors.white : Colors.black,
                    height: 1.0,
                    letterSpacing: 0,
                  ),
                  textDirection: TextDirection.rtl,
                );
              } else {
                // Space between words within the same ayah
                return SizedBox(width: spacePerGap);
              }
            }),
          ),
        ),
      );
      
      widgets.add(ayahWidget);
      
      // Add spacing between different ayahs (except for the last ayah)
      segmentIndex += ayahSegments.length;
      if (segmentIndex < segments.length) {
        widgets.add(SizedBox(width: spacePerGap));
      }
    }
    
    return Row(
      textDirection: TextDirection.rtl,
      mainAxisAlignment: MainAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildClickableTextWithAyahHighlight(List<AyahSegment> segments, bool isDark, TextAlign textAlign, String selectedFont, double fontSize) {
    // Group segments by ayah
    Map<String, List<AyahSegment>> ayahGroups = {};
    for (var segment in segments) {
      String ayahKey = '${segment.surahIndex}_${segment.ayahIndex}';
      ayahGroups[ayahKey] = ayahGroups[ayahKey] ?? [];
      ayahGroups[ayahKey]!.add(segment);
    }
    
    return Wrap(
      textDirection: TextDirection.rtl,
      alignment: textAlign == TextAlign.right ? WrapAlignment.end : WrapAlignment.start,
      children: ayahGroups.entries.map((entry) {
        String ayahKey = entry.key;
        List<AyahSegment> ayahSegments = entry.value;
        bool isHighlighted = highlightedAyah == ayahKey;
        
        return GestureDetector(
          onTap: () => _onAyahTap(ayahSegments.first.surahIndex, ayahSegments.first.ayahIndex, ayahSegments.first.ayahFullText),
          child: Container(
            decoration: isHighlighted ? BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ) : null,
            child: Text(
              '${ayahSegments.map((s) => s.text).join(' ')} ',
              style: TextStyle(
                fontFamily: selectedFont,
                fontSize: fontSize,
                color: isDark ? Colors.white : Colors.black,
                height: 1.0,
                wordSpacing: 3.0,
                letterSpacing: 0,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildJustifiedLine(String line, bool isDark, String selectedFont, double fontSize) {
    return LayoutBuilder(
      builder: (context, constraints) {
        List<String> words = line.split(' ').where((word) => word.trim().isNotEmpty).toList();
        
        if (words.isEmpty) return const SizedBox();
        
        // Check if this is a verse ending line (contains ayah number)
        bool isVerseEnding = line.contains('﴾');
        
        // For single word, very short lines, or verse endings, align right
        if (words.length <= 2 || (isVerseEnding && words.length <= 4)) {
          return Container(
            width: double.infinity,
            alignment: Alignment.centerRight,
            child: Text(
              line,
              style: TextStyle(
                fontFamily: selectedFont,
                fontSize: fontSize,
                color: isDark ? Colors.white : Colors.black,
                height: 1.0,
                wordSpacing: 3.0,
                letterSpacing: 0,
              ),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
          );
        }
        
        // Calculate total width of all words without spacing
        double totalWordsWidth = 0;
        final textPainter = TextPainter(textDirection: TextDirection.rtl);
        List<double> wordWidths = [];
        
        for (String word in words) {
          textPainter.text = TextSpan(
            text: word,
            style: TextStyle(
              fontFamily: selectedFont,
              fontSize: fontSize,
              letterSpacing: 0,
            ),
          );
          textPainter.layout();
          wordWidths.add(textPainter.width);
          totalWordsWidth += textPainter.width;
        }
        
        // Calculate required spacing between words
        double availableWidth = constraints.maxWidth;
        double totalSpacingNeeded = availableWidth - totalWordsWidth;
        
        // If spacing would be too large or negative, use right alignment instead
        if (totalSpacingNeeded <= 0 || totalSpacingNeeded / (words.length - 1) > 50) {
          return Container(
            width: double.infinity,
            alignment: Alignment.centerRight,
            child: Text(
              line,
              style: TextStyle(
                fontFamily: selectedFont,
                fontSize: fontSize,
                color: isDark ? Colors.white : Colors.black,
                height: 1.0,
                wordSpacing: 3.0, // Use standard word spacing
                letterSpacing: 0,
              ),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
          );
        }
        
        double spacePerGap = totalSpacingNeeded / (words.length - 1);
        
        // Additional safety check for negative spacing
        if (spacePerGap < 0) {
          return Container(
            width: double.infinity,
            alignment: Alignment.centerRight,
            child: Text(
              line,
              style: TextStyle(
                fontFamily: selectedFont,
                fontSize: fontSize,
                color: isDark ? Colors.white : Colors.black,
                height: 1.0,
                wordSpacing: 3.0,
                letterSpacing: 0,
              ),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
          );
        }
        
        // Build the justified line with precise spacing
        return SizedBox(
          width: double.infinity,
          child: Row(
            textDirection: TextDirection.rtl,
            mainAxisAlignment: MainAxisAlignment.start,
            children: List.generate(words.length * 2 - 1, (index) {
              if (index.isEven) {
                // Word
                int wordIndex = index ~/ 2;
                return Text(
                  words[wordIndex],
                  style: TextStyle(
                    fontFamily: selectedFont,
                    fontSize: fontSize,
                    color: isDark ? Colors.white : Colors.black,
                    height: 1.0,
                    letterSpacing: 0,
                  ),
                  textDirection: TextDirection.rtl,
                );
              } else {
                // Space between words
                return SizedBox(width: spacePerGap);
              }
            }),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pageController.dispose();
    highlightTimer?.cancel();
    
    // Remove font change listener
    try {
      Provider.of<FontProvider>(context, listen: false).removeListener(_onFontChanged);
    } catch (e) {
      // Ignore if provider is already disposed
    }
    
    super.dispose();
  }
}

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

class QuranPage {
  final int pageNumber;
  final List<String> lines;
  final String surahName;
  final bool isFirstPage;
  final List<List<AyahSegment>> ayahSegments;

  QuranPage({
    required this.pageNumber,
    required this.lines,
    required this.surahName,
    required this.isFirstPage,
    required this.ayahSegments,
  });
}

class QuranPageData {
  final List<String> lines;
  final List<List<AyahSegment>> ayahSegments;

  QuranPageData({
    required this.lines,
    required this.ayahSegments,
  });
}

class AyahSegment {
  final String text;
  final int surahIndex;
  final int ayahIndex;
  final String ayahFullText;

  AyahSegment({
    required this.text,
    required this.surahIndex,
    required this.ayahIndex,
    required this.ayahFullText,
  });
}

class OptionData {
  final IconData icon;
  final String label;
  final String type;
  final bool isAvailable;

  OptionData({
    required this.icon,
    required this.label,
    required this.type,
    this.isAvailable = true,
  });
}
