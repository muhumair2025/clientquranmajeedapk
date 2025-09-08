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
import 'screens/major_downloads_screen.dart';
import 'services/lughat_service.dart';
import 'services/tafseer_service.dart';
import 'services/faidi_service.dart';
import 'services/favorites_service.dart';
import 'services/notes_service.dart';
import 'localization/app_localizations_delegate.dart';
import 'localization/app_localizations_extension.dart';
import 'widgets/language_selection_modal.dart';
import 'widgets/first_launch_language_modal.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize all services data
  await Future.wait([
    LughatService.loadLughatData(),
    TafseerService.loadTafseerData(),
    FaidiService.loadFaidiData(),
    FavoritesService.initialize(),
    NotesService.initialize(),
  ]);
  
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
      const MajorDownloadsScreen(), // Major Downloads
      const PlaceholderPage(), // Reserved for future use
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
        return context.l.downloads;
      case 3:
        return context.l.reserved;
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
      drawer: QuranMajeedDrawer(
        onNavigateToHome: () {
          setState(() {
            _selectedIndex = 4;
          });
        },
      ),
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
                _buildBottomNavItem(3, Icons.more_horiz_rounded), // Reserved
                _buildBottomNavItem(2, Icons.download_rounded), // Major Downloads
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
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/pattern_back_homepage.PNG'),
          fit: BoxFit.cover,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Top row: عقیده (left), تفسیر او ترجمه (right) - MIRRORED
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.18,
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: _buildImageCard(
                      context,
                      imagePath: 'assets/images/tarjumatafseer_card1.png',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const QuranNavigationScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildImageCard(
                      context,
                      imagePath: 'assets/images/aqeeda_card2.png',
                      onTap: () {
                        // Navigate to Aqeedah section
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Middle row: حدیث (right), فقه (left) - MIRRORED
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.18,
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: _buildImageCard(
                      context,
                      imagePath: 'assets/images/hadeeth_card_3.png',
                      onTap: () {
                        // Navigate to Hadith section
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildImageCard(
                      context,
                      imagePath: 'assets/images/fiqah_card4.png',
                      onTap: () {
                        // Navigate to Fiqh section
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Bottom row: کتابونه (right), سوال جواب (left) - MIRRORED
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.18,
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: _buildImageCard(
                      context,
                      imagePath: 'assets/images/kitaboona_card5.png',
                      onTap: () {
                        // Navigate to Books section
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildImageCard(
                      context,
                      imagePath: 'assets/images/sawal_jawab_card6.png',
                      onTap: () {
                        // Navigate to Q&A section
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard(
    BuildContext context, {
    required String imagePath,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.white.withValues(alpha: 0.3), // White ripple effect
          highlightColor: Colors.white.withValues(alpha: 0.1), // Subtle highlight
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // Main image
                    Image.asset(
                      imagePath,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                    // Overlay for press effect
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          splashColor: Colors.black.withValues(alpha: 0.1),
                          highlightColor: Colors.black.withValues(alpha: 0.05),
                          onTap: onTap,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class QuranMajeedDrawer extends StatelessWidget {
  final VoidCallback onNavigateToHome;
  
  const QuranMajeedDrawer({
    super.key,
    required this.onNavigateToHome,
  });

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
                      // Navigate to home page (index 4)
                      onNavigateToHome();
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.book_rounded,
                    title: context.l.quranKareem,
                    onTap: () {
                      Navigator.of(context).pop();
                      // Navigate to Quran Navigation screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const QuranNavigationScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.star_rounded,
                    title: context.l.aqeedah,
                    onTap: () {
                      Navigator.of(context).pop();
                      // TODO: Navigate to Aqeedah screen when available
                      _showComingSoonDialog(context, context.l.aqeedah);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.library_books_rounded,
                    title: context.l.tafseerTranslation,
                    onTap: () {
                      Navigator.of(context).pop();
                      // TODO: Navigate to Tafseer/Translation screen when available
                      _showComingSoonDialog(context, context.l.tafseerTranslation);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.balance_rounded,
                    title: context.l.fiqh,
                    onTap: () {
                      Navigator.of(context).pop();
                      // TODO: Navigate to Fiqh screen when available
                      _showComingSoonDialog(context, context.l.fiqh);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.chat_bubble_rounded,
                    title: context.l.hadith,
                    onTap: () {
                      Navigator.of(context).pop();
                      // TODO: Navigate to Hadith screen when available
                      _showComingSoonDialog(context, context.l.hadith);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.help_rounded,
                    title: context.l.questionAnswer,
                    onTap: () {
                      Navigator.of(context).pop();
                      // TODO: Navigate to Question & Answer screen when available
                      _showComingSoonDialog(context, context.l.questionAnswer);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.library_books_rounded,
                    title: context.l.books,
                    onTap: () {
                      Navigator.of(context).pop();
                      // TODO: Navigate to Books screen when available
                      _showComingSoonDialog(context, context.l.books);
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
                      // TODO: Navigate to About Us screen when available
                      _showComingSoonDialog(context, context.l.aboutUs);
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

  void _showComingSoonDialog(BuildContext context, String featureName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            context.l.comingSoon,
            style: const TextStyle(
              fontFamily: 'Bahij Badr Bold',
            ),
          ),
          content: Text(
            '$featureName ${context.l.featureNotAvailable}',
            style: const TextStyle(
              fontFamily: 'Bahij Badr Light',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                context.l.ok,
                style: TextStyle(
                  color: AppTheme.primaryGreen,
                  fontFamily: 'Bahij Badr Medium',
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}


