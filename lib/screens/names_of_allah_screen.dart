import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xml/xml.dart';
import '../widgets/app_text.dart';
import '../themes/app_theme.dart';
import '../localization/app_localizations_extension.dart';
import '../models/asma_ul_husna_model.dart';
import '../utils/theme_extensions.dart';

class NamesOfAllahScreen extends StatefulWidget {
  const NamesOfAllahScreen({super.key});

  @override
  State<NamesOfAllahScreen> createState() => _NamesOfAllahScreenState();
}

class _NamesOfAllahScreenState extends State<NamesOfAllahScreen> {
  List<AsmaUlHusnaName> _names = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNames();
  }

  Future<void> _loadNames() async {
    try {
      final xmlString = await rootBundle.loadString('assets/data/asma_ul_husna.xml');
      final document = XmlDocument.parse(xmlString);
      
      final names = document.findAllElements('name').map((element) {
        final id = int.parse(element.getAttribute('id') ?? '0');
        final arabic = element.findElements('arabic').first.innerText;
        final transliteration = element.findElements('transliteration').first.innerText;
        
        final translationsElement = element.findElements('translations').first;
        final translations = <String, String>{};
        
        for (var lang in ['en', 'ur', 'ps', 'ar']) {
          final langElement = translationsElement.findElements(lang);
          if (langElement.isNotEmpty) {
            translations[lang] = langElement.first.innerText;
          }
        }
        
        return AsmaUlHusnaName(
          id: id,
          arabic: arabic,
          transliteration: transliteration,
          translations: translations,
        );
      }).toList();
      
      setState(() {
        _names = names;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading Names of Allah: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentLang = context.currentLanguage;

    return Scaffold(
      appBar: AppBar(
        title: AppText(context.l.namesOfAllah),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : Container(
              color: isDark ? const Color(0xFF0D0D0D) : const Color(0xFFFAFAFA),
              child: GridView.builder(
                padding: const EdgeInsets.all(6),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemCount: _names.length,
                itemBuilder: (context, index) {
                  return _NameCard(
                    name: _names[index],
                    isDark: isDark,
                    currentLang: currentLang,
                  );
                },
              ),
            ),
    );
  }
}

class _NameCard extends StatelessWidget {
  final AsmaUlHusnaName name;
  final bool isDark;
  final String currentLang;

  const _NameCard({
    required this.name,
    required this.isDark,
    required this.currentLang,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDark 
        ? const Color(0xFF1A1A1A) 
        : Colors.white;

    return Material(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          _showNameDetail(context);
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: isDark ? null : const DecorationImage(
              image: AssetImage('assets/images/decorative-border.jpg'),
              fit: BoxFit.cover,
              opacity: 0.15,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Number - minimal
              Text(
                '${name.id}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: context.primaryColor.withOpacity(0.7),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              
              // Arabic name
              Expanded(
                child: Center(
                  child: Text(
                    name.arabic,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Al Qalam Quran Majeed',
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: context.primaryColor,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              
              // Translation in current language
              AppText(
                name.getTranslation(currentLang),
                textAlign: TextAlign.center,
                style: context.textStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNameDetail(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            
            // Number badge
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: context.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '${name.id}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: context.primaryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Arabic name
            Text(
              name.arabic,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Al Qalam Quran Majeed',
                fontSize: 36,
                fontWeight: FontWeight.w600,
                color: context.primaryColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            
            // Transliteration
            Text(
              name.transliteration,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            
            // Translation
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: AppText(
                name.getTranslation(currentLang),
                textAlign: TextAlign.center,
                style: context.textStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

