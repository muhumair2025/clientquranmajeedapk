import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'themes/app_theme.dart';
import 'providers/theme_provider.dart';
import 'providers/font_provider.dart';
import 'providers/language_provider.dart';
import 'screens/major_downloads_screen.dart';
import 'screens/more_tools_screen.dart';
import 'screens/live_dars_screen.dart';
import 'screens/home_screen.dart';
import 'screens/latest_content_screen.dart';
import 'screens/splash_screen.dart';
import 'services/lughat_service.dart';
import 'services/tafseer_service.dart';
import 'services/faidi_service.dart';
import 'services/favorites_service.dart';
import 'services/prayer_alarm_service.dart';
import 'services/notes_service.dart';
import 'services/app_content_service.dart';
import 'services/live_video_service.dart';
import 'services/mushaf_database_service.dart';
import 'localization/app_localizations_delegate.dart';
import 'localization/app_localizations_extension.dart';
import 'widgets/first_launch_language_modal.dart';
import 'widgets/curved_bottom_nav.dart';
import 'widgets/app_drawer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables from .env.local
  try {
    await dotenv.load(fileName: '.env.local');
    debugPrint('✅ Loaded .env.local configuration');
  } catch (e) {
    debugPrint('⚠️ Warning: Could not load .env.local file: $e');
    debugPrint('⚠️ API features may not work properly');
  }
  
  // Initialize all services data
  await Future.wait([
    LughatService.loadLughatData(),
    TafseerService.loadTafseerData(),
    FaidiService.loadFaidiData(),
    FavoritesService.initialize(),
    NotesService.initialize(),
    AppContentService.initialize(), // Hero slides & splash screen
    LiveVideoService.initialize(), // Live videos
    PrayerAlarmService.initialize(), // Prayer alarms
    MushafDatabaseService.initialize(), // Mushaf image-based Quran
  ]);
  
  // Setup system UI - Full screen immersive mode (hides navigation bar)
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
    overlays: [], // Hide all system overlays
  );
  
  // Make status bar and navigation bar transparent when they appear
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );
  
  // Initialize providers
  final themeProvider = ThemeProvider();
  await themeProvider.loadThemePreferences(); // Load saved theme preferences
  
  // Launch main app
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
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
          theme: AppTheme.getLightTheme(languageProvider.currentLanguage, themeProvider.themePreset),
          darkTheme: AppTheme.getDarkTheme(languageProvider.currentLanguage, themeProvider.themePreset),
          themeMode: themeProvider.themeMode,
          home: const SplashWrapper(),
        );
      },
    );
  }
}

/// Wrapper that shows splash screen first, then main screen
class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    // Ensure fullscreen mode from the start
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
  }

  void _onSplashComplete() {
    if (mounted) {
      setState(() {
        _showSplash = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(
        onInitializationComplete: _onSplashComplete,
        minimumDisplayDuration: const Duration(seconds: 2),
      );
    }
    return const MainScreen();
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 4; // Default to home page (index 4)
  bool _hasCheckedFirstLaunch = false;

  @override
  void initState() {
    super.initState();
    // Ensure fullscreen mode when main screen loads
    _setFullScreenMode();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasCheckedFirstLaunch) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _checkFirstLaunch();
          }
        });
      }
    });
  }
  
  void _setFullScreenMode() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
  }
  
  Widget _getPageForIndex(int index) {
    final languageCode = context.read<LanguageProvider>().currentLanguage;
    
    switch (index) {
      case 0:
        return const MoreToolsScreen(); // Other tools (More)
      case 1:
        return LatestContentScreen(key: ValueKey('latest_$languageCode')); // Latest content
      case 2:
        return const LiveDarsScreen(); // Live Dars
      case 3:
        return const MajorDownloadsScreen(); // Major Downloads
      case 4:
        return QuranMajeedHomePage(key: ValueKey('home_$languageCode')); // Home page
      default:
        return QuranMajeedHomePage(key: ValueKey('home_$languageCode'));
    }
  }

  void _checkFirstLaunch() async {
    if (_hasCheckedFirstLaunch) return;
    _hasCheckedFirstLaunch = true;
    
    final languageProvider = context.read<LanguageProvider>();
    
    while (!languageProvider.isLoaded && mounted) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    
    if (mounted && languageProvider.isFirstLaunch) {
      FirstLaunchLanguageScreen.show(context);
    }
  }

  String _getPageTitle(BuildContext context, int index) {
    switch (index) {
      case 0:
        return context.l.otherTools;
      case 1:
        return context.l.latest;
      case 2:
        return context.l.live;
      case 3:
        return context.l.downloads;
      case 4:
        return context.l.quranMajeed;
      default:
        return context.l.quranMajeed;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch LanguageProvider to rebuild when language changes
    context.watch<LanguageProvider>();
    
    return Scaffold(
      extendBody: true, // Extend body behind bottom nav for clean transparent effect
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
      body: _getPageForIndex(_selectedIndex),
      drawer: QuranMajeedDrawer(
        onNavigateToHome: () {
          setState(() {
            _selectedIndex = 4;
          });
        },
      ),
      bottomNavigationBar: CurvedBottomNav(
        selectedIndex: _selectedIndex,
        onItemSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          BottomNavItem(
            index: 3,
            outlinedIcon: Icons.download_outlined,
            filledIcon: Icons.download_rounded,
            label: context.l.downloads,
          ),
          BottomNavItem(
            index: 1,
            outlinedIcon: Icons.schedule_outlined,
            filledIcon: Icons.schedule_rounded,
            label: context.l.latest,
          ),
          BottomNavItem(
            index: 4,
            outlinedIcon: Icons.home_outlined,
            filledIcon: Icons.home_rounded,
            label: context.l.home,
          ),
          BottomNavItem(
            index: 2,
            outlinedIcon: Icons.sensors_outlined,
            filledIcon: Icons.sensors_rounded,
            label: context.l.live,
          ),
          BottomNavItem(
            index: 0,
            outlinedIcon: Icons.apps_outlined,
            filledIcon: Icons.apps_rounded,
            label: context.l.more,
          ),
        ],
      ),
    );
  }
}
