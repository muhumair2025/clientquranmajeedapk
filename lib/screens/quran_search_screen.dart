import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xml/xml.dart';
import 'dart:async';
import 'dart:math' as math;
import '../themes/app_theme.dart';
import '../localization/app_localizations_extension.dart';
import 'quran_reader_screen.dart';

class QuranSearchScreen extends StatefulWidget {
  const QuranSearchScreen({super.key});

  @override
  State<QuranSearchScreen> createState() => _QuranSearchScreenState();
}

class _QuranSearchScreenState extends State<QuranSearchScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _ayahNumberController = TextEditingController();
  
  List<SearchResult> searchResults = [];
  bool isLoading = false;
  bool isLoadingQuranData = true;
  Timer? _searchDebounceTimer;
  
  // Cache for expensive operations
  final Map<String, String> _normalizedTextCache = {};
  final Map<String, List<RegExp>> _searchPatternsCache = {};
  String _lastSearchQuery = '';
  
  // Quran data
  Map<int, SurahData> surahsData = {};
  Map<int, Map<int, String>> translationsData = {};
  
  // Selected surah for navigation
  int? selectedSurahIndex;
  int? maxAyahForSelectedSurah;

  // Enhanced character mapping for intelligent search normalization
  static final Map<String, List<String>> characterVariations = {
    // Arabic/Urdu/Pashto variations of similar letters
    'ک': ['ك', 'ڪ', 'ګ', 'گ'], // Different forms of kaaf
    'ك': ['ک', 'ڪ', 'ګ', 'گ'],
    'ی': ['ي', 'ئ', 'ے', 'ى', 'ې'], // Different forms of ya
    'ي': ['ی', 'ئ', 'ے', 'ى', 'ې'],
    'ہ': ['ه', 'ۀ', 'ە', 'ح', 'خ'], // Different forms of ha
    'ه': ['ہ', 'ۀ', 'ە', 'ح', 'خ'],
    'و': ['ؤ', 'ۋ', 'ۇ'], // Different forms of waw
    'ا': ['أ', 'إ', 'آ', 'ء', 'ٱ'], // Different forms of alif
    'ت': ['ة', 'ٹ', 'ث'], // Ta and related letters
    'ة': ['ت', 'ٹ', 'ث'],
    'د': ['ذ', 'ڈ'], // Dal and related letters
    'ذ': ['د', 'ڈ'],
    'ر': ['ڑ', 'ړ', 'ز'], // Different forms of ra
    'ز': ['ذ', 'ژ', 'ر'],
    'ن': ['ں', 'ڻ'], // Noon and variations
    'س': ['ص', 'ث'], // Sin and related letters
    'ط': ['ت', 'ٹ'], // Ta variations
    'ظ': ['ز', 'ذ'], // Za variations
    'ع': ['غ'], // Ain and ghain
    'غ': ['ع'],
    'ف': ['پ'], // Fa and pa
    'پ': ['ف'],
    'ق': ['ک', 'ك'], // Qaf and kaaf
    'ل': ['ڵ'], // Lam variations
    'م': ['ۂ'], // Meem variations
    'ژ': ['ز', 'ذ'], // Zhe and za
    'گ': ['ګ', 'ک', 'ك'], // Gaf variations
    'چ': ['ج'], // Che and jeem
    'ج': ['چ'],
    'ښ': ['ش'], // Pashto specific
    'ږ': ['ژ', 'ز'],
    'ړ': ['ر'],
    'ډ': ['د'],
    'ټ': ['ت'],
    'څ': ['ج'],
    'ځ': ['ج'],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadQuranData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _ayahNumberController.dispose();
    _searchDebounceTimer?.cancel();
    super.dispose();
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
          String translation = ayaElement.getAttribute('text') ?? '';
          surahTranslations[ayahIndex] = translation;
        }
        
        translationsData[surahIndex] = surahTranslations;
      }
      
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

  // Enhanced text normalization for intelligent Arabic search (with caching)
  String _normalizeText(String text) {
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
    String normalized = _normalizeText(text);
    // Remove all spaces for space-flexible matching
    return normalized.replaceAll(RegExp(r'\s+'), '');
  }

  // Create search pattern that handles character variations
  RegExp _createSearchPattern(String query) {
    String pattern = '';
    
    for (int i = 0; i < query.length; i++) {
      String char = query[i];
      
      // Check if this character has variations
      bool hasVariation = false;
      for (var entry in characterVariations.entries) {
        if (entry.key == char || entry.value.contains(char)) {
          // Create character class with all variations
          List<String> allVariations = [entry.key, ...entry.value];
          pattern += '[${allVariations.join('')}]';
          hasVariation = true;
          break;
        }
      }
      
      if (!hasVariation) {
        // Escape special regex characters
        if (RegExp(r'[\[\](){}+*?^$|.\-\\]').hasMatch(char)) {
          pattern += '\\$char';
        } else {
          pattern += char;
        }
      }
    }
    
    return RegExp(pattern, caseSensitive: false);
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
      String normalizedQuery = _normalizeText(cleanQuery);
      
      // Create multiple search strategies for better matching
      List<RegExp> searchPatterns = _createMultipleSearchPatterns(cleanQuery);
      
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
      
      // Search through all surahs and ayahs (Arabic text only)
      int processedCount = 0;
      const batchSize = 50; // Process in batches to prevent blocking
      
      for (var entry in surahsData.entries) {
        final surahIndex = entry.key;
        final surahData = entry.value;
        
        for (var ayah in surahData.ayahs) {
          // Only search in Arabic text
          MatchResult arabicMatch = _analyzeMatch(ayah.text, cleanQuery, normalizedQuery, searchPatterns);
          
          // Add result if match found in Arabic text
          if (arabicMatch.found) {
            double relevanceScore = _calculateRelevance(
              ayah.text,
              cleanQuery,
              normalizedQuery,
            );
            
            // Apply confidence multiplier
            relevanceScore *= arabicMatch.confidence;
            
            // Get translation for display (but not for searching)
            String? translation = translationsData[surahIndex]?[ayah.ayahIndex];
            
            results.add(SearchResult(
              surahIndex: surahIndex,
              surahName: surahData.name,
              ayahIndex: ayah.ayahIndex,
              ayahText: ayah.text,
              translation: translation ?? '',
              matchType: 'arabic', // Always Arabic since we only search Arabic
              relevanceScore: relevanceScore,
            ));
          }
          
          // Yield control periodically to prevent blocking
          processedCount++;
          if (processedCount % batchSize == 0) {
            // Allow other operations to run
            await Future.delayed(Duration.zero);
          }
        }
      }

      // Advanced sorting: prioritize exact matches, then by relevance
      results.sort((a, b) {
        // First sort by match type priority (exact matches first)
        int aPriority = _getMatchPriority(a, cleanQuery);
        int bPriority = _getMatchPriority(b, cleanQuery);
        
        if (aPriority != bPriority) {
          return bPriority.compareTo(aPriority); // Higher priority first
        }
        
        // Then by relevance score
        return b.relevanceScore.compareTo(a.relevanceScore);
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
  
  // Create multiple search patterns for better matching (with caching)
  List<RegExp> _createMultipleSearchPatterns(String query) {
    // Check cache first
    if (_searchPatternsCache.containsKey(query)) {
      return _searchPatternsCache[query]!;
    }
    
    List<RegExp> patterns = [];
    
    try {
      // 1. Exact pattern (case-insensitive)
      patterns.add(RegExp(RegExp.escape(query), caseSensitive: false));
      
      // 2. Flexible character variation pattern
      patterns.add(_createSearchPattern(query));
      
      // 3. Word-boundary pattern for complete word matches
      patterns.add(RegExp(r'\b' + RegExp.escape(query) + r'\b', caseSensitive: false));
      
      // 4. Normalized pattern
      String normalizedQuery = _normalizeText(query);
      if (normalizedQuery != query.toLowerCase()) {
        patterns.add(RegExp(RegExp.escape(normalizedQuery), caseSensitive: false));
      }
    } catch (e) {
      // Fallback to simple pattern
      patterns.add(RegExp(RegExp.escape(query), caseSensitive: false));
    }
    
    // Cache result (limit cache size)
    if (_searchPatternsCache.length < 100) {
      _searchPatternsCache[query] = patterns;
    }
    
    return patterns;
  }
  
  // Analyze match quality and confidence with space-flexible search
  MatchResult _analyzeMatch(String text, String query, String normalizedQuery, List<RegExp> patterns) {
    String lowerText = text.toLowerCase();
    String lowerQuery = query.toLowerCase();
    String normalizedText = _normalizeText(text);
    
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
    String normalizedText = _normalizeText(text);
    String normalizedQuery = _normalizeText(query);
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
    String normalizedText = _normalizeText(text);
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
    String normalizedText = _normalizeText(text);
    String normalizedQuery = _normalizeText(query);
    
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
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        appBar: AppBar(
          title: Text(context.l.quranSearch),
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        title: Text(context.l.quranSearch),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Tab selector
          Container(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkBackground : AppTheme.lightGray,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _tabController.animateTo(0),
                          child: AnimatedBuilder(
                            animation: _tabController,
                            builder: (context, child) {
                              final isSelected = _tabController.index == 0;
                              return Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: isSelected ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ] : null,
                                ),
                                child: Text(
                                  context.l.textSearch,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? AppTheme.primaryGreen : Colors.grey[600],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _tabController.animateTo(1),
                          child: AnimatedBuilder(
                            animation: _tabController,
                            builder: (context, child) {
                              final isSelected = _tabController.index == 1;
                              return Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppTheme.primaryGold : Colors.transparent,
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: isSelected ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ] : null,
                                ),
                                child: Text(
                                  context.l.directNavigation,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? Colors.white : Colors.grey[600],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTextSearchTab(),
                _buildNavigationTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextSearchTab() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Search input
        Container(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkBackground : AppTheme.lightGray,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  textDirection: TextDirection.rtl,
                  onChanged: (value) {
                    // Improved debounce search with cancellation
                    if (_searchDebounceTimer?.isActive ?? false) {
                      _searchDebounceTimer!.cancel();
                    }
                    
                    _searchDebounceTimer = Timer(const Duration(milliseconds: 400), () {
                      if (_searchController.text == value) {
                        if (value.trim().isNotEmpty) {
                          _performTextSearch(value.trim());
                        } else {
                          setState(() {
                            searchResults = [];
                            _lastSearchQuery = '';
                          });
                        }
                      }
                    });
                  },
                  decoration: InputDecoration(
                    hintText: context.l.searchInArabicText,
                    hintStyle: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: AppTheme.primaryGreen,
                      size: 24,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded, color: Colors.grey[500]),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                searchResults = [];
                              });
                            },
                          )
                        : null,
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
                  Text(
                    context.l.smartSearchSystem,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontFamily: 'Bahij Badr Light',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l.searchFeatures,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontFamily: 'Bahij Badr Light',
                      height: 1.3,
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
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                  ),
                )
              : searchResults.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_rounded,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _searchController.text.isEmpty
                                ? context.l.searchPlaceholder
                                : context.l.noResultsFound,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontFamily: 'Bahij Badr Light',
                            ),
                          ),
                          if (_searchController.text.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              context.l.tryDifferentText,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                                fontFamily: 'Bahij Badr Light',
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        final result = searchResults[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkSurface : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _navigateToAyah(result.surahIndex, result.ayahIndex),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    // Surah and Ayah info
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '${context.l.ayah} ${result.ayahIndex}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.primaryGreen,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          result.surahName,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    // Arabic text with highlight (search only in Arabic)
                                    _buildHighlightedText(
                                      result.ayahText,
                                      _searchController.text,
                                      TextStyle(
                                        fontSize: 22,
                                        fontFamily: 'Al Qalam Quran Majeed',
                                        color: isDark ? Colors.white : Colors.black87,
                                        height: 2.2,
                                        letterSpacing: 0.5,
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

  Widget _buildNavigationTab() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppTheme.primaryGreen,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.l.selectSurahFirst,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.primaryGreen,
                      fontFamily: 'Bahij Badr Light',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Surah selector
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child:                   Text(
                    context.l.selectSurah,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                      fontFamily: 'Bahij Badr Light',
                    ),
                  ),
                ),
                const Divider(height: 0),
                SizedBox(
                  height: 300,
                  child: ListView.builder(
                    itemCount: surahsData.length,
                    itemBuilder: (context, index) {
                      final surahIndex = index + 1;
                      final surahData = surahsData[surahIndex];
                      if (surahData == null) return const SizedBox.shrink();

                      final isSelected = selectedSurahIndex == surahIndex;

                      return ListTile(
                        selected: isSelected,
                        selectedTileColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                        onTap: () {
                          setState(() {
                            selectedSurahIndex = surahIndex;
                            maxAyahForSelectedSurah = surahData.ayahs.length;
                            _ayahNumberController.clear();
                          });
                        },
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryGreen
                                : AppTheme.primaryGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '$surahIndex',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : AppTheme.primaryGreen,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          surahData.name,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          '${context.l.verses}: ${surahData.ayahs.length}',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle_rounded,
                                color: AppTheme.primaryGreen,
                              )
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Ayah number input
          if (selectedSurahIndex != null) ...[
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${context.l.enterAyahNumber} (1/$maxAyahForSelectedSurah)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                      fontFamily: 'Bahij Badr Light',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ayahNumberController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            hintText: '1/$maxAyahForSelectedSurah',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppTheme.primaryGreen,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          final ayahNumber = int.tryParse(_ayahNumberController.text);
                          if (ayahNumber != null &&
                              ayahNumber > 0 &&
                              ayahNumber <= maxAyahForSelectedSurah!) {
                            _navigateToAyah(selectedSurahIndex!, ayahNumber);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  context.l.ayahNumberRange.replaceAll('{min}', '1').replaceAll('{max}', '$maxAyahForSelectedSurah'),
                                  style: TextStyle(fontFamily: 'Bahij Badr Light'),
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.navigation_rounded, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              context.l.navigate,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Bahij Badr Light',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHighlightedText(String text, String query, TextStyle style) {
    if (query.isEmpty) {
      return Text(
        text,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        style: style,
      );
    }

    // Use multiple highlighting strategies for better coverage
    final spans = _createHighlightSpans(text, query, style);
    
    if (spans.isEmpty) {
      return Text(
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
      backgroundColor: AppTheme.primaryGold.withValues(alpha: 0.3),
      fontWeight: FontWeight.bold,
    );
    
    if (query.isEmpty) {
      spans.add(TextSpan(text: text, style: style));
      return spans;
    }
    
    // Try different highlighting strategies in order of preference
    List<_HighlightMatch> allMatches = [];
    
    // 1. Try exact match first (most precise)
    allMatches.addAll(_findExactMatches(text, query));
    
    // 2. If no exact matches, try case-insensitive
    if (allMatches.isEmpty) {
      allMatches.addAll(_findCaseInsensitiveMatches(text, query));
    }
    
    // 3. If still no matches, try normalized matching (without diacritics)
    if (allMatches.isEmpty) {
      allMatches.addAll(_findNormalizedMatches(text, query));
    }
    
    // 4. If still no matches, try partial matching for longer queries
    if (allMatches.isEmpty && query.length >= 3) {
      allMatches.addAll(_findPartialMatches(text, query));
    }
    
    if (allMatches.isEmpty) {
      spans.add(TextSpan(text: text, style: style));
      return spans;
    }
    
    // Sort matches by position and merge overlapping ones
    allMatches.sort((a, b) => a.start.compareTo(b.start));
    allMatches = _mergeOverlappingMatches(allMatches);
    
    // Build spans with highlighting
    int lastEnd = 0;
    
    for (final match in allMatches) {
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
  

  
  // Find exact matches
  List<_HighlightMatch> _findExactMatches(String text, String query) {
    List<_HighlightMatch> matches = [];
    int index = 0;
    
    while (index < text.length) {
      int foundIndex = text.indexOf(query, index);
      if (foundIndex == -1) break;
      
      matches.add(_HighlightMatch(foundIndex, foundIndex + query.length));
      index = foundIndex + 1;
    }
    
    return matches;
  }
  
  // Find case-insensitive matches
  List<_HighlightMatch> _findCaseInsensitiveMatches(String text, String query) {
    List<_HighlightMatch> matches = [];
    String lowerText = text.toLowerCase();
    String lowerQuery = query.toLowerCase();
    int index = 0;
    
    while (index < lowerText.length) {
      int foundIndex = lowerText.indexOf(lowerQuery, index);
      if (foundIndex == -1) break;
      
      matches.add(_HighlightMatch(foundIndex, foundIndex + query.length));
      index = foundIndex + 1;
    }
    
    return matches;
  }
  
  // Find normalized matches (without diacritics)
  List<_HighlightMatch> _findNormalizedMatches(String text, String query) {
    List<_HighlightMatch> matches = [];
    String normalizedText = _normalizeText(text);
    String normalizedQuery = _normalizeText(query);
    
    if (normalizedQuery.isEmpty) return matches;
    
    int index = 0;
    while (index < normalizedText.length) {
      int foundIndex = normalizedText.indexOf(normalizedQuery, index);
      if (foundIndex == -1) break;
      
      // Map back to original text positions
      int originalStart = _mapNormalizedToOriginal(text, normalizedText, foundIndex);
      int originalEnd = _mapNormalizedToOriginal(text, normalizedText, foundIndex + normalizedQuery.length);
      
      if (originalStart != -1 && originalEnd != -1 && originalEnd > originalStart) {
        matches.add(_HighlightMatch(originalStart, originalEnd));
      }
      
      index = foundIndex + 1;
    }
    
    return matches;
  }
  
  // Find partial matches for longer queries
  List<_HighlightMatch> _findPartialMatches(String text, String query) {
    List<_HighlightMatch> matches = [];
    
    // Try to find the longest possible substring matches
    for (int len = query.length; len >= 3; len--) {
      for (int i = 0; i <= query.length - len; i++) {
        String subQuery = query.substring(i, i + len);
        matches.addAll(_findCaseInsensitiveMatches(text, subQuery));
        
        if (matches.isNotEmpty) {
          return matches; // Return first successful partial match
        }
      }
    }
    
    return matches;
  }
  
  // Map normalized position back to original text position
  int _mapNormalizedToOriginal(String originalText, String normalizedText, int normalizedIndex) {
    int originalIndex = 0;
    int normalizedCount = 0;
    
    while (originalIndex < originalText.length && normalizedCount < normalizedIndex) {
      String char = originalText[originalIndex];
      String normalizedChar = _normalizeText(char);
      
      if (normalizedChar.isNotEmpty) {
        normalizedCount++;
      }
      originalIndex++;
    }
    
    return originalIndex;
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
  
  // Map normalized text matches back to original text positions
  List<Match> _mapNormalizedMatches(String originalText, String normalizedText, List<Match> normalizedMatches) {
    List<Match> mappedMatches = [];
    
    // Simple mapping - this is a basic implementation
    // In practice, you might need more sophisticated position mapping
    for (Match normalizedMatch in normalizedMatches) {
      String matchedText = normalizedText.substring(normalizedMatch.start, normalizedMatch.end);
      
      // Find corresponding position in original text
      int originalStart = -1;
      for (int i = 0; i <= originalText.length - matchedText.length; i++) {
        String segment = originalText.substring(i, i + matchedText.length);
        if (_normalizeText(segment) == matchedText) {
          originalStart = i;
          break;
        }
      }
      
      if (originalStart >= 0) {
        mappedMatches.add(_CustomMatch(
          originalStart,
          originalStart + matchedText.length,
        ));
      }
    }
    
    return mappedMatches;
  }
}

// Helper class for highlight matches
class _HighlightMatch {
  final int start;
  final int end;
  
  _HighlightMatch(this.start, this.end);
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

// Custom Match implementation for position mapping
class _CustomMatch implements Match {
  @override
  final int start;
  @override
  final int end;
  
  _CustomMatch(this.start, this.end);
  
  @override
  String? operator [](int group) => null;
  
  @override
  String? group(int group) => null;
  
  @override
  int get groupCount => 0;
  
  @override
  List<String?> groups(List<int> groupIndices) => [];
  
  @override
  String get input => '';
  
  @override
  Pattern get pattern => RegExp('');
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