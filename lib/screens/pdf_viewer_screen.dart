import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import '../utils/theme_extensions.dart';
import '../widgets/app_text.dart';
import '../localization/app_localizations_extension.dart';

/// In-app PDF viewer using pdfx for native rendering
class PDFViewerScreen extends StatefulWidget {
  final String filePath;
  final String title;

  const PDFViewerScreen({
    super.key,
    required this.filePath,
    required this.title,
  });

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  PdfControllerPinch? _pdfController;
  int _totalPages = 0;
  int _currentPage = 1;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      final file = File(widget.filePath);
      if (!await file.exists()) {
        setState(() {
          _error = 'PDF file not found';
          _isLoading = false;
        });
        return;
      }

      final document = await PdfDocument.openFile(widget.filePath);
      
      if (mounted) {
        setState(() {
          _totalPages = document.pagesCount;
          _pdfController = PdfControllerPinch(
            document: PdfDocument.openFile(widget.filePath),
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load PDF: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[100],
      appBar: AppBar(
        title: AppText(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: context.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_totalPages > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '$_currentPage / $_totalPages',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: context.primaryColor),
            const SizedBox(height: 16),
            AppText(context.l.loading, style: TextStyle(color: context.secondaryTextColor)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: context.errorColor),
            const SizedBox(height: 16),
            AppText(_error!, style: TextStyle(color: context.textColor), textAlign: TextAlign.center),
          ],
        ),
      );
    }

    if (_pdfController == null) {
      return Center(
        child: AppText('Unable to load PDF', style: TextStyle(color: context.textColor)),
      );
    }

    return PdfViewPinch(
      controller: _pdfController!,
      onPageChanged: (page) {
        setState(() => _currentPage = page);
      },
      builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
        options: const DefaultBuilderOptions(),
        documentLoaderBuilder: (_) => Center(
          child: CircularProgressIndicator(color: context.primaryColor),
        ),
        pageLoaderBuilder: (_) => Center(
          child: CircularProgressIndicator(color: context.primaryColor),
        ),
        errorBuilder: (_, error) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: context.errorColor),
              const SizedBox(height: 16),
              AppText('Error loading page', style: TextStyle(color: context.textColor)),
            ],
          ),
        ),
      ),
    );
  }
}
