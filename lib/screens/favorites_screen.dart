import '../widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:xml/xml.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../themes/app_theme.dart';
import '../services/favorites_service.dart';
import '../services/notes_service.dart';
import '../localization/app_localizations_extension.dart';
import '../providers/font_provider.dart';
import 'quran_reader_screen.dart';
import 'quran_navigation_screen.dart';
import '../utils/theme_extensions.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  Map<int, String> _surahNames = {};
  Map<int, Map<int, String>> _ayahTexts = {}; // surahIndex -> ayahIndex -> text
  Map<int, Map<int, String>> _translations = {}; // surahIndex -> ayahIndex -> translation
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuranData();
  }

  Future<void> _loadQuranData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load Arabic text data (same as Quran reader screen)
      final String arabicData = await rootBundle.loadString('assets/quran_data/quran_arabic.xml');
      final arabicDocument = XmlDocument.parse(arabicData);

      for (var suraElement in arabicDocument.findAllElements('sura')) {
        int surahIndex = int.parse(suraElement.getAttribute('index')!);
        String surahName = suraElement.getAttribute('name') ?? 'Surah $surahIndex';
        
        _surahNames[surahIndex] = surahName;
        _ayahTexts[surahIndex] = {};
        
        for (var ayaElement in suraElement.findAllElements('aya')) {
          int ayahIndex = int.parse(ayaElement.getAttribute('index')!);
          String ayahText = ayaElement.getAttribute('text') ?? '';
          _ayahTexts[surahIndex]![ayahIndex] = ayahText;
        }
      }

      // Load Pashto translation data (same as Quran reader screen)
      try {
        final String translationData = await rootBundle.loadString('assets/quran_data/quran_tr_ps.xml');
        final translationDocument = XmlDocument.parse(translationData);

        for (var suraElement in translationDocument.findAllElements('sura')) {
          int surahIndex = int.parse(suraElement.getAttribute('index')!);
          _translations[surahIndex] = {};
          
          for (var ayaElement in suraElement.findAllElements('aya')) {
            int ayahIndex = int.parse(ayaElement.getAttribute('index')!);
            String translation = ayaElement.getAttribute('text') ?? '';
            _translations[surahIndex]![ayahIndex] = translation;
          }
        }
      } catch (e) {
        debugPrint('Translation loading failed: $e');
      }
      
      debugPrint('Favorites: Loaded ${_surahNames.length} surahs with ${_ayahTexts.values.fold(0, (sum, surah) => sum + surah.length)} ayahs');
    } catch (e) {
      debugPrint('Error loading Quran data: $e');
    }
    
    setState(() => _isLoading = false);
  }

  String _getSurahName(int surahIndex) {
    return _surahNames[surahIndex] ?? 'Surah $surahIndex';
  }

  String _getAyahAppText(int surahIndex, int ayahIndex) {
    final text = _ayahTexts[surahIndex]?[ayahIndex] ?? '';
    if (text.isEmpty) {
      debugPrint('Favorites: No Arabic text found for Surah $surahIndex, Ayah $ayahIndex');
    }
    return text;
  }

  String _getTranslation(int surahIndex, int ayahIndex) {
    return _translations[surahIndex]?[ayahIndex] ?? '';
  }

  String _getParaName(int paraNumber) {
    final paraNames = {
      1: 'الم', 2: 'سيقول السفهاء', 3: 'تلك الرسل', 4: 'لن تنالوا البر',
      5: 'والمحصنات', 6: 'لا يحب الله', 7: 'وإذا سمعوا', 8: 'ولو أننا',
      9: 'قال الملأ', 10: 'واعلموا', 11: 'يعتذرون', 12: 'وما من دابة',
      13: 'وما أبرئ', 14: 'ربما', 15: 'سبحان الذي', 16: 'قال ألم',
      17: 'اقترب للناس', 18: 'قد أفلح', 19: 'وقال الذين', 20: 'أمن خلق',
      21: 'اتل ما أوحي', 22: 'ومن يقنت', 23: 'وما لي', 24: 'فمن أظلم',
      25: 'إليه يرد', 26: 'حم', 27: 'قال فما خطبكم', 28: 'قد سمع',
      29: 'تبارك الذي', 30: 'عم'
    };
    
    return paraNames[paraNumber] ?? 'Para $paraNumber';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? context.backgroundColor : context.backgroundColor,
      appBar: AppBar(
        title: AppText(context.l.favorites ?? 'Favorites'),
        backgroundColor: context.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? _buildLoadingIndicator(isDark)
          : _buildFavoritesList(isDark),
    );
  }

  Widget _buildLoadingIndicator(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(context.primaryColor),
          ),
          const SizedBox(height: 16),
          AppText(
            context.l.loading ?? 'Loading...',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList(bool isDark) {
    return FutureBuilder<List<FavoriteAyah>>(
      future: FavoritesService.getAllFavorites(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: Colors.red, size: 48),
                SizedBox(height: 16),
                AppText('Error loading favorites: ${snapshot.error}'),
              ],
            ),
          );
        }
        
        if (!snapshot.hasData) {
          return _buildLoadingIndicator(isDark);
        }

        final favorites = snapshot.data!;
        
        if (favorites.isEmpty) {
          return _buildEmptyState(isDark);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: favorites.length,
          itemBuilder: (context, index) {
            final favorite = favorites[index];
            return _buildFavoriteAyahCard(favorite, isDark);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark 
                    ? context.primaryColor.withValues(alpha: 0.1)
                    : context.primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: context.primaryColor.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.favorite_border_rounded,
            size: 80,
                color: context.primaryColor,
              ),
          ),
            const SizedBox(height: 24),
          AppText(
            context.l.noFavorites ?? 'No favorite ayahs yet',
            style: TextStyle(
                fontSize: 22,
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isDark 
                    ? context.primaryColor.withValues(alpha: 0.1)
                    : context.primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: context.primaryColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: context.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: AppText(
            context.l.addFavoritesFromReader ?? 'Add favorites from the Quran reader',
            style: TextStyle(
                        fontSize: 15,
                        color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
            ),
            textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const QuranNavigationScreen(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(25),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      context.primaryColor,
                      context.primaryColor.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: context.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.menu_book_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    AppText(
                      'Start Reading Quran',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
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
  }

  Widget _buildFavoriteAyahCard(FavoriteAyah favorite, bool isDark) {
    return Consumer<FontProvider>(
      builder: (context, fontProvider, child) {
        final ayahText = _getAyahAppText(favorite.surahIndex, favorite.ayahIndex);
        final translation = _getTranslation(favorite.surahIndex, favorite.ayahIndex);
        final surahName = _getSurahName(favorite.surahIndex);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? context.surfaceColor : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark 
              ? context.primaryColor.withValues(alpha: 0.2)
              : context.primaryColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with surah name and ayah number
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          context.primaryColor.withValues(alpha: 0.15),
                          context.primaryColor.withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: context.primaryColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.menu_book_rounded,
                          color: context.primaryColor,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                  child: AppText(
                            '$surahName',
                    style: TextStyle(
                              fontSize: 14,
                      color: context.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                            color: context.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: AppText(
                            '${favorite.ayahIndex}',
                            style: const TextStyle(
                      fontSize: 12,
                              color: Colors.white,
                      fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Arabic text - Enhanced display
            if (ayahText.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark 
                        ? [
                            context.primaryColor.withValues(alpha: 0.12),
                            context.primaryColor.withValues(alpha: 0.06),
                          ]
                        : [
                            context.primaryColor.withValues(alpha: 0.08),
                            context.primaryColor.withValues(alpha: 0.03),
                          ],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: context.primaryColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppText(
                      ayahText.isNotEmpty ? ayahText : 'آیت متن دستیاب نہیں',
                  style: TextStyle(
                        fontSize: 16,
                    color: isDark ? Colors.white : Colors.black87,
                    fontFamily: fontProvider.selectedArabicFont,
                        height: 2.0,
                        fontWeight: FontWeight.w500,
                  ),
                  textDirection: TextDirection.rtl,
                      textAlign: TextAlign.justify,
                    ),
                    if (ayahText.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: AppText(
                          'Arabic text not loaded',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.withValues(alpha: 0.7),
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red,
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    AppText(
                      'Arabic text not available',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            
            // Translation
            if (translation.isNotEmpty) ...[
            const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark 
                      ? context.primaryColor.withValues(alpha: 0.08)
                      : context.primaryColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: context.primaryColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: AppText(
                translation,
                style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
                    height: 1.5,
                ),
                textDirection: TextDirection.rtl,
                  textAlign: TextAlign.justify,
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Action buttons row - Compact design
            Row(
              children: [
                // Notes button - Compact
                Expanded(
                  child: FutureBuilder<bool>(
                    future: NotesService.hasNote(favorite.surahIndex, favorite.ayahIndex),
                    builder: (context, snapshot) {
                      final hasNote = snapshot.data ?? false;
                      return Container(
                        height: 36,
                        child: ElevatedButton.icon(
                          onPressed: () => _showNotesDialog(favorite, isDark),
                          icon: Icon(
                            hasNote ? Icons.edit_note : Icons.note_add,
                            size: 14,
                            color: Colors.white,
                          ),
                          label: AppText(
                            hasNote ? 'Note' : 'Note',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: hasNote ? context.primaryColor : Colors.grey[600],
                            foregroundColor: Colors.white,
                            elevation: 1,
                            shadowColor: (hasNote ? context.primaryColor : Colors.grey[600])?.withValues(alpha: 0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(width: 6),
                
                // Remove favorite button - Compact
                Container(
                  height: 36,
                  child: ElevatedButton.icon(
                    onPressed: () => _removeFavorite(favorite),
                    icon: const Icon(
                      Icons.favorite,
                      size: 14,
                      color: Colors.white,
                    ),
                    label: const AppText(
                      'Remove',
                style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      foregroundColor: Colors.white,
                      elevation: 1,
                      shadowColor: Colors.red.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                  ),
                ),
                
                const SizedBox(width: 6),
                
                // Navigate button - Compact
                Container(
                  height: 36,
                  width: 36,
                  child: ElevatedButton(
                    onPressed: () => _navigateToAyah(favorite),
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.white,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 1,
                      shadowColor: context.primaryColor.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
            
            // Notes preview
            FutureBuilder<String?>(
              future: NotesService.getNote(favorite.surahIndex, favorite.ayahIndex),
              builder: (context, snapshot) {
                final note = snapshot.data;
                if (note != null && note.isNotEmpty) {
                  return Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark 
                          ? context.primaryColor.withValues(alpha: 0.1)
                          : context.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: context.primaryColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: context.primaryColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                          Icons.note,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                'Your Note:',
                                style: TextStyle(
                                  fontSize: 11,
                          color: context.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                        ),
                              const SizedBox(height: 2),
                              AppText(
                            note,
                            style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
                                  height: 1.3,
                            ),
                                maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
      },
    );
  }

  void _removeFavorite(FavoriteAyah favorite) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? context.surfaceColor : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppText(
                context.l.removeFavorite ?? 'Remove Favorite',
                style: TextStyle(
                  fontSize: 18,
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              context.l.removeFavoriteConfirm ?? 'Are you sure you want to remove this ayah from favorites?',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark 
                    ? context.primaryColor.withValues(alpha: 0.1)
                    : context.primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: context.primaryColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    color: context.primaryColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppText(
                      '${_getSurahName(favorite.surahIndex)} - Ayah ${favorite.ayahIndex}',
                      style: TextStyle(
                        fontSize: 14,
                        color: context.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            height: 40,
            child: TextButton(
            onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(
                foregroundColor: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black54,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: AppText(
                context.l.cancel ?? 'Cancel',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 40,
            child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
              icon: const Icon(
                Icons.delete_outline,
                size: 18,
                color: Colors.white,
              ),
              label: AppText(
                context.l.remove ?? 'Remove',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                elevation: 2,
                shadowColor: Colors.red.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    
    if (result == true) {
      await FavoritesService.removeFromFavorites(favorite.surahIndex, favorite.ayahIndex);
      setState(() {}); // Refresh the list
      
      // Show success snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                AppText(
                  context.l.removedFromFavorites ?? 'Removed from favorites',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            backgroundColor: context.primaryColor,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _navigateToAyah(FavoriteAyah favorite) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuranReaderScreen(
          surahIndex: favorite.surahIndex,
          surahName: _getSurahName(favorite.surahIndex),
          initialAyahIndex: favorite.ayahIndex,
          highlightInitialAyah: true, // Highlight favorited ayah
        ),
      ),
    );
  }

  void _showNotesDialog(FavoriteAyah favorite, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => NotesDialog(
        surahIndex: favorite.surahIndex,
        ayahIndex: favorite.ayahIndex,
        surahName: _getSurahName(favorite.surahIndex),
        onNoteSaved: () => setState(() {}), // Refresh to show note preview
      ),
    );
  }
}

class NotesDialog extends StatefulWidget {
  final int surahIndex;
  final int ayahIndex;
  final String surahName;
  final VoidCallback onNoteSaved;

  const NotesDialog({
    super.key,
    required this.surahIndex,
    required this.ayahIndex,
    required this.surahName,
    required this.onNoteSaved,
  });

  @override
  State<NotesDialog> createState() => _NotesDialogState();
}

class _NotesDialogState extends State<NotesDialog> {
  late TextEditingController _noteController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
    _loadNote();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _loadNote() async {
    final note = await NotesService.getNote(widget.surahIndex, widget.ayahIndex);
    if (mounted) {
      setState(() {
        _noteController.text = note ?? '';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: AppText(
        '${widget.surahName} - آیت ${widget.ayahIndex}',
        style: const TextStyle(
                      fontWeight: FontWeight.bold,
        ),
      ),
      content: _isLoading
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : SizedBox(
              width: double.maxFinite,
              height: 200,
              child: TextField(
                controller: _noteController,
                maxLines: null,
                expands: true,
                decoration: InputDecoration(
                  hintText: context.l.addNote ?? 'Add your note here...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: AppText(context.l.cancel ?? 'Cancel'),
        ),
        if (!_isLoading)
          TextButton(
            onPressed: () async {
              await NotesService.addNote(
                widget.surahIndex,
                widget.ayahIndex,
                _noteController.text,
              );
              widget.onNoteSaved();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: AppText(
                      _noteController.text.trim().isEmpty
                          ? (context.l.noteRemoved ?? 'Note removed')
                          : (context.l.noteSaved ?? 'Note saved'),
                    ),
                    backgroundColor: context.primaryColor,
                  ),
                );
              }
            },
            child: AppText(context.l.save ?? 'Save'),
          ),
      ],
    );
  }
}
