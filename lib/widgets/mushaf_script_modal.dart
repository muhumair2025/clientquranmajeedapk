import 'package:flutter/material.dart';
import '../services/mushaf_download_service.dart';
import '../themes/app_theme.dart';
import '../localization/app_localizations_extension.dart';
import 'app_text.dart';

/// Compact modal for selecting and downloading Mushaf scripts
class MushafScriptModal extends StatefulWidget {
  final VoidCallback? onScriptReady;
  
  const MushafScriptModal({
    super.key,
    this.onScriptReady,
  });

  @override
  State<MushafScriptModal> createState() => _MushafScriptModalState();

  /// Show the modal and return true if a script is ready to use
  static Future<bool> show(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const MushafScriptModal(),
    );
    return result ?? false;
  }
}

class _MushafScriptModalState extends State<MushafScriptModal> {
  MushafScript _selectedScript = MushafDownloadService.availableScripts.first;
  bool _isDownloaded = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkDownloadStatus();
  }

  Future<void> _checkDownloadStatus() async {
    setState(() => _isChecking = true);
    
    final downloaded = await MushafDownloadService.isScriptDownloaded(_selectedScript.id);
    
    if (mounted) {
      setState(() {
        _isDownloaded = downloaded;
        _isChecking = false;
      });
    }
  }

  void _startDownload() {
    MushafDownloadService.resetState();
    MushafDownloadService.downloadScript(_selectedScript);
  }

  void _handleContinue() {
    Navigator.pop(context, true);
    widget.onScriptReady?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.65),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBackground : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(
                  Icons.auto_stories_rounded,
                  color: AppTheme.primaryGreen,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        context.l.quranScript,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      AppText(
                        context.l.downloadToReadQuran,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.grey[500], size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.pop(context, false),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Script preview card
                  _buildScriptCard(isDark),
                  
                  const SizedBox(height: 16),
                  
                  // Download/Continue button
                  _buildActionButton(isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScriptCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isDownloaded 
              ? AppTheme.primaryGreen.withOpacity(0.3)
              : (isDark ? Colors.white10 : Colors.grey[200]!),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Preview image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            child: Container(
              height: 160,
              color: Colors.white,
              child: Image.asset(
                _selectedScript.previewImage,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Center(
                  child: Icon(
                    Icons.menu_book_rounded,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                ),
              ),
            ),
          ),
          
          // Script info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AppText(
                            _selectedScript.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 6),
                          AppText(
                            _selectedScript.nameArabic,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primaryGold,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildInfoChip(
                            '${_selectedScript.totalPages} ${context.l.pages}',
                            Icons.layers_outlined,
                            isDark,
                          ),
                          const SizedBox(width: 8),
                          _buildInfoChip(
                            '~${_selectedScript.sizeInMB} MB',
                            Icons.storage_outlined,
                            isDark,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_isDownloaded)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: AppTheme.primaryGreen,
                        ),
                        const SizedBox(width: 4),
                        AppText(
                          context.l.scriptReady,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[500]),
          const SizedBox(width: 4),
          AppText(
            text,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(bool isDark) {
    if (_isChecking) {
      return const SizedBox(
        height: 44,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_isDownloaded) {
      return SizedBox(
        width: double.infinity,
        height: 44,
        child: ElevatedButton.icon(
          onPressed: _handleContinue,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
          ),
          icon: const Icon(Icons.menu_book_rounded, size: 18),
          label: AppText(
            context.l.openQuran,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
      );
    }

    return ValueListenableBuilder<DownloadStatus>(
      valueListenable: MushafDownloadService.downloadStatus,
      builder: (context, status, _) {
        if (status == DownloadStatus.downloading || status == DownloadStatus.extracting) {
          return _buildDownloadProgress(isDark, status);
        }

        if (status == DownloadStatus.downloaded) {
          // Download just completed
          Future.microtask(() {
            if (mounted) {
              setState(() => _isDownloaded = true);
            }
          });
        }

        if (status == DownloadStatus.error) {
          return _buildErrorState(isDark);
        }

        return SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton.icon(
            onPressed: _startDownload,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGold,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.download_rounded, size: 18),
            label: AppText(
              '${context.l.downloadScript} (~${_selectedScript.sizeInMB} MB)',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDownloadProgress(bool isDark, DownloadStatus status) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey[200]!,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ValueListenableBuilder<String>(
                  valueListenable: MushafDownloadService.statusMessage,
                  builder: (context, message, _) {
                    return AppText(
                      message.isNotEmpty ? message : (status == DownloadStatus.extracting ? 'Extracting...' : 'Downloading...'),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    );
                  },
                ),
              ),
              TextButton(
                onPressed: MushafDownloadService.cancelDownload,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                ),
                child: AppText(
                  context.l.cancel,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red[400],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<double>(
            valueListenable: MushafDownloadService.downloadProgress,
            builder: (context, progress, _) {
              return Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: status == DownloadStatus.extracting ? null : progress,
                      minHeight: 6,
                      backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation(AppTheme.primaryGreen),
                    ),
                  ),
                  if (status == DownloadStatus.downloading && progress > 0) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: AppText(
                        '${(progress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[400], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: ValueListenableBuilder<String>(
              valueListenable: MushafDownloadService.statusMessage,
              builder: (context, message, _) {
                return AppText(
                  message.isNotEmpty ? message : 'Download failed',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              MushafDownloadService.resetState();
              _startDownload();
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(0, 32),
            ),
            child: AppText(
              context.l.retry,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

