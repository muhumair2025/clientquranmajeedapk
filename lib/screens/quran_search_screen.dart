import '../widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import '../themes/app_theme.dart';
import '../localization/app_localizations_extension.dart';
import '../services/mushaf_database_service.dart';
import 'quran_reader_screen.dart';
import '../utils/theme_extensions.dart';

class QuranSearchScreen extends StatefulWidget {
  const QuranSearchScreen({super.key});

  @override
  State<QuranSearchScreen> createState() => _QuranSearchScreenState();
}

class _QuranSearchScreenState extends State<QuranSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  List<SearchResult> searchResults = [];
  bool isLoading = false;
  bool isLoadingQuranData = true;
  String _lastSearchQuery = '';
  
  // Cache for expensive operations
  final Map<String, String> _normalizedTextCache = {};
  
  // Quran data
  Map<int, SurahData> surahsData = {};


  @override
  void initState() {
    super.initState();
    _loadQuranData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadQuranData() async {
    try {
      // Database is already initialized in main.dart
      // Just load surah names and metadata for navigation
      await _loadSurahMetadata();
      
      setState(() {
        isLoadingQuranData = false;
      });
    } catch (e) {
      debugPrint('Error loading Quran data: $e');
      setState(() {
        isLoadingQuranData = false;
      });
    }
  }
  
  /// Get all ayahs from database in one efficient query
  Future<List<Map<String, dynamic>>> _getAllAyahsFromDatabase() async {
    try {
      // Single query to get all ayahs - much faster than 6236 individual queries!
      return await MushafDatabaseService.getAllAyahs();
    } catch (e) {
      debugPrint('❌ Error loading all ayahs: $e');
      return [];
    }
  }
  
  /// Load surah names and ayah counts from database
  Future<void> _loadSurahMetadata() async {
    try {
      // Surah names (standard Quran surah names)
      const surahNames = [
        'الفاتحة', 'البقرة', 'آل عمران', 'النساء', 'المائدة', 'الأنعام', 'الأعراف', 'الأنفال',
        'التوبة', 'يونس', 'هود', 'يوسف', 'الرعد', 'إبراهيم', 'الحجر', 'النحل',
        'الإسراء', 'الكهف', 'مريم', 'طه', 'الأنبياء', 'الحج', 'المؤمنون', 'النور',
        'الفرقان', 'الشعراء', 'النمل', 'القصص', 'العنكبوت', 'الروم', 'لقمان', 'السجدة',
        'الأحزاب', 'سبأ', 'فاطر', 'يس', 'الصافات', 'ص', 'الزمر', 'غافر',
        'فصلت', 'الشورى', 'الزخرف', 'الدخان', 'الجاثية', 'الأحقاف', 'محمد', 'الفتح',
        'الحجرات', 'ق', 'الذاريات', 'الطور', 'النجم', 'القمر', 'الرحمن', 'الواقعة',
        'الحديد', 'المجادلة', 'الحشر', 'الممتحنة', 'الصف', 'الجمعة', 'المنافقون', 'التغابن',
        'الطلاق', 'التحريم', 'الملك', 'القلم', 'الحاقة', 'المعارج', 'نوح', 'الجن',
        'المزمل', 'المدثر', 'القيامة', 'الإنسان', 'المرسلات', 'النبأ', 'النازعات', 'عبس',
        'التكوير', 'الانفطار', 'المطففين', 'الانشقاق', 'البروج', 'الطارق', 'الأعلى', 'الغاشية',
        'الفجر', 'البلد', 'الشمس', 'الليل', 'الضحى', 'الشرح', 'التين', 'العلق',
        'القدر', 'البينة', 'الزلزلة', 'العاديات', 'القارعة', 'التكاثر', 'العصر', 'الهمزة',
        'الفيل', 'قريش', 'الماعون', 'الكوثر', 'الكافرون', 'النصر', 'المسد', 'الإخلاص',
        'الفلق', 'الناس'
      ];
      
      // Ayah counts per surah
      const ayahCounts = [
        7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52, 99, 128,
        111, 110, 98, 135, 112, 78, 118, 64, 77, 227, 93, 88, 69, 60, 34, 30,
        73, 54, 45, 83, 182, 88, 75, 85, 54, 53, 89, 59, 37, 35, 38, 29,
        18, 45, 60, 49, 62, 55, 78, 96, 29, 22, 24, 13, 14, 11, 11, 18,
        12, 12, 30, 52, 52, 44, 28, 28, 20, 56, 40, 31, 50, 40, 46, 42,
        29, 19, 36, 25, 22, 17, 19, 26, 30, 20, 15, 21, 11, 8, 8, 19,
        5, 8, 8, 11, 11, 8, 3, 9, 5, 4, 7, 3, 6, 3, 5, 4, 5, 6
      ];
      
      // Build surah data structure
      for (int i = 0; i < surahNames.length; i++) {
        int surahIndex = i + 1;
        surahsData[surahIndex] = SurahData(
          index: surahIndex,
          name: surahNames[i],
          ayahs: List.generate(
            ayahCounts[i],
            (j) => AyahData(ayahIndex: j + 1, text: ''),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error loading surah metadata: $e');
    }
  }

  // Enhanced text normalization for intelligent Arabic search (with caching)
  String _normalizeAppText(String text) {
    // Check cache first
    if (_normalizedTextCache.containsKey(text)) {
      return _normalizedTextCache[text]!;
    }
    
    String normalized = text.trim();
    
    // Remove all diacritics and harakat (comprehensive Arabic diacritics)
    normalized = normalized.replaceAll(RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED\u08E3-\u08FE\u08F0-\u08F2\u08F3-\u08FF]'), '');
    
    // Remove punctuation and normalize spaces
    normalized = normalized.replaceAll(RegExp(r'[۔،؍؎؏؞؟٪٫٬٭\u060C\u061B\u061F\u06D4]'), ' ');
    
    // Normalize multiple spaces to single space
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // Apply comprehensive Arabic character normalization (const map for better performance)
    const charMap = {
      // Alif variations - normalize to basic alif
      'أ': 'ا', 'إ': 'ا', 'آ': 'ا', 'ء': 'ا', 'ٱ': 'ا',
      
      // Ya variations - normalize to basic ya
      'ی': 'ي', 'ئ': 'ي', 'ے': 'ي', 'ى': 'ي', 'ې': 'ي',
      
      // Waw variations
      'ؤ': 'و', 'ۋ': 'و', 'ۇ': 'و',
      
      // Ha variations
      'ہ': 'ه', 'ۀ': 'ه', 'ە': 'ه',
      
      // Kaaf variations
      'ک': 'ك', 'ڪ': 'ك', 'ګ': 'ك', 'گ': 'ك',
      
      // Ta marbuta and related
      'ة': 'ت', 'ٹ': 'ت',
      
      // Dal and related
      'ڈ': 'د', 'ډ': 'د',
      
      // Ra variations
      'ڑ': 'ر', 'ړ': 'ر',
      
      // Za and related (ذ maps to د not ز for better Arabic matching)
      'ژ': 'ز', 'ظ': 'ز', 'ږ': 'ز',
      
      // Sin and related
      'ص': 'س',
      
      // Tha maps to ت for consistency
      'ث': 'ت',
      
      // Noon variations
      'ں': 'ن', 'ڻ': 'ن',
      
      // Other normalizations for better matching
      'ق': 'ك', // Often confused
      'چ': 'ج', // Regional variations
      'ښ': 'ش', // Pashto
      'څ': 'ج', 'ځ': 'ج', // Pashto
      'ټ': 'ت', // Pashto
    };
    
    // Apply character mappings
    charMap.forEach((from, to) {
      normalized = normalized.replaceAll(from, to);
    });
    
    final result = normalized.toLowerCase();
    
    // Cache result (limit cache size to prevent memory issues)
    if (_normalizedTextCache.length < 1000) {
      _normalizedTextCache[text] = result;
    }
    
    return result;
  }
  
  // Create space-flexible normalized text for better matching
  String _normalizeTextForSpaceFlexibleSearch(String text) {
    String normalized = _normalizeAppText(text);
    // Remove all spaces for space-flexible matching
    return normalized.replaceAll(RegExp(r'\s+'), '');
  }


  void _performTextSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        searchResults = [];
        _lastSearchQuery = '';
      });
      return;
    }
    
    // Skip search if query hasn't changed
    if (query == _lastSearchQuery) {
      return;
    }
    
    _lastSearchQuery = query;

    setState(() {
      isLoading = true;
    });

    // Use async execution to prevent UI blocking
    Future.microtask(() async {
      List<SearchResult> results = [];
      
      // Clean and normalize the query
      String cleanQuery = query.trim();
      String normalizedQuery = _normalizeAppText(cleanQuery);
      
      // Early exit for very short queries
      if (cleanQuery.length < 2) {
        if (mounted) {
          setState(() {
            searchResults = [];
            isLoading = false;
          });
        }
        return;
      }
      
      // ✨ OPTIMIZED DATABASE SEARCH - Load all text at once!
      try {
        // Get all ayahs from database in one efficient query
        final allAyahs = await _getAllAyahsFromDatabase();
        
        // Now search through the cached data (much faster!)
        int processedCount = 0;
        const batchSize = 100;
        
        for (var ayahData in allAyahs) {
          // Safe casting with null checks
          final arabicText = ayahData['text'] as String?;
          final surahNum = ayahData['sura'] as int?;
          final ayahNum = ayahData['ayah'] as int?;
          
          // Skip if any field is null
          if (arabicText == null || surahNum == null || ayahNum == null) continue;
          
          // Analyze match quality
          final matchResult = _analyzeMatch(arabicText, cleanQuery, normalizedQuery, []);
          
          if (matchResult.found) {
            final surahData = surahsData[surahNum];
            if (surahData == null) continue;
            
            // Calculate relevance score
            double relevanceScore = _calculateRelevance(
              arabicText,
              cleanQuery,
              normalizedQuery,
            );
            
            // Apply confidence multiplier
            relevanceScore *= matchResult.confidence;
            
            results.add(SearchResult(
              surahIndex: surahNum,
              surahName: surahData.name,
              ayahIndex: ayahNum,
              ayahText: arabicText,
              translation: '',
              matchType: 'arabic',
              relevanceScore: relevanceScore,
            ));
          }
          
          // Yield control periodically to keep UI responsive
          processedCount++;
          if (processedCount % batchSize == 0) {
            await Future.delayed(Duration.zero);
          }
        }
      } catch (e) {
        debugPrint('❌ Database search error: $e');
      }

      // Sort sequentially: Surah 1 first, then Surah 2, etc.
      results.sort((a, b) {
        // First by surah number
        int surahCompare = a.surahIndex.compareTo(b.surahIndex);
        if (surahCompare != 0) return surahCompare;
        
        // Then by ayah number within the same surah
        return a.ayahIndex.compareTo(b.ayahIndex);
      });
      
      // Remove duplicate or very similar results
      results = _removeDuplicateResults(results);
      
      // Limit results to top 50 for better performance and relevance
      if (results.length > 50) {
        results = results.take(50).toList();
      }

      // Only update UI if query is still current and widget is mounted
      if (mounted && query == _lastSearchQuery) {
        setState(() {
          searchResults = results;
          isLoading = false;
        });
      }
    });
  }
  
  // Analyze match quality and confidence with space-flexible search
  MatchResult _analyzeMatch(String text, String query, String normalizedQuery, List<RegExp> patterns) {
    String lowerText = text.toLowerCase();
    String lowerQuery = query.toLowerCase();
    String normalizedText = _normalizeAppText(text);
    
    // Create space-flexible versions
    String spaceFlexibleText = _normalizeTextForSpaceFlexibleSearch(text);
    String spaceFlexibleQuery = _normalizeTextForSpaceFlexibleSearch(query);
    
    // Check for different types of matches with confidence levels
    
    // Perfect exact match
    if (text == query) {
      return MatchResult(found: true, confidence: 1.0, matchType: 'perfect');
    }
    
    // Case-insensitive exact match
    if (lowerText == lowerQuery) {
      return MatchResult(found: true, confidence: 0.98, matchType: 'exact');
    }
    
    // Normalized exact match (with diacritics removed)
    if (normalizedText == normalizedQuery) {
      return MatchResult(found: true, confidence: 0.95, matchType: 'normalized_exact');
    }
    
    // Space-flexible exact match (handles missing/extra spaces)
    if (spaceFlexibleText == spaceFlexibleQuery) {
      return MatchResult(found: true, confidence: 0.92, matchType: 'space_flexible_exact');
    }
    
    // Exact substring with word boundaries
    try {
      if (RegExp(r'\b' + RegExp.escape(lowerQuery) + r'\b').hasMatch(lowerText)) {
        return MatchResult(found: true, confidence: 0.9, matchType: 'word_boundary');
      }
    } catch (e) {
      // Skip if regex fails
    }
    
    // Exact substring match
    if (lowerText.contains(lowerQuery)) {
      return MatchResult(found: true, confidence: 0.85, matchType: 'substring');
    }
    
    // Normalized substring match
    if (normalizedText.contains(normalizedQuery)) {
      return MatchResult(found: true, confidence: 0.8, matchType: 'normalized_substring');
    }
    
    // Space-flexible substring match
    if (spaceFlexibleText.contains(spaceFlexibleQuery)) {
      return MatchResult(found: true, confidence: 0.75, matchType: 'space_flexible_substring');
    }
    
    // Split query into words for partial matching
    List<String> queryWords = normalizedQuery.split(' ').where((w) => w.isNotEmpty).toList();
    if (queryWords.length > 1) {
      int matchedWords = 0;
      for (String word in queryWords) {
        if (normalizedText.contains(word)) {
          matchedWords++;
        }
      }
      
      // If most words match, consider it a partial match
      double wordMatchRatio = matchedWords / queryWords.length;
      if (wordMatchRatio >= 0.7) {
        return MatchResult(found: true, confidence: 0.7 * wordMatchRatio, matchType: 'partial_words');
      }
    }
    
    // Pattern matching (fuzzy with character variations)
    for (RegExp pattern in patterns) {
      try {
        if (pattern.hasMatch(text) || pattern.hasMatch(normalizedText)) {
          return MatchResult(found: true, confidence: 0.6, matchType: 'pattern');
        }
      } catch (e) {
        // Skip if pattern fails
      }
    }
    
    return MatchResult(found: false, confidence: 0.0, matchType: 'none');
  }
  
  // Get match priority for sorting (Arabic text only)
  int _getMatchPriority(SearchResult result, String query) {
    String text = result.ayahText; // Always Arabic text now
    String lowerText = text.toLowerCase();
    String lowerQuery = query.toLowerCase();
    String normalizedText = _normalizeAppText(text);
    String normalizedQuery = _normalizeAppText(query);
    String spaceFlexibleText = _normalizeTextForSpaceFlexibleSearch(text);
    String spaceFlexibleQuery = _normalizeTextForSpaceFlexibleSearch(query);
    
    if (text == query) return 10; // Perfect match
    if (lowerText == lowerQuery) return 9; // Case-insensitive exact
    if (normalizedText == normalizedQuery) return 8; // Normalized exact (no diacritics)
    if (spaceFlexibleText == spaceFlexibleQuery) return 7; // Space-flexible exact
    
    try {
      if (RegExp(r'\b' + RegExp.escape(lowerQuery) + r'\b').hasMatch(lowerText)) return 6; // Word boundary
    } catch (e) {
      // Skip if regex fails
    }
    
    if (lowerText.contains(lowerQuery)) return 5; // Substring
    if (normalizedText.contains(normalizedQuery)) return 4; // Normalized substring
    if (spaceFlexibleText.contains(spaceFlexibleQuery)) return 3; // Space-flexible substring
    
    return 1; // Pattern/fuzzy match
  }
  
  // Remove duplicate or very similar results
  List<SearchResult> _removeDuplicateResults(List<SearchResult> results) {
    List<SearchResult> uniqueResults = [];
    Set<String> seenAyahs = {};
    
    for (SearchResult result in results) {
      String ayahKey = '${result.surahIndex}_${result.ayahIndex}';
      
      if (!seenAyahs.contains(ayahKey)) {
        seenAyahs.add(ayahKey);
        uniqueResults.add(result);
      }
    }
    
    return uniqueResults;
  }

  // Enhanced relevance scoring for intelligent search results
  double _calculateRelevance(String text, String query, String normalizedQuery) {
    double score = 0.0;
    String normalizedText = _normalizeAppText(text);
    String lowerText = text.toLowerCase();
    String lowerQuery = query.toLowerCase();
    
    // 1. Perfect exact match (highest priority) - 100 points
    if (text == query || lowerText == lowerQuery) {
      score += 100.0;
    }
    // 2. Exact substring match with word boundaries - 80 points
    else if (_isExactWordMatch(lowerText, lowerQuery)) {
      score += 80.0;
    }
    // 3. Exact substring match (case-insensitive) - 60 points
    else if (lowerText.contains(lowerQuery)) {
      score += 60.0;
    }
    // 4. Normalized exact match - 40 points
    else if (normalizedText == normalizedQuery) {
      score += 40.0;
    }
    // 5. Normalized substring match - 30 points
    else if (normalizedText.contains(normalizedQuery)) {
      score += 30.0;
    }
    // 6. Fuzzy/pattern match - 20 points
    else {
      score += 20.0;
    }
    
    // Bonus scoring factors
    
    // Word completeness bonus (prefer complete words)
    if (_isCompleteWord(normalizedText, normalizedQuery)) {
      score += 15.0;
    }
    
    // Position bonus (matches at start get higher score)
    int position = normalizedText.indexOf(normalizedQuery);
    if (position == 0) {
      score += 10.0; // Starts with query
    } else if (position > 0 && position < normalizedText.length * 0.3) {
      score += 5.0; // Early in text
    }
    
    // Length factor (prefer shorter, more focused results)
    if (text.length < 100) {
      score += 10.0;
    } else if (text.length < 200) {
      score += 5.0;
    }
    
    // Multiple occurrences bonus
    int occurrences = normalizedQuery.allMatches(normalizedText).length;
    if (occurrences > 1) {
      score += occurrences * 3.0;
    }
    
    // Phrase integrity bonus (prefer results that don't break meaningful phrases)
    if (_hasGoodPhraseIntegrity(text, query)) {
      score += 8.0;
    }
    
    return score;
  }
  
  // Check if query matches as complete words (with word boundaries)
  bool _isExactWordMatch(String text, String query) {
    // Create word boundary pattern
    String pattern = r'\b' + RegExp.escape(query) + r'\b';
    return RegExp(pattern, caseSensitive: false).hasMatch(text);
  }
  
  // Check if the match represents complete words
  bool _isCompleteWord(String text, String query) {
    List<String> textWords = text.split(' ');
    List<String> queryWords = query.split(' ');
    
    // Check if all query words are complete matches in text
    for (String queryWord in queryWords) {
      bool foundCompleteMatch = false;
      for (String textWord in textWords) {
        if (textWord == queryWord) {
          foundCompleteMatch = true;
          break;
        }
      }
      if (!foundCompleteMatch) return false;
    }
    return true;
  }
  
  // Check phrase integrity (avoid breaking meaningful Arabic phrases)
  bool _hasGoodPhraseIntegrity(String text, String query) {
    // If query is a single word, integrity is good
    if (!query.contains(' ')) return true;
    
    // Check if the query appears as a complete phrase
    String normalizedText = _normalizeAppText(text);
    String normalizedQuery = _normalizeAppText(query);
    
    return normalizedText.contains(normalizedQuery);
  }

  void _navigateToAyah(int surahIndex, int ayahIndex) {
    final surahData = surahsData[surahIndex];
    if (surahData != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuranReaderScreen(
            surahIndex: surahIndex,
            surahName: surahData.name,
            initialAyahIndex: ayahIndex,
            highlightInitialAyah: true, // Highlight searched ayah
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isLoadingQuranData) {
      return Scaffold(
        backgroundColor: isDark ? context.backgroundColor : context.backgroundColor,
        appBar: AppBar(
          title: AppText(context.l.quranSearch),
          backgroundColor: context.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(context.primaryColor),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? context.backgroundColor : context.backgroundColor,
      appBar: AppBar(
        title: AppText(context.l.quranSearch),
        backgroundColor: context.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildSearchContent(),
    );
  }

  Widget _buildSearchContent() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Search input
        Container(
          color: isDark ? context.surfaceColor : Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isDark ? context.backgroundColor : AppTheme.lightGray,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  textDirection: TextDirection.rtl,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (value) {
                    // Search when user presses Enter/Search button
                    if (value.trim().isNotEmpty) {
                      _performTextSearch(value.trim());
                    } else {
                      setState(() {
                        searchResults = [];
                        _lastSearchQuery = '';
                      });
                    }
                  },
                  decoration: InputDecoration(
                    hintText: context.l.searchInArabicText,
                    hintStyle: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: context.primaryColor,
                      size: 24,
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: Icon(Icons.clear_rounded, color: Colors.grey[500]),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                searchResults = [];
                                _lastSearchQuery = '';
                              });
                            },
                          ),
                        IconButton(
                          icon: Icon(Icons.search_rounded, color: context.primaryColor),
                          onPressed: () {
                            final text = _searchController.text.trim();
                            if (text.isNotEmpty) {
                              _searchFocusNode.unfocus();
                              _performTextSearch(text);
                            }
                          },
                        ),
                      ],
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    '🔍 Enter Arabic text and tap Search button or press Enter',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Search results
        Expanded(
          child: isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(context.primaryColor),
                  ),
                )
              : searchResults.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_rounded,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 20),
                              AppText(
                                _searchController.text.isEmpty
                                    ? context.l.searchPlaceholder
                                    : context.l.noResultsFound,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (_searchController.text.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                AppText(
                                  context.l.tryDifferentText,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        final result = searchResults[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isDark ? context.surfaceColor : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: context.primaryColor.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _navigateToAyah(result.surahIndex, result.ayahIndex),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    // Surah and Ayah info - Compact
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: context.primaryColor.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: AppText(
                                            '${result.ayahIndex}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: context.primaryColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        AppText(
                                          result.surahName,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // Arabic text with highlight (search only in Arabic)
                                    _buildHighlightedAppText(
                                      result.ayahText,
                                      _searchController.text,
                                      TextStyle(
                                        fontSize: 18,
                                        fontFamily: 'Noorehuda',
                                        color: isDark ? Colors.white : Colors.black87,
                                        height: 1.8,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }


  Widget _buildHighlightedAppText(String text, String query, TextStyle style) {
    if (query.isEmpty) {
      return AppText(
        text,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        style: style,
      );
    }

    // Use multiple highlighting strategies for better coverage
    final spans = _createHighlightSpans(text, query, style);
    
    if (spans.isEmpty) {
      return AppText(
        text,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        style: style,
      );
    }

    return RichText(
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
      text: TextSpan(children: spans),
    );
  }
  
  List<TextSpan> _createHighlightSpans(String text, String query, TextStyle style) {
    final spans = <TextSpan>[];
    final highlightStyle = style.copyWith(
      backgroundColor: context.accentColor.withValues(alpha: 0.3),
      fontWeight: FontWeight.bold,
    );
    
    if (query.isEmpty) {
      spans.add(TextSpan(text: text, style: style));
      return spans;
    }
    
    // IMPROVED: Use word-based matching to avoid splitting words
    List<_HighlightMatch> matches = _findWordBasedMatches(text, query);
    
    if (matches.isEmpty) {
      spans.add(TextSpan(text: text, style: style));
      return spans;
    }
    
    // Sort and merge overlapping matches
    matches.sort((a, b) => a.start.compareTo(b.start));
    matches = _mergeOverlappingMatches(matches);
    
    // Build spans with highlighting
    int lastEnd = 0;
    
    for (final match in matches) {
      // Add text before match
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: style,
        ));
      }
      
      // Add highlighted match
      spans.add(TextSpan(
        text: text.substring(match.start, match.end),
        style: highlightStyle,
      ));
      
      lastEnd = match.end;
    }
    
    // Add remaining text
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: style,
      ));
    }
    
    return spans;
  }
  
  /// Find matches based on complete words (don't split words!)
  List<_HighlightMatch> _findWordBasedMatches(String text, String query) {
    List<_HighlightMatch> matches = [];
    
    // Normalize for comparison
    final normalizedText = _normalizeAppText(text);
    final normalizedQuery = _normalizeAppText(query);
    
    if (normalizedQuery.isEmpty) return matches;
    
    // Method 1: Try to find exact phrase in normalized text
    int index = 0;
    while (index < normalizedText.length) {
      int foundIndex = normalizedText.indexOf(normalizedQuery, index);
      if (foundIndex == -1) break;
      
      // Map back to original text with word boundary awareness
      final matchInfo = _findOriginalTextBounds(text, normalizedText, foundIndex, normalizedQuery.length);
      if (matchInfo != null) {
        matches.add(matchInfo);
      }
      
      index = foundIndex + normalizedQuery.length;
    }
    
    return matches;
  }
  
  
  
  /// Find the original text bounds for a normalized match
  _HighlightMatch? _findOriginalTextBounds(String originalText, String normalizedText, int normalizedStart, int normalizedLength) {
    int charCountInNormalized = 0;
    int originalStart = -1;
    int originalEnd = -1;
    
    for (int i = 0; i < originalText.length; i++) {
      // Get normalized version of current character
      final char = originalText[i];
      
      // Skip diacritics and special characters that get removed in normalization
      if (_isDiacritic(char)) continue;
      
      // This character counts in normalized text
      if (charCountInNormalized == normalizedStart && originalStart == -1) {
        originalStart = i;
      }
      
      charCountInNormalized++;
      
      if (charCountInNormalized == normalizedStart + normalizedLength) {
        originalEnd = i + 1;
        break;
      }
    }
    
    if (originalStart >= 0 && originalEnd > originalStart) {
      return _HighlightMatch(originalStart, originalEnd);
    }
    
    return null;
  }
  
  /// Check if character is a diacritic mark
  bool _isDiacritic(String char) {
    if (char.isEmpty) return false;
    final code = char.codeUnitAt(0);
    
    // Arabic diacritics range
    return (code >= 0x064B && code <= 0x065F) ||  // Main diacritics
           code == 0x0670 ||                        // Superscript alef
           (code >= 0x06D6 && code <= 0x06ED) ||  // Extended diacritics
           (code >= 0x08E3 && code <= 0x08FE);     // More diacritics
  }
  

  
  // Merge overlapping matches
  List<_HighlightMatch> _mergeOverlappingMatches(List<_HighlightMatch> matches) {
    if (matches.isEmpty) return matches;
    
    List<_HighlightMatch> merged = [];
    _HighlightMatch current = matches[0];
    
    for (int i = 1; i < matches.length; i++) {
      _HighlightMatch next = matches[i];
      
      if (next.start <= current.end) {
        // Overlapping or adjacent, merge them
        current = _HighlightMatch(current.start, math.max(current.end, next.end));
      } else {
        // No overlap, add current and move to next
        merged.add(current);
        current = next;
      }
    }
    
    merged.add(current);
    return merged;
  }
}

// Helper class for highlight matches
class _HighlightMatch {
  final int start;
  final int end;
  
  _HighlightMatch(this.start, this.end);
}

// Helper class for word information
class WordInfo {
  final String word;
  final int start;
  final int end;
  
  WordInfo(this.word, this.start, this.end);
}

// Search result model
class SearchResult {
  final int surahIndex;
  final String surahName;
  final int ayahIndex;
  final String ayahText;
  final String translation;
  final String matchType; // 'arabic' or 'translation'
  final double relevanceScore;

  SearchResult({
    required this.surahIndex,
    required this.surahName,
    required this.ayahIndex,
    required this.ayahText,
    required this.translation,
    required this.matchType,
    this.relevanceScore = 0.0,
  });
}

// Match analysis result
class MatchResult {
  final bool found;
  final double confidence; // 0.0 to 1.0
  final String matchType;

  MatchResult({
    required this.found,
    required this.confidence,
    required this.matchType,
  });
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