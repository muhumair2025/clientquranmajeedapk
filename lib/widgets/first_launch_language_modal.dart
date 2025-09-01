import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../themes/app_theme.dart';

class FirstLaunchLanguageScreen extends StatelessWidget {
  const FirstLaunchLanguageScreen({super.key});

  static Future<void> show(BuildContext context) async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const FirstLaunchLanguageScreen(),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back button dismissal
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Column(
              children: [
                // Compact Header Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16), // Reduced padding
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.primaryGreen,
                        AppTheme.primaryGreen.withValues(alpha: 0.9),
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      // Compact App Icon
                      Container(
                        width: 48, // Reduced from 80
                        height: 48, // Reduced from 80
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12), // Reduced from 20
                        ),
                        child: Icon(
                          Icons.menu_book_rounded,
                          size: 28, // Reduced from 50
                          color: Colors.white,
                        ),
                      ),
                      
                      const SizedBox(height: 12), // Reduced from 24
                      
                      // Compact Welcome Text
                      Text(
                        'Welcome to Quran Majeed',
                        style: TextStyle(
                          fontSize: 20, // Reduced from 24 and combined texts
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 8), // Reduced from 16
                      
                      Text(
                        'Select your language',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14, // Reduced from 16
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Compact Language Selection Section
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16), // Reduced from 24
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Compact Section Title
                        Row(
                          children: [
                            Icon(
                              Icons.language_rounded,
                              color: AppTheme.primaryGreen,
                              size: 20, // Reduced from 28
                            ),
                            const SizedBox(width: 8), // Reduced from 12
                            Text(
                              'Choose Language',
                              style: TextStyle(
                                fontSize: 16, // Reduced from 22
                                fontWeight: FontWeight.w600, // Reduced weight
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16), // Reduced from 24
                        
                        // Compact Language Options
                        Expanded(
                          child: Consumer<LanguageProvider>(
                            builder: (context, languageProvider, child) {
                              return ListView.builder(
                                itemCount: LanguageProvider.supportedLocales.length,
                                itemBuilder: (context, index) {
                                  final locale = LanguageProvider.supportedLocales[index];
                                  final languageName = languageProvider.getLanguageName(locale);
                                  final languageFlag = languageProvider.getLanguageFlag(locale.languageCode);
                                  final languageDescription = languageProvider.getLanguageDescription(locale.languageCode);
                                  
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8), // Reduced from 16
                                    child: _buildLanguageOption(
                                      context: context,
                                      locale: locale,
                                      languageName: languageName,
                                      languageDescription: languageDescription,
                                      languageFlag: languageFlag,
                                      onTap: () => _onLanguageSelected(context, languageProvider, locale),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Compact Footer Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16), // Reduced from 24
                  child: Column(
                    children: [
                      Text(
                        'You can change this later in Settings',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12, // Reduced from 14
                          color: Colors.grey[600],
                        ),
                      ),
                      
                      const SizedBox(height: 12), // Reduced from 16
                      
                      // Compact Progress indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 6, // Reduced from 8
                            height: 6, // Reduced from 8
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 6), // Reduced from 8
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required Locale locale,
    required String languageName,
    required String languageDescription,
    required String languageFlag,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12), // Reduced from 16
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12), // Reduced from 20
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12), // Reduced from 16
            border: Border.all(
              color: Colors.grey[200]!,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03), // Reduced shadow
                blurRadius: 6, // Reduced from 10
                offset: const Offset(0, 1), // Reduced from 2
              ),
            ],
          ),
          child: Row(
            children: [
              // Compact Flag
              Container(
                width: 40, // Reduced from 60
                height: 40, // Reduced from 60
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8), // Reduced from 12
                  border: Border.all(
                    color: Colors.grey[200]!,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    languageFlag,
                    style: const TextStyle(fontSize: 22), // Reduced from 32
                  ),
                ),
              ),
              
              const SizedBox(width: 12), // Reduced from 20
              
              // Compact Language info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      languageName,
                      style: const TextStyle(
                        fontSize: 16, // Reduced from 20
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2), // Reduced from 4
                    Text(
                      languageDescription,
                      style: TextStyle(
                        fontSize: 13, // Reduced from 16
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Compact Arrow icon
              Container(
                width: 28, // Reduced from 40
                height: 28, // Reduced from 40
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6), // Reduced from 10
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14, // Reduced from 18
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onLanguageSelected(
    BuildContext context,
    LanguageProvider languageProvider,
    Locale selectedLocale,
  ) async {
    // Complete first launch with selected language
    await languageProvider.completeFirstLaunch(selectedLocale);
    
    // Check if the widget is still mounted before using context
    if (context.mounted) {
      // Close the screen
      Navigator.of(context).pop();
      
      // Show a brief success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Language set to ${languageProvider.getLanguageDescription(selectedLocale.languageCode)}'),
          backgroundColor: AppTheme.primaryGreen,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }
} 