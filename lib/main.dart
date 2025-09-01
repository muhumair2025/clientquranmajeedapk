import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'themes/app_theme.dart';
import 'providers/theme_provider.dart';
import 'providers/font_provider.dart';
import 'providers/language_provider.dart';
import 'screens/quran_navigation_screen.dart';
import 'screens/audio_downloads_screen.dart';
import 'screens/video_downloads_screen.dart';
import 'services/lughat_service.dart';
import 'localization/app_localizations_delegate.dart';
import 'localization/app_localizations_extension.dart';
import 'widgets/language_selection_modal.dart';
import 'widgets/first_launch_language_modal.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize LughatService data
  await LughatService.loadLughatData();
  
  // Setup system UI
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );
  
  // Launch main app
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => FontProvider()),
        ChangeNotifierProvider(create: (context) => LanguageProvider()),
      ],
      child: const QuranMajeedApp(),
    ),
  );
}



class QuranMajeedApp extends StatelessWidget {
  const QuranMajeedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LanguageProvider>(
      builder: (context, themeProvider, languageProvider, child) {
        return MaterialApp(
          title: 'Quran Majeed',
          debugShowCheckedModeBanner: false,
          // Localization setup
          locale: languageProvider.currentLocale,
          supportedLocales: LanguageProvider.supportedLocales,
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          // Set text direction based on language
          builder: (context, child) {
            return Directionality(
              textDirection: languageProvider.textDirection,
              child: child!,
            );
          },
          theme: AppTheme.getLightTheme(languageProvider.currentLanguage),
          darkTheme: AppTheme.getDarkTheme(languageProvider.currentLanguage),
          themeMode: themeProvider.themeMode,
          home: const MainScreen(),
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 4; // Default to home page with 6 cards

  late final List<Widget> _pages;
  bool _hasCheckedFirstLaunch = false; // Add flag to prevent multiple checks

  @override
  void initState() {
    super.initState();
    _pages = [
      const PlaceholderPage(), // Other tools
      const PlaceholderPage(), // Documents
      const AudioDownloadsScreen(), // Download Audio
      const VideoDownloadsScreen(), // Download Video
      const QuranMajeedHomePage(), // Home page - shows all 6 cards ONLY here
    ];
    
    // Check for first launch after the frame is built with a small delay
    // to ensure LanguageProvider has loaded its state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasCheckedFirstLaunch) {
        // Add a small delay to ensure SharedPreferences have been loaded
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _checkFirstLaunch();
          }
        });
      }
    });
  }

  void _checkFirstLaunch() async {
    if (_hasCheckedFirstLaunch) return;
    _hasCheckedFirstLaunch = true; // Ensure this only runs once
    
    final languageProvider = context.read<LanguageProvider>();
    
    // Wait for the language provider to finish loading
    while (!languageProvider.isLoaded && mounted) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    
    if (mounted && languageProvider.isFirstLaunch) {
      debugPrint('Showing first launch language screen');
      // Show first launch language selection screen
      FirstLaunchLanguageScreen.show(context);
    } else {
      debugPrint('Not first launch, skipping language screen');
    }
  }

  String _getPageTitle(BuildContext context, int index) {
    switch (index) {
      case 0:
        return context.l.otherTools;
      case 1:
        return context.l.documents;
      case 2:
        return context.l.audioDownloads;
      case 3:
        return context.l.videoDownloads;
      case 4:
        return context.l.quranMajeed;
      default:
        return context.l.quranMajeed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getPageTitle(context, _selectedIndex)),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(
                  themeProvider.isDarkMode
                    ? Icons.light_mode_rounded 
                    : Icons.dark_mode_rounded,
                ),
                onPressed: () {
                  themeProvider.toggleTheme();
                },
              );
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      drawer: const QuranMajeedDrawer(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              // RTL order - reversed
              children: [
                _buildBottomNavItem(4, Icons.home_rounded), // Home page
                _buildBottomNavItem(3, Icons.video_library_rounded), // Download Video
                _buildBottomNavItem(2, Icons.library_music_rounded), // Download Audio
                _buildBottomNavItem(1, Icons.description_rounded), // Documents
                _buildBottomNavItem(0, Icons.apps_rounded), // Other tools - grid icon
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(int index, IconData icon) {
    final isSelected = _selectedIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
          size: 28,
        ),
      ),
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction_rounded,
            size: 80,
            color: AppTheme.primaryGreen,
          ),
          const SizedBox(height: 20),
          Text(
            context.l.underDevelopment,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.primaryGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            context.l.featureNotAvailable,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class QuranMajeedHomePage extends StatefulWidget {
  const QuranMajeedHomePage({super.key});

  @override
  State<QuranMajeedHomePage> createState() => _QuranMajeedHomePageState();
}

class _QuranMajeedHomePageState extends State<QuranMajeedHomePage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Padding(
      padding: const EdgeInsets.all(12), // Reduced from 16
      child: Column(
        children: [
          // Top row: عقیده (right), تفسیر او ترجمه (left)
          Expanded(
            flex: 1, // Equal height for all rows
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: _buildMenuCard(
                    context,
                    title: context.l.aqeedah,
                    subtitle: context.l.aqeedahSubtitle,
                    icon: Icons.star_rounded,
                    onTap: () {
                      // Navigate to Aqeedah section
                    },
                  ),
                ),
                const SizedBox(width: 8), // Reduced from 12
                Expanded(
                  child: _buildMenuCard(
                    context,
                    title: context.l.tafseerTranslation,
                    subtitle: context.l.tafseerSubtitle,
                    icon: Icons.book_rounded,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const QuranNavigationScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8), // Reduced from 12
          // Middle row: فقه (right), حدیث (left)
          Expanded(
            flex: 1, // Equal height for all rows
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: _buildMenuCard(
                    context,
                    title: context.l.fiqh,
                    subtitle: context.l.fiqhSubtitle,
                    icon: Icons.balance_rounded,
                    onTap: () {
                      // Navigate to Fiqh section
                    },
                  ),
                ),
                const SizedBox(width: 8), // Reduced from 12
                Expanded(
                  child: _buildMenuCard(
                    context,
                    title: context.l.hadith,
                    subtitle: context.l.hadithSubtitle,
                    icon: Icons.chat_bubble_rounded,
                    onTap: () {
                      // Navigate to Hadith section
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8), // Reduced from 12
          // Bottom row: سوال خواب (right), کتابونه (left)
          Expanded(
            flex: 1, // Equal height for all rows
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: _buildMenuCard(
                    context,
                    title: context.l.questionAnswer,
                    subtitle: context.l.questionAnswerSubtitle,
                    icon: Icons.help_rounded,
                    onTap: () {
                      // Navigate to Q&A section
                    },
                  ),
                ),
                const SizedBox(width: 8), // Reduced from 12
                Expanded(
                  child: _buildMenuCard(
                    context,
                    title: context.l.books,
                    subtitle: context.l.booksSubtitle,
                    icon: Icons.library_books_rounded,
                    onTap: () {
                      // Navigate to Books section
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16), // Reduced from 20
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Flexible icon container
                Container(
                  padding: const EdgeInsets.all(14), // Reduced from 18
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12), // Reduced from 16
                  ),
                  child: Icon(
                    icon,
                    size: 28, // Reduced from 36
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(height: 12), // Reduced from 18
                
                // Flexible title with better text handling
                Flexible(
                  child: AutoSizeText(
                    title,
                    style: TextStyle(
                      fontSize: 15, // Reduced from 16
                      fontWeight: FontWeight.bold,
                      height: 1.1, // Tighter line height
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3, // Increased from 2
                    minFontSize: 12, // Minimum font size
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                const SizedBox(height: 6), // Reduced from 8
                
                // Flexible subtitle with better text handling
                Flexible(
                  child: AutoSizeText(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12, // Reduced from 13
                      height: 1.2, // Tighter line height
                      color: isDark ? Colors.white60 : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3, // Increased from 2
                    minFontSize: 10, // Minimum font size
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class QuranMajeedDrawer extends StatelessWidget {
  const QuranMajeedDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        
        return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark 
              ? [
                  AppTheme.darkGreen,
                  AppTheme.primaryGreen.withValues(alpha: 0.9),
                  AppTheme.darkGreen.withValues(alpha: 0.8),
                ]
              : [AppTheme.primaryGreen, AppTheme.darkGreen],
          ),
        ),
        child: Column(
          children: [
            // Fixed header
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.l.appTitle,
                    style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  ),
                ],
              ),
            ),
            // Scrollable content
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    context,
                    icon: Icons.home_rounded,
                    title: context.l.home,
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.book_rounded,
                    title: context.l.quranKareem,
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.star_rounded,
                    title: context.l.aqeedah,
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.library_books_rounded,
                    title: context.l.tafseerTranslation,
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.balance_rounded,
                    title: context.l.fiqh,
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.chat_bubble_rounded,
                    title: context.l.hadith,
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.help_rounded,
                    title: context.l.questionAnswer,
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.library_books_rounded,
                    title: context.l.books,
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  const Divider(color: Colors.white54),
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return _buildDrawerItem(
                        context,
                        icon: themeProvider.isDarkMode
                          ? Icons.light_mode_rounded 
                          : Icons.dark_mode_rounded,
                        title: themeProvider.isDarkMode
                          ? context.l.lightMode
                          : context.l.darkMode,
                        onTap: () {
                          themeProvider.toggleTheme();
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.language_rounded,
                    title: context.l.language,
                    onTap: () {
                      Navigator.of(context).pop();
                      LanguageSelectionModal.show(context);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.info_rounded,
                    title: context.l.aboutUs,
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.white,
        size: 24,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}


