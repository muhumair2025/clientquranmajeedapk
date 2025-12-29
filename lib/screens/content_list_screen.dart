import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../providers/language_provider.dart';
import '../localization/app_localizations_extension.dart';
import '../services/content_api_service.dart';
import '../services/content_storage_service.dart';
import '../models/content_models.dart';
import '../utils/theme_extensions.dart';
import '../utils/font_manager.dart';
import '../widgets/app_text.dart';
import 'content_detail_screen.dart';

/// Clean minimal content list screen - matches subcategories style
class ContentListScreen extends StatefulWidget {
  final int subcategoryId;
  final String subcategoryName;
  final String? categoryColor;

  const ContentListScreen({
    super.key,
    required this.subcategoryId,
    required this.subcategoryName,
    this.categoryColor,
  });

  @override
  State<ContentListScreen> createState() => _ContentListScreenState();
}

class _ContentListScreenState extends State<ContentListScreen> {
  final ContentApiService _apiService = ContentApiService();
  final ContentStorageService _storageService = ContentStorageService();
  
  List<ContentItem> _contents = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _loadContents(forceRefresh: false);
  }

  Future<bool> _hasNetworkConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return false;
      }
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _loadContents({bool forceRefresh = false}) async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = _contents.isEmpty;
      _errorMessage = null;
    });

    try {
      final hasNetwork = await _hasNetworkConnection();
      if (mounted) setState(() => _isOffline = !hasNetwork);

      final subcategoryContents = await _apiService.getSubcategoryContents(
        widget.subcategoryId,
        forceRefresh: forceRefresh && hasNetwork,
      );
      
      final List<ContentItem> updatedContents = [];
      for (var content in subcategoryContents.contents) {
        if (content.requiresDownload) {
          final isDownloaded = await _storageService.isContentDownloaded(content.id);
          if (isDownloaded) {
            final localPath = await _storageService.getLocalPath(content.id);
            updatedContents.add(content.copyWith(
              isDownloaded: true,
              localFilePath: localPath,
            ));
          } else {
            updatedContents.add(content);
          }
        } else {
          updatedContents.add(content);
        }
      }
      
      if (mounted) {
        setState(() {
          _contents = updatedContents;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading contents: $e');
      if (mounted) {
        setState(() {
          if (_contents.isEmpty) _errorMessage = context.l.failedToLoadLatest;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshContents() async {
    final hasNetwork = await _hasNetworkConnection();
    if (mounted) setState(() => _isOffline = !hasNetwork);

    if (!hasNetwork) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: AppText(context.l.offline),
            backgroundColor: context.primaryColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    await _loadContents(forceRefresh: true);
  }

  void _openContent(ContentItem content) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContentDetailScreen(content: content),
      ),
    ).then((_) => _loadContents());
  }

  IconData _getContentIcon(ContentType type) {
    switch (type) {
      case ContentType.text:
        return Icons.article_outlined;
      case ContentType.qa:
        return Icons.help_outline;
      case ContentType.pdf:
        return Icons.picture_as_pdf_outlined;
      case ContentType.audio:
        return Icons.headphones_outlined;
      case ContentType.video:
        return Icons.play_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isOffline) ...[
              Icon(Icons.cloud_off, size: 16, color: Colors.white70),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: AppText(
                widget.subcategoryName,
                style: const TextStyle(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: context.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(context, languageProvider, isDark),
    );
  }

  Widget _buildBody(BuildContext context, LanguageProvider languageProvider, bool isDark) {
    if (_isLoading && _contents.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: context.primaryColor),
      );
    }

    if (_errorMessage != null && _contents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: context.errorColor),
            const SizedBox(height: 12),
            AppText(_errorMessage!, style: TextStyle(color: context.textColor)),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _loadContents,
              icon: const Icon(Icons.refresh),
              label: AppText(context.l.retry),
            ),
          ],
        ),
      );
    }

    if (_contents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 48, color: context.secondaryTextColor),
            const SizedBox(height: 12),
            AppText(context.l.noDataFound, style: TextStyle(color: context.secondaryTextColor)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshContents,
      color: context.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: _contents.length,
        itemBuilder: (context, index) => _buildContentItem(_contents[index], isDark, languageProvider.currentLanguage),
      ),
    );
  }

  Widget _buildContentItem(ContentItem content, bool isDark, String languageCode) {
    final isRTL = FontManager.isRTL(languageCode);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.primaryColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openContent(content),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
              children: [
                // Content type icon
                Icon(
                  _getContentIcon(content.type),
                  size: 20,
                  color: context.primaryColor,
                ),
                const SizedBox(width: 12),
                
                // Title
                Expanded(
                  child: AppText(
                    content.title,
                    style: FontManager.getTextStyle(
                      languageCode,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: context.textColor,
                      height: 1.4,
                    ),
                    textAlign: isRTL ? TextAlign.right : TextAlign.left,
                    textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                // Downloaded indicator
                if (content.isDownloaded) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.download_done, size: 16, color: context.primaryColor.withOpacity(0.7)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
