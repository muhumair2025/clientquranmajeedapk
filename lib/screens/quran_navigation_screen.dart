import 'package:flutter/material.dart';
import '../themes/app_theme.dart';
import 'quran_reader_screen.dart';

class QuranNavigationScreen extends StatefulWidget {
  const QuranNavigationScreen({super.key});

  @override
  State<QuranNavigationScreen> createState() => _QuranNavigationScreenState();
}

class _QuranNavigationScreenState extends State<QuranNavigationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1); // Start with Surah tab
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        title: const Text('قرآن کریم'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Custom Tab Bar with search
          Container(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            child: Column(
              children: [
                // Tab selector
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
                                  'پاړې',
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
                                  'سورتونه',
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
                // Search box
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkBackground : AppTheme.lightGray,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      textDirection: TextDirection.rtl,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'د سورت لټون وکړئ',
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 16,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: AppTheme.primaryGreen,
                          size: 24,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
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
                _buildParaTab(),
                _buildSurahTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParaTab() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 30, // 30 Para
      itemBuilder: (context, index) {
        final paraNumber = index + 1;
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
              onTap: () {
                // Navigate to Para reading screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuranReaderScreen(
                      surahIndex: 1, // For now, use first surah for para navigation
                      paraIndex: paraNumber,
                      paraName: _getParaName(paraNumber),
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Para number on the left
                    Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '$paraNumber',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Para content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Para name on the right side (RTL)
                          Container(
                            height: 30,
                            alignment: Alignment.centerRight,
                            child: ColorFiltered(
                              colorFilter: isDark 
                                  ? const ColorFilter.mode(Colors.white, BlendMode.srcIn)
                                  : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                              child: Image.asset(
                                'assets/drawable/para_$paraNumber.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Text(
                                    _getParaName(paraNumber),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black,
                                    ),
                                    textDirection: TextDirection.rtl,
                                    textAlign: TextAlign.right,
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Ayah count
                          Text(
                            'آیتونه ${_getParaAyahCount(paraNumber)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white60 : Colors.grey[600],
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Para emoji indicator on the right side
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getParaEmoji(paraNumber),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSurahTab() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Filter surahs based on search query
    final filteredSurahs = _getSurahList()
        .where((surah) => _searchQuery.isEmpty || 
            surah['name'].toString().contains(_searchQuery) ||
            surah['transliteration'].toString().toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredSurahs.length,
      itemBuilder: (context, index) {
        final surah = filteredSurahs[index];
        final surahNumber = surah['number'] as int;
        
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuranReaderScreen(
                      surahIndex: surahNumber,
                      surahName: surah['name'],
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Surah number on the left
                    Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '$surahNumber',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Surah content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Surah name on the right side (RTL)
                          Container(
                            height: 30,
                            alignment: Alignment.centerRight,
                            child: ColorFiltered(
                              colorFilter: isDark 
                                  ? const ColorFilter.mode(Colors.white, BlendMode.srcIn)
                                  : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                              child: Image.asset(
                                'assets/drawable/sname_$surahNumber.webp',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Text(
                                    surah['name'],
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black,
                                    ),
                                    textDirection: TextDirection.rtl,
                                    textAlign: TextAlign.right,
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Ayah count
                          Text(
                            'آیتونه ${surah['ayahCount']}',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white60 : Colors.grey[600],
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Makki/Madani indicator on the right side
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: surah['isMakki'] 
                            ? Colors.orange.withValues(alpha: 0.1)
                            : Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        surah['isMakki'] ? '🕋' : '🕌',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getParaName(int paraNumber) {
    final paraNames = [
      'الم', 'سَيَقُولُ', 'تِلْكَ الرُّسُلُ', 'لَن تَنَالُوا', 'وَالْمُحْصَنَاتُ',
      'لَا يُحِبُّ اللَّهُ', 'وَإِذَا سَمِعُوا', 'وَلَوْ أَنَّنَا', 'قَالَ الْمَلَأُ', 'وَاعْلَمُوا',
      'يَعْتَذِرُونَ', 'وَمَا مِن دَابَّةٍ', 'وَمَا أُبَرِّئُ', 'رُبَمَا', 'سُبْحَانَ الَّذِي',
      'قَالَ أَلَمْ', 'اقْتَرَبَ لِلنَّاسِ', 'قَدْ أَفْلَحَ', 'وَقَالَ الَّذِينَ', 'أَمَّنْ خَلَقَ',
      'اتْلُ مَا أُوحِيَ', 'وَمَن يَقْنُتْ', 'وَمَا لِيَ', 'فَمَنْ أَظْلَمُ', 'إِلَيْهِ يُرَدُّ',
      'حم', 'قَالَ فَمَا خَطْبُكُمْ', 'قَدْ سَمِعَ اللَّهُ', 'تَبَارَكَ الَّذِي', 'عَمَّ'
    ];
    return paraNames[paraNumber - 1];
  }

  String _getParaEmoji(int paraNumber) {
    return '📖'; // Same book emoji for all Paras
  }

  int _getParaAyahCount(int paraNumber) {
    // Approximate ayah counts for each para
    final ayahCounts = [
      148, 111, 126, 131, 124, 110, 149, 142, 159, 128,
      123, 133, 154, 227, 185, 269, 190, 206, 188, 172,
      171, 140, 140, 159, 201, 185, 250, 125, 154, 564
    ];
    return ayahCounts[paraNumber - 1];
  }

  List<Map<String, dynamic>> _getSurahList() {
    return [
      {'number': 1, 'name': 'الفاتحة', 'transliteration': 'Al-Fatihah', 'ayahCount': 7, 'pageNumber': 1, 'isMakki': true},
      {'number': 2, 'name': 'البقرة', 'transliteration': 'Al-Baqarah', 'ayahCount': 286, 'pageNumber': 2, 'isMakki': false},
      {'number': 3, 'name': 'آل عمران', 'transliteration': 'Aal-E-Imran', 'ayahCount': 200, 'pageNumber': 50, 'isMakki': false},
      {'number': 4, 'name': 'النساء', 'transliteration': 'An-Nisa', 'ayahCount': 176, 'pageNumber': 77, 'isMakki': false},
      {'number': 5, 'name': 'المائدة', 'transliteration': 'Al-Maidah', 'ayahCount': 120, 'pageNumber': 106, 'isMakki': false},
      {'number': 6, 'name': 'الأنعام', 'transliteration': 'Al-Anam', 'ayahCount': 165, 'pageNumber': 128, 'isMakki': true},
      {'number': 7, 'name': 'الأعراف', 'transliteration': 'Al-Araf', 'ayahCount': 206, 'pageNumber': 151, 'isMakki': true},
      {'number': 8, 'name': 'الأنفال', 'transliteration': 'Al-Anfal', 'ayahCount': 75, 'pageNumber': 177, 'isMakki': false},
      {'number': 9, 'name': 'التوبة', 'transliteration': 'At-Tawbah', 'ayahCount': 129, 'pageNumber': 187, 'isMakki': false},
      {'number': 10, 'name': 'يونس', 'transliteration': 'Yunus', 'ayahCount': 109, 'pageNumber': 208, 'isMakki': true},
      {'number': 11, 'name': 'هود', 'transliteration': 'Hud', 'ayahCount': 123, 'pageNumber': 221, 'isMakki': true},
      {'number': 12, 'name': 'يوسف', 'transliteration': 'Yusuf', 'ayahCount': 111, 'pageNumber': 235, 'isMakki': true},
      {'number': 13, 'name': 'الرعد', 'transliteration': 'Ar-Rad', 'ayahCount': 43, 'pageNumber': 249, 'isMakki': false},
      {'number': 14, 'name': 'إبراهيم', 'transliteration': 'Ibrahim', 'ayahCount': 52, 'pageNumber': 255, 'isMakki': true},
      {'number': 15, 'name': 'الحجر', 'transliteration': 'Al-Hijr', 'ayahCount': 99, 'pageNumber': 262, 'isMakki': true},
      {'number': 16, 'name': 'النحل', 'transliteration': 'An-Nahl', 'ayahCount': 128, 'pageNumber': 267, 'isMakki': true},
      {'number': 17, 'name': 'الإسراء', 'transliteration': 'Al-Isra', 'ayahCount': 111, 'pageNumber': 282, 'isMakki': true},
      {'number': 18, 'name': 'الكهف', 'transliteration': 'Al-Kahf', 'ayahCount': 110, 'pageNumber': 293, 'isMakki': true},
      {'number': 19, 'name': 'مريم', 'transliteration': 'Maryam', 'ayahCount': 98, 'pageNumber': 305, 'isMakki': true},
      {'number': 20, 'name': 'طه', 'transliteration': 'Taha', 'ayahCount': 135, 'pageNumber': 312, 'isMakki': true},
      {'number': 21, 'name': 'الأنبياء', 'transliteration': 'Al-Anbiya', 'ayahCount': 112, 'pageNumber': 322, 'isMakki': true},
      {'number': 22, 'name': 'الحج', 'transliteration': 'Al-Hajj', 'ayahCount': 78, 'pageNumber': 332, 'isMakki': false},
      {'number': 23, 'name': 'المؤمنون', 'transliteration': 'Al-Muminun', 'ayahCount': 118, 'pageNumber': 342, 'isMakki': true},
      {'number': 24, 'name': 'النور', 'transliteration': 'An-Nur', 'ayahCount': 64, 'pageNumber': 350, 'isMakki': false},
      {'number': 25, 'name': 'الفرقان', 'transliteration': 'Al-Furqan', 'ayahCount': 77, 'pageNumber': 359, 'isMakki': true},
      {'number': 26, 'name': 'الشعراء', 'transliteration': 'Ash-Shuara', 'ayahCount': 227, 'pageNumber': 367, 'isMakki': true},
      {'number': 27, 'name': 'النمل', 'transliteration': 'An-Naml', 'ayahCount': 93, 'pageNumber': 377, 'isMakki': true},
      {'number': 28, 'name': 'القصص', 'transliteration': 'Al-Qasas', 'ayahCount': 88, 'pageNumber': 385, 'isMakki': true},
      {'number': 29, 'name': 'العنكبوت', 'transliteration': 'Al-Ankabut', 'ayahCount': 69, 'pageNumber': 396, 'isMakki': true},
      {'number': 30, 'name': 'الروم', 'transliteration': 'Ar-Rum', 'ayahCount': 60, 'pageNumber': 404, 'isMakki': true},
      {'number': 31, 'name': 'لقمان', 'transliteration': 'Luqman', 'ayahCount': 34, 'pageNumber': 411, 'isMakki': true},
      {'number': 32, 'name': 'السجدة', 'transliteration': 'As-Sajdah', 'ayahCount': 30, 'pageNumber': 415, 'isMakki': true},
      {'number': 33, 'name': 'الأحزاب', 'transliteration': 'Al-Ahzab', 'ayahCount': 73, 'pageNumber': 418, 'isMakki': false},
      {'number': 34, 'name': 'سبأ', 'transliteration': 'Saba', 'ayahCount': 54, 'pageNumber': 428, 'isMakki': true},
      {'number': 35, 'name': 'فاطر', 'transliteration': 'Fatir', 'ayahCount': 45, 'pageNumber': 434, 'isMakki': true},
      {'number': 36, 'name': 'يس', 'transliteration': 'Ya-Sin', 'ayahCount': 83, 'pageNumber': 440, 'isMakki': true},
      {'number': 37, 'name': 'الصافات', 'transliteration': 'As-Saffat', 'ayahCount': 182, 'pageNumber': 446, 'isMakki': true},
      {'number': 38, 'name': 'ص', 'transliteration': 'Sad', 'ayahCount': 88, 'pageNumber': 453, 'isMakki': true},
      {'number': 39, 'name': 'الزمر', 'transliteration': 'Az-Zumar', 'ayahCount': 75, 'pageNumber': 458, 'isMakki': true},
      {'number': 40, 'name': 'غافر', 'transliteration': 'Ghafir', 'ayahCount': 85, 'pageNumber': 467, 'isMakki': true},
      {'number': 41, 'name': 'فصلت', 'transliteration': 'Fussilat', 'ayahCount': 54, 'pageNumber': 477, 'isMakki': true},
      {'number': 42, 'name': 'الشورى', 'transliteration': 'Ash-Shura', 'ayahCount': 53, 'pageNumber': 483, 'isMakki': true},
      {'number': 43, 'name': 'الزخرف', 'transliteration': 'Az-Zukhruf', 'ayahCount': 89, 'pageNumber': 489, 'isMakki': true},
      {'number': 44, 'name': 'الدخان', 'transliteration': 'Ad-Dukhan', 'ayahCount': 59, 'pageNumber': 496, 'isMakki': true},
      {'number': 45, 'name': 'الجاثية', 'transliteration': 'Al-Jathiyah', 'ayahCount': 37, 'pageNumber': 499, 'isMakki': true},
      {'number': 46, 'name': 'الأحقاف', 'transliteration': 'Al-Ahqaf', 'ayahCount': 35, 'pageNumber': 502, 'isMakki': true},
      {'number': 47, 'name': 'محمد', 'transliteration': 'Muhammad', 'ayahCount': 38, 'pageNumber': 507, 'isMakki': false},
      {'number': 48, 'name': 'الفتح', 'transliteration': 'Al-Fath', 'ayahCount': 29, 'pageNumber': 511, 'isMakki': false},
      {'number': 49, 'name': 'الحجرات', 'transliteration': 'Al-Hujurat', 'ayahCount': 18, 'pageNumber': 515, 'isMakki': false},
      {'number': 50, 'name': 'ق', 'transliteration': 'Qaf', 'ayahCount': 45, 'pageNumber': 518, 'isMakki': true},
      {'number': 51, 'name': 'الذاريات', 'transliteration': 'Adh-Dhariyat', 'ayahCount': 60, 'pageNumber': 520, 'isMakki': true},
      {'number': 52, 'name': 'الطور', 'transliteration': 'At-Tur', 'ayahCount': 49, 'pageNumber': 523, 'isMakki': true},
      {'number': 53, 'name': 'النجم', 'transliteration': 'An-Najm', 'ayahCount': 62, 'pageNumber': 526, 'isMakki': true},
      {'number': 54, 'name': 'القمر', 'transliteration': 'Al-Qamar', 'ayahCount': 55, 'pageNumber': 528, 'isMakki': true},
      {'number': 55, 'name': 'الرحمن', 'transliteration': 'Ar-Rahman', 'ayahCount': 78, 'pageNumber': 531, 'isMakki': true},
      {'number': 56, 'name': 'الواقعة', 'transliteration': 'Al-Waqiah', 'ayahCount': 96, 'pageNumber': 534, 'isMakki': true},
      {'number': 57, 'name': 'الحديد', 'transliteration': 'Al-Hadid', 'ayahCount': 29, 'pageNumber': 537, 'isMakki': false},
      {'number': 58, 'name': 'المجادلة', 'transliteration': 'Al-Mujadila', 'ayahCount': 22, 'pageNumber': 542, 'isMakki': false},
      {'number': 59, 'name': 'الحشر', 'transliteration': 'Al-Hashr', 'ayahCount': 24, 'pageNumber': 545, 'isMakki': false},
      {'number': 60, 'name': 'الممتحنة', 'transliteration': 'Al-Mumtahanah', 'ayahCount': 13, 'pageNumber': 549, 'isMakki': false},
      {'number': 61, 'name': 'الصف', 'transliteration': 'As-Saff', 'ayahCount': 14, 'pageNumber': 551, 'isMakki': false},
      {'number': 62, 'name': 'الجمعة', 'transliteration': 'Al-Jumuah', 'ayahCount': 11, 'pageNumber': 553, 'isMakki': false},
      {'number': 63, 'name': 'المنافقون', 'transliteration': 'Al-Munafiqun', 'ayahCount': 11, 'pageNumber': 554, 'isMakki': false},
      {'number': 64, 'name': 'التغابن', 'transliteration': 'At-Taghabun', 'ayahCount': 18, 'pageNumber': 556, 'isMakki': false},
      {'number': 65, 'name': 'الطلاق', 'transliteration': 'At-Talaq', 'ayahCount': 12, 'pageNumber': 558, 'isMakki': false},
      {'number': 66, 'name': 'التحريم', 'transliteration': 'At-Tahrim', 'ayahCount': 12, 'pageNumber': 560, 'isMakki': false},
      {'number': 67, 'name': 'الملك', 'transliteration': 'Al-Mulk', 'ayahCount': 30, 'pageNumber': 562, 'isMakki': true},
      {'number': 68, 'name': 'القلم', 'transliteration': 'Al-Qalam', 'ayahCount': 52, 'pageNumber': 564, 'isMakki': true},
      {'number': 69, 'name': 'الحاقة', 'transliteration': 'Al-Haqqah', 'ayahCount': 52, 'pageNumber': 566, 'isMakki': true},
      {'number': 70, 'name': 'المعارج', 'transliteration': 'Al-Maarij', 'ayahCount': 44, 'pageNumber': 568, 'isMakki': true},
      {'number': 71, 'name': 'نوح', 'transliteration': 'Nuh', 'ayahCount': 28, 'pageNumber': 570, 'isMakki': true},
      {'number': 72, 'name': 'الجن', 'transliteration': 'Al-Jinn', 'ayahCount': 28, 'pageNumber': 572, 'isMakki': true},
      {'number': 73, 'name': 'المزمل', 'transliteration': 'Al-Muzzammil', 'ayahCount': 20, 'pageNumber': 574, 'isMakki': true},
      {'number': 74, 'name': 'المدثر', 'transliteration': 'Al-Muddaththir', 'ayahCount': 56, 'pageNumber': 575, 'isMakki': true},
      {'number': 75, 'name': 'القيامة', 'transliteration': 'Al-Qiyamah', 'ayahCount': 40, 'pageNumber': 577, 'isMakki': true},
      {'number': 76, 'name': 'الإنسان', 'transliteration': 'Al-Insan', 'ayahCount': 31, 'pageNumber': 578, 'isMakki': false},
      {'number': 77, 'name': 'المرسلات', 'transliteration': 'Al-Mursalat', 'ayahCount': 50, 'pageNumber': 580, 'isMakki': true},
      {'number': 78, 'name': 'النبأ', 'transliteration': 'An-Naba', 'ayahCount': 40, 'pageNumber': 582, 'isMakki': true},
      {'number': 79, 'name': 'النازعات', 'transliteration': 'An-Naziat', 'ayahCount': 46, 'pageNumber': 583, 'isMakki': true},
      {'number': 80, 'name': 'عبس', 'transliteration': 'Abasa', 'ayahCount': 42, 'pageNumber': 585, 'isMakki': true},
      {'number': 81, 'name': 'التكوير', 'transliteration': 'At-Takwir', 'ayahCount': 29, 'pageNumber': 586, 'isMakki': true},
      {'number': 82, 'name': 'الانفطار', 'transliteration': 'Al-Infitar', 'ayahCount': 19, 'pageNumber': 587, 'isMakki': true},
      {'number': 83, 'name': 'المطففين', 'transliteration': 'Al-Mutaffifin', 'ayahCount': 36, 'pageNumber': 587, 'isMakki': true},
      {'number': 84, 'name': 'الانشقاق', 'transliteration': 'Al-Inshiqaq', 'ayahCount': 25, 'pageNumber': 589, 'isMakki': true},
      {'number': 85, 'name': 'البروج', 'transliteration': 'Al-Buruj', 'ayahCount': 22, 'pageNumber': 590, 'isMakki': true},
      {'number': 86, 'name': 'الطارق', 'transliteration': 'At-Tariq', 'ayahCount': 17, 'pageNumber': 591, 'isMakki': true},
      {'number': 87, 'name': 'الأعلى', 'transliteration': 'Al-Ala', 'ayahCount': 19, 'pageNumber': 591, 'isMakki': true},
      {'number': 88, 'name': 'الغاشية', 'transliteration': 'Al-Ghashiyah', 'ayahCount': 26, 'pageNumber': 592, 'isMakki': true},
      {'number': 89, 'name': 'الفجر', 'transliteration': 'Al-Fajr', 'ayahCount': 30, 'pageNumber': 593, 'isMakki': true},
      {'number': 90, 'name': 'البلد', 'transliteration': 'Al-Balad', 'ayahCount': 20, 'pageNumber': 594, 'isMakki': true},
      {'number': 91, 'name': 'الشمس', 'transliteration': 'Ash-Shams', 'ayahCount': 15, 'pageNumber': 595, 'isMakki': true},
      {'number': 92, 'name': 'الليل', 'transliteration': 'Al-Layl', 'ayahCount': 21, 'pageNumber': 595, 'isMakki': true},
      {'number': 93, 'name': 'الضحى', 'transliteration': 'Ad-Duhaa', 'ayahCount': 11, 'pageNumber': 596, 'isMakki': true},
      {'number': 94, 'name': 'الشرح', 'transliteration': 'Ash-Sharh', 'ayahCount': 8, 'pageNumber': 596, 'isMakki': true},
      {'number': 95, 'name': 'التين', 'transliteration': 'At-Tin', 'ayahCount': 8, 'pageNumber': 597, 'isMakki': true},
      {'number': 96, 'name': 'العلق', 'transliteration': 'Al-Alaq', 'ayahCount': 19, 'pageNumber': 597, 'isMakki': true},
      {'number': 97, 'name': 'القدر', 'transliteration': 'Al-Qadr', 'ayahCount': 5, 'pageNumber': 598, 'isMakki': true},
      {'number': 98, 'name': 'البينة', 'transliteration': 'Al-Bayyinah', 'ayahCount': 8, 'pageNumber': 598, 'isMakki': false},
      {'number': 99, 'name': 'الزلزلة', 'transliteration': 'Az-Zalzalah', 'ayahCount': 8, 'pageNumber': 599, 'isMakki': false},
      {'number': 100, 'name': 'العاديات', 'transliteration': 'Al-Adiyat', 'ayahCount': 11, 'pageNumber': 599, 'isMakki': true},
      {'number': 101, 'name': 'القارعة', 'transliteration': 'Al-Qariah', 'ayahCount': 11, 'pageNumber': 600, 'isMakki': true},
      {'number': 102, 'name': 'التكاثر', 'transliteration': 'At-Takathur', 'ayahCount': 8, 'pageNumber': 600, 'isMakki': true},
      {'number': 103, 'name': 'العصر', 'transliteration': 'Al-Asr', 'ayahCount': 3, 'pageNumber': 601, 'isMakki': true},
      {'number': 104, 'name': 'الهمزة', 'transliteration': 'Al-Humazah', 'ayahCount': 9, 'pageNumber': 601, 'isMakki': true},
      {'number': 105, 'name': 'الفيل', 'transliteration': 'Al-Fil', 'ayahCount': 5, 'pageNumber': 601, 'isMakki': true},
      {'number': 106, 'name': 'قريش', 'transliteration': 'Quraysh', 'ayahCount': 4, 'pageNumber': 602, 'isMakki': true},
      {'number': 107, 'name': 'الماعون', 'transliteration': 'Al-Maun', 'ayahCount': 7, 'pageNumber': 602, 'isMakki': true},
      {'number': 108, 'name': 'الكوثر', 'transliteration': 'Al-Kawthar', 'ayahCount': 3, 'pageNumber': 602, 'isMakki': true},
      {'number': 109, 'name': 'الكافرون', 'transliteration': 'Al-Kafirun', 'ayahCount': 6, 'pageNumber': 603, 'isMakki': true},
      {'number': 110, 'name': 'النصر', 'transliteration': 'An-Nasr', 'ayahCount': 3, 'pageNumber': 603, 'isMakki': false},
      {'number': 111, 'name': 'المسد', 'transliteration': 'Al-Masad', 'ayahCount': 5, 'pageNumber': 603, 'isMakki': true},
      {'number': 112, 'name': 'الإخلاص', 'transliteration': 'Al-Ikhlas', 'ayahCount': 4, 'pageNumber': 604, 'isMakki': true},
      {'number': 113, 'name': 'الفلق', 'transliteration': 'Al-Falaq', 'ayahCount': 5, 'pageNumber': 604, 'isMakki': true},
      {'number': 114, 'name': 'الناس', 'transliteration': 'An-Nas', 'ayahCount': 6, 'pageNumber': 604, 'isMakki': true},
    ];
  }
} 