import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'themes/app_theme.dart';
import 'providers/theme_provider.dart';
import 'providers/font_provider.dart';
import 'screens/quran_navigation_screen.dart';
import 'services/lughat_service.dart';

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
      ],
      child: const QuranMajeedApp(),
    ),
  );
}



class QuranMajeedApp extends StatelessWidget {
  const QuranMajeedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'قرآن مجید',
          debugShowCheckedModeBanner: false,
          // Enable RTL support
          locale: const Locale('ps', 'AF'), // Pashto Afghanistan
          // Set text direction to RTL
          builder: (context, child) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: child!,
            );
          },
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
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

  @override
  void initState() {
    super.initState();
    _pages = [
      const PlaceholderPage(title: 'نور وسایل'), // Other tools
      const PlaceholderPage(title: 'اسناد'), // Documents
      const PlaceholderPage(title: 'د غږیز فایلونو ډاونلوډ'), // Download Audio
      const PlaceholderPage(title: 'د ویډیو فایلونو ډاونلوډ'), // Download Video
      const QuranMajeedHomePage(), // Home page - shows all 6 cards ONLY here
    ];
  }

  String _getPageTitle(int index) {
    switch (index) {
      case 0:
        return 'نور وسایل';
      case 1:
        return 'اسناد';
      case 2:
        return 'د غږیز فایلونو ډاونلوډ';
      case 3:
        return 'د ویډیو فایلونو ډاونلوډ';
      case 4:
        return 'قرآن مجید';
      default:
        return 'قرآن مجید';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getPageTitle(_selectedIndex)),
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
  final String title;
  
  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getPageIcon(title),
            size: 80,
            color: AppTheme.primaryGreen,
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.primaryGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'دا برخه د پراختیا لاندې ده',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPageIcon(String title) {
    switch (title) {
      case 'اسناد':
        return Icons.description_rounded; // Documents
      case 'د غږیز فایلونو ډاونلوډ':
        return Icons.library_music_rounded; // Download Audio
      case 'د ویډیو فایلونو ډاونلوډ':
        return Icons.video_library_rounded; // Download Video
      case 'نور وسایل':
        return Icons.apps_rounded; // Other tools - grid icon
      default:
        return Icons.home_rounded; // Default home icon
    }
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Top row: عقیده (right), تفسیر او ترجمه (left)
          Expanded(
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: _buildMenuCard(
                    context,
                    title: 'عقیده',
                    subtitle: 'د اسلام بنسټونه',
                    icon: Icons.star_rounded,
                    onTap: () {
                      // Navigate to Aqeedah section
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMenuCard(
                    context,
                    title: 'تفسیر او ترجمه',
                    subtitle: 'د قرآن تشریح',
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
          const SizedBox(height: 12),
          // Middle row: فقه (right), حدیث (left)
          Expanded(
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: _buildMenuCard(
                    context,
                    title: 'فقه',
                    subtitle: 'اسلامي قوانین',
                    icon: Icons.balance_rounded,
                    onTap: () {
                      // Navigate to Fiqh section
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMenuCard(
                    context,
                    title: 'حدیث',
                    subtitle: 'د نبي وینا',
                    icon: Icons.chat_bubble_rounded,
                    onTap: () {
                      // Navigate to Hadith section
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Bottom row: سوال خواب (right), کتابونه (left)
          Expanded(
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: _buildMenuCard(
                    context,
                    title: 'سوال خواب',
                    subtitle: 'ستاسو پوښتنې',
                    icon: Icons.help_rounded,
                    onTap: () {
                      // Navigate to Q&A section
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMenuCard(
                    context,
                    title: 'کتابونه',
                    subtitle: 'اسلامي کتابونه',
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
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    size: 36,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    height: 1.3,
                    color: isDark ? Colors.white60 : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
                  const Text(
                    'قرآن مجید',
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
                    icon: Icons.home_rounded,
                    title: 'کورپاڼه',
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.book_rounded,
                    title: 'قرآن کریم',
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.star_rounded,
                    title: 'عقیده',
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.library_books_rounded,
                    title: 'تفسیر او ترجمه',
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.balance_rounded,
                    title: 'فقه',
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.chat_bubble_rounded,
                    title: 'حدیث',
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.help_rounded,
                    title: 'سوال خواب',
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.library_books_rounded,
                    title: 'کتابونه',
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  const Divider(color: Colors.white54),
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return _buildDrawerItem(
                        icon: themeProvider.isDarkMode
                          ? Icons.light_mode_rounded 
                          : Icons.dark_mode_rounded,
                        title: themeProvider.isDarkMode
                          ? 'روښانه حالت' 
                          : 'تیاره حالت',
                        onTap: () {
                          themeProvider.toggleTheme();
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.settings_rounded,
                    title: 'تنظیمات',
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.info_rounded,
                    title: 'د اپلیکیشن په اړه',
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
  }

  Widget _buildDrawerItem({
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


