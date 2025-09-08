import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../themes/app_theme.dart';
import '../widgets/media_viewers.dart';
import '../localization/app_localizations_extension.dart';
import 'dart:io';

class AudioDownloadsScreen extends StatefulWidget {
  final String sectionType;
  
  const AudioDownloadsScreen({
    super.key,
    this.sectionType = 'lughat',
  });

  @override
  State<AudioDownloadsScreen> createState() => _AudioDownloadsScreenState();
}

class _AudioDownloadsScreenState extends State<AudioDownloadsScreen> {
  Map<int, List<DownloadedAudio>> downloadedAudioByPara = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDownloadedAudios();
  }

  Future<void> _loadDownloadedAudios() async {
    setState(() => isLoading = true);
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      final sectionDir = Directory('${directory.path}/${widget.sectionType}');
      
      if (await sectionDir.exists()) {
        final files = sectionDir.listSync();
        
        for (var file in files) {
          if (file is File && file.path.endsWith('.mp3')) {
            // Extract surah and ayah from filename (e.g., "1_1_audio_abc12345.mp3")
            final filename = file.path.split('/').last;
            final parts = filename.split('_');
            
            // Expected pattern: surahIndex_ayahIndex_audio_urlhash.mp3
            if (parts.length >= 3 && parts[2] == 'audio') {
              final surahIndex = int.tryParse(parts[0]);
              final ayahIndex = int.tryParse(parts[1]);
              
              if (surahIndex != null && ayahIndex != null) {
                final paraNumber = _getParaNumberForSurah(surahIndex);
                
                if (!downloadedAudioByPara.containsKey(paraNumber)) {
                  downloadedAudioByPara[paraNumber] = [];
                }
                
                downloadedAudioByPara[paraNumber]!.add(
                  DownloadedAudio(
                    surahIndex: surahIndex,
                    ayahIndex: ayahIndex,
                    filePath: file.path,
                    surahName: _getSurahName(surahIndex),
                  ),
                );
              }
            }
          }
        }
        
        // Sort audios within each para
        downloadedAudioByPara.forEach((para, audios) {
          audios.sort((a, b) {
            if (a.surahIndex != b.surahIndex) {
              return a.surahIndex.compareTo(b.surahIndex);
            }
            return a.ayahIndex.compareTo(b.ayahIndex);
          });
        });
      }
    } catch (e) {
      debugPrint('Error loading downloaded audios: $e');
    }
    
    setState(() => isLoading = false);
  }

  int _getParaNumberForSurah(int surahIndex) {
    // Para mapping for surahs
    final paraMapping = {
      1: 1, 2: 1,  // Para 1: Al-Fatiha, Al-Baqarah (start)
      3: 3, 4: 4,  // Para 3: Aal-e-Imran, Para 4: An-Nisa
      5: 6, 6: 7,  // Para 6: Al-Maidah, Para 7: Al-An'am
      7: 8, 8: 9, 9: 10,  // Para 8-10
      10: 11, 11: 11,  // Para 11: Yunus, Hud
      12: 12, 13: 13, 14: 13,  // Para 12-13
      15: 14, 16: 14,  // Para 14
      17: 15, 18: 15, 19: 16, 20: 16,  // Para 15-16
      21: 17, 22: 17, 23: 18, 24: 18, 25: 18,  // Para 17-18
      26: 19, 27: 19, 28: 20, 29: 21,  // Para 19-21
      30: 21, 31: 21, 32: 21, 33: 21, 34: 22, 35: 22, 36: 22,  // Para 21-22
      37: 23, 38: 23, 39: 23, 40: 24, 41: 24,  // Para 23-24
      42: 25, 43: 25, 44: 25, 45: 25, 46: 26,  // Para 25-26
      47: 26, 48: 26, 49: 26, 50: 26, 51: 26,  // Para 26
      52: 27, 53: 27, 54: 27, 55: 27, 56: 27, 57: 27,  // Para 27
      58: 28, 59: 28, 60: 28, 61: 28, 62: 28, 63: 28, 64: 28, 65: 28, 66: 28,  // Para 28
      67: 29, 68: 29, 69: 29, 70: 29, 71: 29, 72: 29, 73: 29, 74: 29, 75: 29, 76: 29, 77: 29,  // Para 29
      78: 30, 79: 30, 80: 30, 81: 30, 82: 30, 83: 30, 84: 30, 85: 30, 86: 30, 87: 30,  // Para 30
      88: 30, 89: 30, 90: 30, 91: 30, 92: 30, 93: 30, 94: 30, 95: 30, 96: 30, 97: 30,
      98: 30, 99: 30, 100: 30, 101: 30, 102: 30, 103: 30, 104: 30, 105: 30, 106: 30,
      107: 30, 108: 30, 109: 30, 110: 30, 111: 30, 112: 30, 113: 30, 114: 30
    };
    
    return paraMapping[surahIndex] ?? 1;
  }

  String _getSurahName(int surahIndex) {
    final surahNames = {
      1: 'الفاتحة', 2: 'البقرة', 3: 'آل عمران', 4: 'النساء', 5: 'المائدة',
      6: 'الأنعام', 7: 'الأعراف', 8: 'الأنفال', 9: 'التوبة', 10: 'يونس',
      11: 'هود', 12: 'يوسف', 13: 'الرعد', 14: 'إبراهيم', 15: 'الحجر',
      16: 'النحل', 17: 'الإسراء', 18: 'الكهف', 19: 'مريم', 20: 'طه',
      21: 'الأنبياء', 22: 'الحج', 23: 'المؤمنون', 24: 'النور', 25: 'الفرقان',
      26: 'الشعراء', 27: 'النمل', 28: 'القصص', 29: 'العنكبوت', 30: 'الروم',
      31: 'لقمان', 32: 'السجدة', 33: 'الأحزاب', 34: 'سبأ', 35: 'فاطر',
      36: 'يس', 37: 'الصافات', 38: 'ص', 39: 'الزمر', 40: 'غافر',
      41: 'فصلت', 42: 'الشورى', 43: 'الزخرف', 44: 'الدخان', 45: 'الجاثية',
      46: 'الأحقاف', 47: 'محمد', 48: 'الفتح', 49: 'الحجرات', 50: 'ق',
      51: 'الذاريات', 52: 'الطور', 53: 'النجم', 54: 'القمر', 55: 'الرحمن',
      56: 'الواقعة', 57: 'الحديد', 58: 'المجادلة', 59: 'الحشر', 60: 'الممتحنة',
      61: 'الصف', 62: 'الجمعة', 63: 'المنافقون', 64: 'التغابن', 65: 'الطلاق',
      66: 'التحريم', 67: 'الملك', 68: 'القلم', 69: 'الحاقة', 70: 'المعارج',
      71: 'نوح', 72: 'الجن', 73: 'المزمل', 74: 'المدثر', 75: 'القيامة',
      76: 'الإنسان', 77: 'المرسلات', 78: 'النبأ', 79: 'النازعات', 80: 'عبس',
      81: 'التكوير', 82: 'الانفطار', 83: 'المطففين', 84: 'الانشقاق', 85: 'البروج',
      86: 'الطارق', 87: 'الأعلى', 88: 'الغاشية', 89: 'الفجر', 90: 'البلد',
      91: 'الشمس', 92: 'الليل', 93: 'الضحى', 94: 'الشرح', 95: 'التين',
      96: 'العلق', 97: 'القدر', 98: 'البينة', 99: 'الزلزلة', 100: 'العاديات',
      101: 'القارعة', 102: 'التكاثر', 103: 'العصر', 104: 'الهمزة', 105: 'الفيل',
      106: 'قريش', 107: 'الماعون', 108: 'الكوثر', 109: 'الكافرون', 110: 'النصر',
      111: 'المسد', 112: 'الإخلاص', 113: 'الفلق', 114: 'الناس'
    };
    
    return surahNames[surahIndex] ?? 'سورة $surahIndex';
  }

  String _getParaName(int paraNumber, BuildContext context) {
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
    
    return paraNames[paraNumber] ?? context.l.paraNumber.replaceAll('{number}', paraNumber.toString());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        title: Text(context.l.audioDownloads),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(context, isDark),
    );
  }

  Widget _buildBody(BuildContext context, bool isDark) {
    if (isLoading) {
      return Center(
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
      );
    }

    if (downloadedAudioByPara.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_off_rounded,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            Text(
              context.l.noAudioDownloads,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontFamily: 'Bahij Badr Light',
              ),
            ),
            const SizedBox(height: 10),
            Text(
              context.l.downloadAudiosFromVerses,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                fontFamily: 'Bahij Badr Light',
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: 30,
      itemBuilder: (context, index) {
        final paraNumber = index + 1;
        final audioCount = downloadedAudioByPara[paraNumber]?.length ?? 0;
        final hasAudios = audioCount > 0;

        return GestureDetector(
          onTap: hasAudios
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ParaAudioDetailScreen(
                        paraNumber: paraNumber,
                        paraName: _getParaName(paraNumber, context),
                        audios: downloadedAudioByPara[paraNumber]!,
                        sectionType: widget.sectionType,
                      ),
                    ),
                  );
                }
              : null,
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? (hasAudios ? AppTheme.darkSurface : AppTheme.darkSurface.withValues(alpha: 0.5))
                  : (hasAudios ? Colors.white : Colors.grey[100]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: hasAudios
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
              border: Border.all(
                color: hasAudios
                    ? AppTheme.primaryGreen.withValues(alpha: 0.3)
                    : Colors.grey.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.folder_rounded,
                  size: 40,
                  color: hasAudios ? AppTheme.primaryGreen : Colors.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  context.l.paraNumber.replaceAll('{number}', paraNumber.toString()),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: hasAudios
                        ? (isDark ? Colors.white : Colors.black87)
                        : Colors.grey[500],
                    fontFamily: 'Bahij Badr Light',
                  ),
                ),
                if (hasAudios) ...[
                  const SizedBox(height: 4),
                  Text(
                    context.l.audiosCount.replaceAll('{count}', audioCount.toString()),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryGreen,
                      fontFamily: 'Bahij Badr Light',
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class ParaAudioDetailScreen extends StatelessWidget {
  final int paraNumber;
  final String paraName;
  final List<DownloadedAudio> audios;
  final String sectionType;

  const ParaAudioDetailScreen({
    super.key,
    required this.paraNumber,
    required this.paraName,
    required this.audios,
    required this.sectionType,
  });

  Map<int, List<DownloadedAudio>> _groupAudiosBySurah() {
    final Map<int, List<DownloadedAudio>> grouped = {};
    
    for (var audio in audios) {
      if (!grouped.containsKey(audio.surahIndex)) {
        grouped[audio.surahIndex] = [];
      }
      grouped[audio.surahIndex]!.add(audio);
    }
    
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final audiosBySurah = _groupAudiosBySurah();

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
                        title: Text('$paraName - ${context.l.para} $paraNumber'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: audiosBySurah.length,
        itemBuilder: (context, index) {
          final surahIndex = audiosBySurah.keys.elementAt(index);
          final surahAudios = audiosBySurah[surahIndex]!;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
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
            child: ExpansionTile(
              title: Row(
                children: [
                  Icon(
                    Icons.folder_rounded,
                    color: AppTheme.primaryGreen,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      surahAudios.first.surahName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${surahAudios.length} غږونه',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              children: surahAudios.map((audio) {
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.music_note_rounded,
                        color: AppTheme.primaryGreen,
                        size: 20,
                      ),
                    ),
                  ),
                  title: Text(
                    'آیت ${audio.ayahIndex}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    'لغات - غږ',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.play_circle_filled_rounded,
                      color: AppTheme.primaryGreen,
                      size: 32,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FullScreenAudioPlayer(
                            audioUrl: '',  // URL not needed as we have local file
                            title: '${audio.surahName} - آیت ${audio.ayahIndex}',
                            surahIndex: audio.surahIndex,
                            ayahIndex: audio.ayahIndex,
                            autoPlay: true,
                            sectionType: sectionType,
                          ),
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}

class DownloadedAudio {
  final int surahIndex;
  final int ayahIndex;
  final String filePath;
  final String surahName;

  DownloadedAudio({
    required this.surahIndex,
    required this.ayahIndex,
    required this.filePath,
    required this.surahName,
  });
} 