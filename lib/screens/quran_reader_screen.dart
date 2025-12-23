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
import '../widgets/media_viewers.dart';
import '../providers/font_provider.dart';
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

  const QuranReaderScreen({
    super.key,
    this.surahIndex = 0,
    this.surahName = '',
    this.paraIndex,
    this.paraName,
    this.initialAyahIndex,
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
  Map<int, ParaData> parasData = {}; // paraIndex -> ParaData with start/end positions
  
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
      
      // Parse para markers and associated surahs/ayahs
      _parseParaData(arabicDocument);
      
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

  void _parseParaData(XmlDocument document) {
    // Parse all para tags and find which surahs/ayahs they start with
    var allElements = document.findAllElements('*').toList();
    
    for (int i = 0; i < allElements.length; i++) {
      var element = allElements[i];
      
      if (element.name.local == 'para') {
        int paraIndex = int.parse(element.getAttribute('index')!);
        
        // Find the next aya after this para tag (might be in same or different sura)
        int? startSurahIndex;
        int? startAyahIndex;
        int? currentSurahIndex;
        
        // Look backwards to find current sura if para is within a sura
        for (int j = i - 1; j >= 0; j--) {
          var prevElement = allElements[j];
          if (prevElement.name.local == 'sura') {
            currentSurahIndex = int.parse(prevElement.getAttribute('index')!);
            break;
          }
        }
        
        // Look forward for the next aya
        for (int j = i + 1; j < allElements.length; j++) {
          var nextElement = allElements[j];
          
          if (nextElement.name.local == 'sura') {
            currentSurahIndex = int.parse(nextElement.getAttribute('index')!);
          } else if (nextElement.name.local == 'aya') {
            startAyahIndex = int.parse(nextElement.getAttribute('index')!);
            startSurahIndex = currentSurahIndex;
            break;
          }
        }
        
        if (startSurahIndex != null && startAyahIndex != null) {
          parasData[paraIndex] = ParaData(
            index: paraIndex,
            startSurahIndex: startSurahIndex,
            startAyahIndex: startAyahIndex,
          );
          
          debugPrint('Para $paraIndex starts at Surah $startSurahIndex, Ayah $startAyahIndex');
        }
      }
    }
  }

  void _generateQuranPages() {
    pages.clear();
    
    // Handle both Surah and Para navigation
    if (widget.paraIndex != null && parasData.containsKey(widget.paraIndex)) {
      // Para navigation - generate pages starting from para location
      _generateParaPages();
      return;
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
    
    // Navigate to specific ayah if requested
    if (widget.initialAyahIndex != null) {
      _navigateToInitialAyah();
    }
  }

  void _generateParaPages() {
    if (widget.paraIndex == null || !parasData.containsKey(widget.paraIndex!)) {
      setState(() {
        isLoading = false;
      });
      return;
    }
    
    ParaData paraData = parasData[widget.paraIndex!]!;
    
    // Get current font size to determine layout type
    FontSize currentFontSize = Provider.of<FontProvider>(context, listen: false).selectedFontSize;
    
    // Generate all ayahs starting from para location until the next para or end
    List<AyahSegment> allSegments = [];
    
    // Determine end point (next para or end of Quran)
    int? endSurahIndex;
    int? endAyahIndex;
    
    if (widget.paraIndex! < 30) {
      // Find next para
      ParaData? nextPara = parasData[widget.paraIndex! + 1];
      if (nextPara != null) {
        endSurahIndex = nextPara.startSurahIndex;
        endAyahIndex = nextPara.startAyahIndex - 1;
        
        // If next para starts at ayah 1, we need the last ayah of previous surah
        if (endAyahIndex! < 1) {
          endSurahIndex = endSurahIndex - 1;
          if (surahsData.containsKey(endSurahIndex)) {
            endAyahIndex = surahsData[endSurahIndex]!.ayahs.length;
          }
        }
      }
    }
    
    // If no end point found, go to end of Quran
    if (endSurahIndex == null) {
      endSurahIndex = 114;
      if (surahsData.containsKey(114)) {
        endAyahIndex = surahsData[114]!.ayahs.length;
      }
    }
    
    // Collect all ayahs from start to end
    bool collecting = false;
    int? lastCollectedSurah = null;
    
    debugPrint('Para ${widget.paraIndex} collection: start at S${paraData.startSurahIndex}:A${paraData.startAyahIndex}, end at S${endSurahIndex}:A${endAyahIndex}');
    
    for (int surahIdx = paraData.startSurahIndex; surahIdx <= endSurahIndex!; surahIdx++) {
      if (!surahsData.containsKey(surahIdx)) continue;
      
      SurahData surahData = surahsData[surahIdx]!;
      
      for (var ayah in surahData.ayahs) {
        // Start collecting from para start point
        if (surahIdx == paraData.startSurahIndex && ayah.ayahIndex == paraData.startAyahIndex) {
          collecting = true;
          debugPrint('Started collecting at Surah ${surahIdx}, Ayah ${ayah.ayahIndex}');
        }
        
        // Stop collecting at end point
        if (surahIdx == endSurahIndex && ayah.ayahIndex > endAyahIndex!) {
          break;
        }
        
        if (collecting) {
          // Debug: Track surah transitions
          if (lastCollectedSurah != null && lastCollectedSurah != surahIdx) {
            debugPrint('=== SURAH TRANSITION: From Surah $lastCollectedSurah to Surah $surahIdx at Ayah ${ayah.ayahIndex} ===');
          }
          lastCollectedSurah = surahIdx;
          
          String ayahText = '${ayah.text} ﴿${_convertToArabicNumeral(ayah.ayahIndex)}﴾';
          List<String> words = ayahText.split(' ').where((word) => word.trim().isNotEmpty).toList();
          
          // Debug first few words of ayah 1
          if (ayah.ayahIndex == 1) {
            debugPrint('Collecting Ayah 1 of Surah $surahIdx (${surahData.name}): First words: ${words.take(3).join(' ')}');
          }
          
          for (String word in words) {
            allSegments.add(AyahSegment(
              text: word,
              surahIndex: surahData.index,
              ayahIndex: ayah.ayahIndex,
              ayahFullText: ayah.text,
            ));
          }
        }
      }
    }
    
    debugPrint('Total segments collected: ${allSegments.length}');
    
    // Debug: Print surah transitions in collected segments
    int? prevSurah = null;
    for (int i = 0; i < allSegments.length; i++) {
      if (allSegments[i].surahIndex != prevSurah) {
        if (prevSurah != null) {
          debugPrint('Segment $i: Surah transition from $prevSurah to ${allSegments[i].surahIndex}, Ayah ${allSegments[i].ayahIndex}');
        }
        prevSurah = allSegments[i].surahIndex;
      }
    }
    
    if (allSegments.isEmpty) {
      setState(() {
        isLoading = false;
      });
      return;
    }
    
    // Generate pages using the same logic as surah pages
    // Format para title with separator
    String formattedTitle = 'پارہ ◆ ${widget.paraName ?? ''}';
    
    List<QuranPageData> pageDataList;
    if (currentFontSize.needsFlexibleLayout) {
      pageDataList = _generateFlexibleQuranPagesFromSegments(allSegments, currentFontSize.size, formattedTitle, true);
    } else {
      pageDataList = _generateStandardQuranPagesFromSegments(allSegments, formattedTitle, true);
    }
    
    for (int i = 0; i < pageDataList.length; i++) {
      pages.add(QuranPage(
        pageNumber: i + 1,
        lines: pageDataList[i].lines,
        surahName: formattedTitle,
        isFirstPage: i == 0,
        ayahSegments: pageDataList[i].ayahSegments,
      ));
    }
    
    setState(() {
      isLoading = false;
    });
  }
  
  void _navigateToInitialAyah() {
    if (widget.initialAyahIndex == null || pages.isEmpty) return;
    
    // Find the page containing the requested ayah
    for (int pageIndex = 0; pageIndex < pages.length; pageIndex++) {
      final page = pages[pageIndex];
      
      // Check if this page contains the requested ayah
      for (var lineSegments in page.ayahSegments) {
        for (var segment in lineSegments) {
          if (segment.ayahIndex == widget.initialAyahIndex) {
            // Found the page, navigate to it
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _pageController.jumpToPage(pageIndex);
              // Highlight the ayah
              setState(() {
                highlightedAyah = '${widget.surahIndex}_${widget.initialAyahIndex}';
              });
              
              // Keep the ayah highlighted longer when navigating to it
              highlightTimer?.cancel();
              highlightTimer = Timer(const Duration(seconds: 10), () {
                if (mounted) {
                  setState(() {
                    highlightedAyah = null;
                  });
                }
              });
              
              // Update reading progress and show translation modal after navigation
              Future.delayed(const Duration(milliseconds: 500), () {
                _updateReadingProgress(widget.surahIndex, widget.initialAyahIndex!);
                final ayahText = _getAyahText(widget.surahIndex, widget.initialAyahIndex!);
                _showTranslationModal(widget.surahIndex, widget.initialAyahIndex!, ayahText);
              });
            });
            return;
          }
        }
      }
    }
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

  List<QuranPageData> _generateStandardQuranPagesFromSegments(List<AyahSegment> allSegments, String title, [bool isPara = false]) {
    List<QuranPageData> pages = [];
    
    if (allSegments.isEmpty) return pages;
    
    // Get screen dimensions
    final screenSize = MediaQuery.of(context).size;
    final double availableWidth = screenSize.width - 16; // 8px padding on each side
    
    // Calculate words per line dynamically based on screen width
    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.justify,
    );
    
    // Track which surahs have been processed (headers shown)
    Set<int> processedSurahs = {};
    
    // Generate pages with exactly 15 lines each
    int segmentIndex = 0;
    int pageNumber = 0;
    
    while (segmentIndex < allSegments.length) {
      List<String> pageLines = [];
      List<List<AyahSegment>> pageAyahSegments = [];
      int startingSegmentIndex = segmentIndex;
      
      // Add title header for first page
      if (pageNumber == 0) {
        pageLines.add(title);
        pageAyahSegments.add([]); // Empty segments for header
      }
      
      // Fill remaining lines with content
      while (pageLines.length < linesPerPage && segmentIndex < allSegments.length) {
        // For para mode, check if we need to add surah headers
        if (isPara && segmentIndex < allSegments.length) {
          // Look ahead to find the start of a new ayah
          AyahSegment currentSegment = allSegments[segmentIndex];
          
          // Check if this is the first segment of ayah 1 of a new surah
          bool isFirstSegmentOfAyah1 = false;
          if (currentSegment.ayahIndex == 1 && !processedSurahs.contains(currentSegment.surahIndex)) {
            // Check if this is the first segment for this ayah by looking back
            if (segmentIndex == 0) {
              isFirstSegmentOfAyah1 = true;
            } else {
              AyahSegment prevSegment = allSegments[segmentIndex - 1];
              // It's the first segment if previous segment was from different surah or different ayah
              isFirstSegmentOfAyah1 = prevSegment.surahIndex != currentSegment.surahIndex || 
                                     prevSegment.ayahIndex != currentSegment.ayahIndex;
            }
          }
          
          if (isFirstSegmentOfAyah1) {
            debugPrint('>>> NEW SURAH DETECTED: Surah ${currentSegment.surahIndex} at segment $segmentIndex');
            
            // Add surah header
            if (pageLines.length < linesPerPage && surahsData.containsKey(currentSegment.surahIndex)) {
              String surahName = surahsData[currentSegment.surahIndex]!.name;
              pageLines.add('سُورَةُ $surahName');
              pageAyahSegments.add([]); // Empty segments for surah header
              debugPrint('Added Surah header: سُورَةُ $surahName');
            }
            
            // Add Bismillah (except for Surah 9)
            if (currentSegment.surahIndex != 9 && pageLines.length < linesPerPage) {
              pageLines.add('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ');
              pageAyahSegments.add([]); // Empty segments for Bismillah
              debugPrint('Added Bismillah');
            }
            
            // Mark this surah as processed
            processedSurahs.add(currentSegment.surahIndex);
          }
        }
        
        // Skip line building if we've filled the page with headers
        if (pageLines.length >= linesPerPage) {
          break;
        }
        
        List<AyahSegment> lineSegments = [];
        double currentLineWidth = 0;
        
        // Build line with segments
        while (segmentIndex < allSegments.length) {
          AyahSegment testSegment = allSegments[segmentIndex];
          
          // Create test line
          List<String> testWords = lineSegments.map((s) => s.text).toList();
          testWords.add(testSegment.text);
          String testLine = testWords.join(' ');
          
          // Measure the line with the new word using actual font settings
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

  List<QuranPageData> _generateFlexibleQuranPagesFromSegments(List<AyahSegment> allSegments, double fontSize, String title, [bool isPara = false]) {
    List<QuranPageData> pages = [];
    
    if (allSegments.isEmpty) return pages;
    
    // Get screen dimensions
    final screenSize = MediaQuery.of(context).size;
    final double availableWidth = screenSize.width - 16; // 8px padding on each side
    final double availableHeight = screenSize.height - 120; // More space for header/footer
    
    // Calculate how many lines can fit with XL font
    final double lineHeight = fontSize * 1.6; // More generous spacing for XL
    final int maxLinesPerPage = (availableHeight / lineHeight).floor().clamp(8, 20); // Min 8, max 20 lines
    
    // Calculate words per line dynamically based on screen width
    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.justify,
    );
    
    // Track which surahs have been processed (headers shown)
    Set<int> processedSurahs = {};
    
    // Generate flexible pages
    int segmentIndex = 0;
    int pageNumber = 0;
    
    while (segmentIndex < allSegments.length) {
      List<String> pageLines = [];
      List<List<AyahSegment>> pageAyahSegments = [];
      int startingSegmentIndex = segmentIndex;
      
      // Add title header for first page
      if (pageNumber == 0) {
        pageLines.add(title);
        pageAyahSegments.add([]); // Empty segments for header
      }
      
      // Fill remaining lines with content
      while (pageLines.length < maxLinesPerPage && segmentIndex < allSegments.length) {
        // For para mode, check if we need to add surah headers
        if (isPara && segmentIndex < allSegments.length) {
          // Look ahead to find the start of a new ayah
          AyahSegment currentSegment = allSegments[segmentIndex];
          
          // Check if this is the first segment of ayah 1 of a new surah
          bool isFirstSegmentOfAyah1 = false;
          if (currentSegment.ayahIndex == 1 && !processedSurahs.contains(currentSegment.surahIndex)) {
            // Check if this is the first segment for this ayah by looking back
            if (segmentIndex == 0) {
              isFirstSegmentOfAyah1 = true;
            } else {
              AyahSegment prevSegment = allSegments[segmentIndex - 1];
              // It's the first segment if previous segment was from different surah or different ayah
              isFirstSegmentOfAyah1 = prevSegment.surahIndex != currentSegment.surahIndex || 
                                     prevSegment.ayahIndex != currentSegment.ayahIndex;
            }
          }
          
          if (isFirstSegmentOfAyah1) {
            debugPrint('>>> NEW SURAH DETECTED (Flexible): Surah ${currentSegment.surahIndex} at segment $segmentIndex');
            
            // Add surah header
            if (pageLines.length < maxLinesPerPage && surahsData.containsKey(currentSegment.surahIndex)) {
              String surahName = surahsData[currentSegment.surahIndex]!.name;
              pageLines.add('سُورَةُ $surahName');
              pageAyahSegments.add([]); // Empty segments for surah header
              debugPrint('Added Surah header: سُورَةُ $surahName');
            }
            
            // Add Bismillah (except for Surah 9)
            if (currentSegment.surahIndex != 9 && pageLines.length < maxLinesPerPage) {
              pageLines.add('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ');
              pageAyahSegments.add([]); // Empty segments for Bismillah
              debugPrint('Added Bismillah');
            }
            
            // Mark this surah as processed
            processedSurahs.add(currentSegment.surahIndex);
          }
        }
        
        // Skip line building if we've filled the page with headers
        if (pageLines.length >= maxLinesPerPage) {
          break;
        }
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
              fontFamily: 'Al Qalam Quran Majeed', // Keep default for measurement
              fontSize: fontSize,
              wordSpacing: wordSpacing,
            ),
          );
          textPainter.layout();
          currentLineWidth = textPainter.width;
          
          // Check if adding this segment would exceed line width
          if (currentLineWidth <= availableWidth * 0.9 || lineSegments.isEmpty) {
            lineSegments.add(testSegment);
            segmentIndex++;
          } else {
            break;
          }
        }
        
        // Ensure we have at least some content on each line
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
    
    // Update reading progress
    _updateReadingProgress(surahIndex, ayahIndex);
    
    // Show translation modal
    _showTranslationModal(surahIndex, ayahIndex, ayahText);
  }

  void _updateReadingProgress(int surahIndex, int ayahIndex) {
    // Update reading progress when user interacts with ayah
    ReadingProgressService.updateProgress(
      surahIndex: surahIndex,
      ayahIndex: ayahIndex,
      surahName: surahsData[surahIndex]?.name ?? 'Unknown Surah',
      paraIndex: widget.paraIndex,
      paraName: widget.paraName,
    );
  }

  // Helper methods for ayah navigation
  Map<String, int>? _getPreviousAyah(int surahIndex, int ayahIndex) {
    if (ayahIndex > 1) {
      // Same surah, previous ayah
      return {'surahIndex': surahIndex, 'ayahIndex': ayahIndex - 1};
    } else if (surahIndex > 1) {
      // Previous surah, last ayah
      int prevSurahIndex = surahIndex - 1;
      if (surahsData.containsKey(prevSurahIndex)) {
        int lastAyahIndex = surahsData[prevSurahIndex]!.ayahs.length;
        return {'surahIndex': prevSurahIndex, 'ayahIndex': lastAyahIndex};
      }
    }
    return null; // No previous ayah
  }

  Map<String, int>? _getNextAyah(int surahIndex, int ayahIndex) {
    if (surahsData.containsKey(surahIndex)) {
      SurahData currentSurah = surahsData[surahIndex]!;
      if (ayahIndex < currentSurah.ayahs.length) {
        // Same surah, next ayah
        return {'surahIndex': surahIndex, 'ayahIndex': ayahIndex + 1};
      } else {
        // Next surah, first ayah
        int nextSurahIndex = surahIndex + 1;
        if (surahsData.containsKey(nextSurahIndex)) {
          return {'surahIndex': nextSurahIndex, 'ayahIndex': 1};
        }
      }
    }
    return null; // No next ayah
  }

  String _getAyahText(int surahIndex, int ayahIndex) {
    if (surahsData.containsKey(surahIndex)) {
      SurahData surah = surahsData[surahIndex]!;
      AyahData? ayah = surah.ayahs.where((a) => a.ayahIndex == ayahIndex).firstOrNull;
      return ayah?.text ?? '';
    }
    return '';
  }

  void _navigateToAyah(int newSurahIndex, int newAyahIndex) {
    String ayahText = _getAyahText(newSurahIndex, newAyahIndex);
    
    // Update highlighting
    setState(() {
      highlightedAyah = '${newSurahIndex}_$newAyahIndex';
    });
    
    // Close current modal and show new one
    Navigator.pop(context);
    
    // Small delay to ensure smooth transition
    Future.delayed(const Duration(milliseconds: 100), () {
      _showTranslationModal(newSurahIndex, newAyahIndex, ayahText);
    });
  }

  void _showTranslationModal(int surahIndex, int ayahIndex, String ayahText) {
    String? translation = translationsData[surahIndex]?[ayahIndex];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: true,
      enableDrag: true,
      barrierColor: Colors.black54,
      builder: (context) => GestureDetector(
        onTap: () {}, // Prevents tap from propagating to barrier
        child: Consumer<FontProvider>(
          builder: (context, fontProvider, child) => _buildAsyncTranslationModal(surahIndex, ayahIndex, ayahText, translation, fontProvider),
        ),
      ),
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


  Widget _buildAsyncTranslationModal(int surahIndex, int ayahIndex, String ayahText, String? translation, FontProvider fontProvider) {
    return StatefulBuilder(
      builder: (context, setModalState) {
        Future<Map<String, bool>>? availabilityFuture;
        
        void refreshData() {
          availabilityFuture = _loadAvailabilityData(surahIndex, ayahIndex, refresh: true);
          setModalState(() {});
        }
        
        availabilityFuture ??= _loadAvailabilityData(surahIndex, ayahIndex);
        
        return FutureBuilder<Map<String, bool>>(
          future: availabilityFuture,
          builder: (context, snapshot) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final screenHeight = MediaQuery.of(context).size.height;
        
        // Default availability (all false) while loading
        Map<String, bool> availability = {
          'lughat_text': false,
          'lughat_audio': false,
          'lughat_video': false,
          'tafseer_text': false,
          'tafseer_audio': false,
          'tafseer_video': false,
          'faidi_text': false,
          'faidi_audio': false,
          'faidi_video': false,
        };
        
        if (snapshot.hasData) {
          availability = snapshot.data!;
        }
        
        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 60),
            height: screenHeight * 0.75, // Fixed height at 75% of screen
            width: double.infinity,
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
              mainAxisSize: MainAxisSize.max,
              children: [
              // Header with navigation - Fixed at top
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Previous ayah button
                    _buildNavigationButton(
                      icon: Icons.keyboard_arrow_left,
                      onPressed: () {
                        final prevAyah = _getPreviousAyah(surahIndex, ayahIndex);
                        if (prevAyah != null) {
                          _navigateToAyah(prevAyah['surahIndex']!, prevAyah['ayahIndex']!);
                        }
                      },
                      isEnabled: _getPreviousAyah(surahIndex, ayahIndex) != null,
                      isDark: isDark,
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Surah and Ayah info
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '${surahsData[surahIndex]?.name ?? 'Surah $surahIndex'}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'آیت ${_convertToArabicNumeral(ayahIndex)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Next ayah button
                    _buildNavigationButton(
                      icon: Icons.keyboard_arrow_right,
                      onPressed: () {
                        final nextAyah = _getNextAyah(surahIndex, ayahIndex);
                        if (nextAyah != null) {
                          _navigateToAyah(nextAyah['surahIndex']!, nextAyah['ayahIndex']!);
                        }
                      },
                      isEnabled: _getNextAyah(surahIndex, ayahIndex) != null,
                      isDark: isDark,
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Share button
                    _buildNavigationButton(
                      icon: Icons.share_rounded,
                      onPressed: () => _shareAyah(surahIndex, ayahIndex, ayahText, translation),
                      isEnabled: true,
                      isDark: isDark,
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Favorite button
                    _buildFavoriteButton(surahIndex, ayahIndex, isDark),
                    
                    const SizedBox(width: 8),
                    
                    // Refresh button
                    _buildNavigationButton(
                      icon: Icons.refresh_rounded,
                      onPressed: refreshData,
                      isEnabled: true,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // Arabic text
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark 
                                ? AppTheme.primaryGreen.withValues(alpha: 0.08)
                                : AppTheme.primaryGreen.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            ayahText,
                            style: TextStyle(
                              fontFamily: fontProvider.selectedArabicFont,
                              fontSize: 17,
                              color: isDark ? Colors.white : Colors.black87,
                              height: 1.8,
                            ),
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                      ),
                      
                      // Translation
                      if (translation != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              translation,
                              style: context.textStyle(
                                fontSize: 14,
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Column(
                          children: [
                            // Lughat section
                            _buildOptionSection(
                              title: context.l.verseVocabulary,
                              options: [
                                OptionData(
                                  icon: Icons.text_fields_rounded, 
                                  label: context.l.text, 
                                  type: 'lughat_text',
                                  isAvailable: availability['lughat_text'] ?? false,
                                ),
                                OptionData(
                                  icon: Icons.volume_up_rounded, 
                                  label: context.l.audio, 
                                  type: 'lughat_audio',
                                  isAvailable: availability['lughat_audio'] ?? false,
                                ),
                                OptionData(
                                  icon: Icons.videocam_rounded, 
                                  label: context.l.video, 
                                  type: 'lughat_video',
                                  isAvailable: availability['lughat_video'] ?? false,
                                ),
                              ],
                              surahIndex: surahIndex,
                              ayahIndex: ayahIndex,
                              isDark: isDark,
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // Tafseer section
                            _buildOptionSection(
                              title: context.l.verseCommentary,
                              options: [
                                OptionData(
                                  icon: Icons.text_fields_rounded, 
                                  label: context.l.text, 
                                  type: 'tafseer_text',
                                  isAvailable: availability['tafseer_text'] ?? false,
                                ),
                                OptionData(
                                  icon: Icons.volume_up_rounded, 
                                  label: context.l.audio, 
                                  type: 'tafseer_audio',
                                  isAvailable: availability['tafseer_audio'] ?? false,
                                ),
                                OptionData(
                                  icon: Icons.videocam_rounded, 
                                  label: context.l.video, 
                                  type: 'tafseer_video',
                                  isAvailable: availability['tafseer_video'] ?? false,
                                ),
                              ],
                              surahIndex: surahIndex,
                              ayahIndex: ayahIndex,
                              isDark: isDark,
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // Faidi section
                            _buildOptionSection(
                              title: context.l.verseBenefits,
                              options: [
                                OptionData(
                                  icon: Icons.text_fields_rounded, 
                                  label: context.l.text, 
                                  type: 'faidi_text',
                                  isAvailable: availability['faidi_text'] ?? false,
                                ),
                                OptionData(
                                  icon: Icons.volume_up_rounded, 
                                  label: context.l.audio, 
                                  type: 'faidi_audio',
                                  isAvailable: availability['faidi_audio'] ?? false,
                                ),
                                OptionData(
                                  icon: Icons.videocam_rounded, 
                                  label: context.l.video, 
                                  type: 'faidi_video',
                                  isAvailable: availability['faidi_video'] ?? false,
                                ),
                              ],
                              surahIndex: surahIndex,
                              ayahIndex: ayahIndex,
                              isDark: isDark,
                            ),
                            
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
          ),
        );
          },
        );
      },
    );
  }

  Future<Map<String, bool>> _loadAvailabilityData(int surahIndex, int ayahIndex, {bool refresh = false}) async {
    try {
      // Clear API cache if refresh is requested
      if (refresh) {
        QuranApiService.clearCacheForAyah(surahIndex, ayahIndex);
      }
      
      // Optimized: Batch load all section data at once
      final allSections = await QuranApiService.getAllSectionsData(surahIndex, ayahIndex);
      
      // Check text data availability (synchronous, from XML)
      final lughatTextAvailable = LughatService.hasTextData(surahIndex, ayahIndex);
      final tafseerTextAvailable = TafseerService.hasTextData(surahIndex, ayahIndex);
      final faidiTextAvailable = FaidiService.hasTextData(surahIndex, ayahIndex);
      
      // Check API data availability (from batched result)
      final lughatData = allSections['lughat'];
      final tafseerData = allSections['tafseer'];
      final faidiData = allSections['faidi'];

      return {
        'lughat_text': lughatTextAvailable,
        'lughat_audio': lughatData?.audioUrl != null,
        'lughat_video': lughatData?.videoUrl != null,
        'tafseer_text': tafseerTextAvailable,
        'tafseer_audio': tafseerData?.audioUrl != null,
        'tafseer_video': tafseerData?.videoUrl != null,
        'faidi_text': faidiTextAvailable,
        'faidi_audio': faidiData?.audioUrl != null,
        'faidi_video': faidiData?.videoUrl != null,
      };
    } catch (e) {
      debugPrint('Error loading availability data: $e');
      return {
        'lughat_text': false,
        'lughat_audio': false,
        'lughat_video': false,
        'tafseer_text': false,
        'tafseer_audio': false,
        'tafseer_video': false,
        'faidi_text': false,
        'faidi_audio': false,
        'faidi_video': false,
      };
    }
  }

  Widget _buildNavigationButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required bool isEnabled,
    required bool isDark,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isEnabled 
            ? AppTheme.primaryGreen.withValues(alpha: 0.1)
            : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        onPressed: isEnabled ? onPressed : null,
        icon: Icon(
          icon,
          size: 16,
          color: isEnabled
              ? AppTheme.primaryGreen
              : (isDark ? Colors.white.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.4)),
        ),
        padding: EdgeInsets.zero,
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
    // Use theme green color for all sections
    final sectionColor = AppTheme.primaryGreen;
    final bgColor = isDark 
        ? AppTheme.primaryGreen.withOpacity(0.08)
        : AppTheme.primaryGreen.withOpacity(0.05);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: sectionColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Title on the right
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: context.textStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: sectionColor,
              ),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
          ),
          const SizedBox(width: 8),
          // Icons on the left - no labels
          ...options.map((option) => Padding(
            padding: const EdgeInsets.only(left: 4),
            child: _buildCompactIconButton(
              icon: option.icon,
              color: sectionColor,
              onTap: option.isAvailable 
                  ? () => _handleOptionTap(option.type, surahIndex, ayahIndex)
                  : null,
              isDark: isDark,
              isAvailable: option.isAvailable,
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildCompactIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
    required bool isDark,
    required bool isAvailable,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isAvailable 
              ? (isDark ? color.withOpacity(0.2) : color.withOpacity(0.12))
              : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isAvailable 
                ? color.withOpacity(0.4)
                : Colors.grey.shade400,
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          color: isAvailable ? color : Colors.grey,
          size: 22,
        ),
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
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FullScreenTextViewer(
            content: textData.content,
            title: context.l.verseVocabularyTitle.replaceAll('{verse}', _convertToArabicNumeral(ayahIndex)),
          ),
        ),
      );
    } else {
      _showError(context.l.vocabularyTextNotAvailable);
    }
  }

  void _showLughatAudio(int surahIndex, int ayahIndex) async {
    try {
      final audioData = await LughatService.getAudioData(surahIndex, ayahIndex);
      if (audioData != null) {
        // Directly open bulk audio player
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BulkAudioPlayerScreen(
              initialSurahIndex: surahIndex,
              initialAyahIndex: ayahIndex,
              surahName: surahsData[surahIndex]?.name ?? 'Surah $surahIndex',
            ),
          ),
        );
      } else {
        _showError(context.l.vocabularyAudioNotAvailable);
      }
    } catch (e) {
      _showError('Error loading audio: $e');
    }
  }

  void _showLughatVideo(int surahIndex, int ayahIndex) async {
    try {
      final videoData = await LughatService.getVideoData(surahIndex, ayahIndex);
      if (videoData != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FullScreenVideoPlayer(
              videoUrl: videoData.content,
              title: context.l.verseVocabularyTitle.replaceAll('{verse}', _convertToArabicNumeral(ayahIndex)),
              surahIndex: surahIndex,
              ayahIndex: ayahIndex,
              sectionType: 'lughat',
            ),
          ),
        );
      } else {
        _showError(context.l.vocabularyVideoNotAvailable);
      }
    } catch (e) {
      _showError('Error loading video: $e');
    }
  }

  // Tafseer methods
  void _showTafseerText(int surahIndex, int ayahIndex) {
    final textData = TafseerService.getTextData(surahIndex, ayahIndex);
    if (textData != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FullScreenTextViewer(
            content: textData.content,
            title: 'Tafseer - Verse ${_convertToArabicNumeral(ayahIndex)}',
          ),
        ),
      );
    } else {
      _showError('Tafseer text not available for this verse.');
    }
  }

  void _showTafseerAudio(int surahIndex, int ayahIndex) async {
    try {
      final audioData = await TafseerService.getAudioData(surahIndex, ayahIndex);
      if (audioData != null) {
        // Use the same bulk audio player as lughat
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BulkAudioPlayerScreen(
              initialSurahIndex: surahIndex,
              initialAyahIndex: ayahIndex,
              surahName: surahsData[surahIndex]?.name ?? 'Surah $surahIndex',
              sectionType: 'tafseer', // Add section type parameter
            ),
          ),
        );
      } else {
        _showError('Tafseer audio not available for this verse.');
      }
    } catch (e) {
      _showError('Error loading tafseer audio: $e');
    }
  }

  void _showTafseerVideo(int surahIndex, int ayahIndex) async {
    try {
      final videoData = await TafseerService.getVideoData(surahIndex, ayahIndex);
      if (videoData != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FullScreenVideoPlayer(
              videoUrl: videoData.content,
              title: 'Tafseer Video - Verse ${_convertToArabicNumeral(ayahIndex)}',
              surahIndex: surahIndex,
              ayahIndex: ayahIndex,
              sectionType: 'tafseer',
            ),
          ),
        );
      } else {
        _showError('Tafseer video not available for this verse.');
      }
    } catch (e) {
      _showError('Error loading tafseer video: $e');
    }
  }

  // Faidi methods
  void _showFaidiText(int surahIndex, int ayahIndex) {
    final textData = FaidiService.getTextData(surahIndex, ayahIndex);
    if (textData != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FullScreenTextViewer(
            content: textData.content,
            title: 'Faidi - Verse ${_convertToArabicNumeral(ayahIndex)}',
          ),
        ),
      );
    } else {
      _showError('Faidi text not available for this verse.');
    }
  }

  void _showFaidiAudio(int surahIndex, int ayahIndex) async {
    try {
      final audioData = await FaidiService.getAudioData(surahIndex, ayahIndex);
      if (audioData != null) {
        // Use the same bulk audio player as lughat
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BulkAudioPlayerScreen(
              initialSurahIndex: surahIndex,
              initialAyahIndex: ayahIndex,
              surahName: surahsData[surahIndex]?.name ?? 'Surah $surahIndex',
              sectionType: 'faidi', // Add section type parameter
            ),
          ),
        );
      } else {
        _showError('Faidi audio not available for this verse.');
      }
    } catch (e) {
      _showError('Error loading faidi audio: $e');
    }
  }

  void _showFaidiVideo(int surahIndex, int ayahIndex) async {
    try {
      final videoData = await FaidiService.getVideoData(surahIndex, ayahIndex);
      if (videoData != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FullScreenVideoPlayer(
              videoUrl: videoData.content,
              title: 'Faidi Video - Verse ${_convertToArabicNumeral(ayahIndex)}',
              surahIndex: surahIndex,
              ayahIndex: ayahIndex,
              sectionType: 'faidi',
            ),
          ),
        );
      } else {
        _showError('Faidi video not available for this verse.');
      }
    } catch (e) {
      _showError('Error loading faidi video: $e');
    }
  }

  void _shareAyah(int surahIndex, int ayahIndex, String ayahText, String? translation) {
    final surahName = surahsData[surahIndex]?.name ?? 'Surah $surahIndex';
    final ayahNumber = ayahIndex + 1;
    
    String shareText = '$surahName - ${context.l.ayah} $ayahNumber\n\n';
    shareText += '$ayahText\n\n';
    if (translation != null && translation.isNotEmpty) {
      shareText += '$translation\n\n';
    }
    shareText += '📖 ${context.l.appTitle}';
    
    Share.share(shareText);
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        
        return AlertDialog(
          backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: AppTheme.primaryGreen,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                                  child: Text(
                    context.l.information,
                    style: TextStyle(
                      fontFamily: 'Bahij Badr Bold',
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(
              fontFamily: 'Bahij Badr Light',
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
            textDirection: TextDirection.rtl,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                context.l.ok,
                style: TextStyle(
                  fontFamily: 'Bahij Badr Light',
                  color: AppTheme.primaryGreen,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$feature - ${context.l.comingSoon}',
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
                  context.l.arabicTextFont,
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
                              context.l.textSizeLabel,
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
                                          fontSize.getDisplayName(context),
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
                        context.l.fontTypeLabel,
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

  Widget _buildFavoriteButton(int surahIndex, int ayahIndex, bool isDark) {
    return FutureBuilder<bool>(
      future: FavoritesService.isFavorite(surahIndex, ayahIndex),
      builder: (context, snapshot) {
        final isFavorite = snapshot.data ?? false;
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isFavorite 
                ? AppTheme.primaryGold.withValues(alpha: 0.1)
                : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            onPressed: () async {
              try {
                final newFavoriteStatus = await FavoritesService.toggleFavorite(surahIndex, ayahIndex);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        newFavoriteStatus 
                            ? context.l.addedToFavorites ?? 'Added to favorites'
                            : context.l.removedFromFavorites ?? 'Removed from favorites',
                        style: const TextStyle(fontFamily: 'Bahij Badr Light'),
                      ),
                      duration: const Duration(seconds: 2),
                      backgroundColor: AppTheme.primaryGreen,
                    ),
                  );
                  // Trigger rebuild to update heart icon
                  setState(() {});
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              size: 16,
              color: isFavorite
                  ? AppTheme.primaryGold
                  : (isDark ? Colors.white.withValues(alpha: 0.6) : Colors.grey),
            ),
            padding: EdgeInsets.zero,
          ),
        );
      },
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
              size: 24,
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.l.loading,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
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
                            
                            // Right side buttons
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
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
              bool isBismillah = line.contains('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ');
              bool isSurahHeader = line.startsWith('سُورَةُ');
              bool isParaHeader = line.startsWith('پارہ');
              bool isHeader = isBismillah || isSurahHeader || isParaHeader;
              
              return Container(
                width: double.infinity,
                constraints: BoxConstraints(minHeight: lineHeight),
                alignment: isHeader ? Alignment.center : Alignment.centerRight,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: line.isEmpty ? const SizedBox() : (isHeader ? Text(
                  line,
                  style: TextStyle(
                    fontFamily: (isSurahHeader || isParaHeader) ? 'Bahij Badr Bold' : selectedFont,
                    fontSize: isHeader ? (isBismillah ? fontSize * 0.9 : (isParaHeader ? fontSize * 0.85 : fontSize * 0.75)) : fontSize,
                    color: (isSurahHeader || isParaHeader) ? AppTheme.primaryGreen : (isDark ? Colors.white : Colors.black),
                    height: 1.4,
                    fontWeight: (isSurahHeader || isParaHeader) ? FontWeight.bold : FontWeight.normal,
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
              bool isBismillah = line.contains('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ');
              bool isSurahHeader = line.startsWith('سُورَةُ');
              bool isParaHeader = line.startsWith('پارہ');
              bool isHeader = isBismillah || isSurahHeader || isParaHeader;
              
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
                      fontFamily: (isSurahHeader || isParaHeader) ? 'Bahij Badr Bold' : selectedFont,
                      fontSize: isHeader ? (isBismillah ? 22 : (isParaHeader ? 20 : 18)) : fontSize,
                      color: (isSurahHeader || isParaHeader) ? AppTheme.primaryGreen : (isDark ? Colors.white : Colors.black),
                      height: 1.0,
                      fontWeight: (isSurahHeader || isParaHeader) ? FontWeight.bold : FontWeight.normal,
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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: isHighlighted ? BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppTheme.primaryGreen.withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ) : null,
            padding: isHighlighted ? const EdgeInsets.symmetric(horizontal: 4, vertical: 2) : EdgeInsets.zero,
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

class ParaData {
  final int index;
  final int startSurahIndex;
  final int startAyahIndex;

  ParaData({
    required this.index,
    required this.startSurahIndex,
    required this.startAyahIndex,
  });
}
