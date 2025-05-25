import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_buddy/services/pdf_service.dart';
import 'package:pdf_buddy/utils/theme.dart';
import 'dart:typed_data';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

final pdfDataProvider = StateProvider<Uint8List?>((ref) => null);
final pdfMetadataProvider = StateProvider<PdfMetadata?>((ref) => null);
final loadingProvider = StateProvider<bool>((ref) => false);
final errorMessageProvider = StateProvider<String?>((ref) => null);

class PDFViewer extends ConsumerWidget {
  const PDFViewer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pdfData = ref.watch(pdfDataProvider);
    final metadata = ref.watch(pdfMetadataProvider);
    final isLoading = ref.watch(loadingProvider);
    final errorMessage = ref.watch(errorMessageProvider);

    if (errorMessage != null) {
      return Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, 
                size: 64,
                color: Colors.red.withOpacity(0.8),
              ),
              const SizedBox(height: 24),
              Text(
                'OPERATION FAILED',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.red,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.darkBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  errorMessage,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(errorMessageProvider.notifier).state = null;
                  ref.read(pdfDataProvider.notifier).state = null;
                  ref.read(pdfMetadataProvider.notifier).state = null;
                },
                icon: const Icon(Icons.refresh),
                label: const Text('TRY AGAIN'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surfaceColor,
                  foregroundColor: AppTheme.primaryBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: AppTheme.primaryBlue),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (pdfData == null || metadata == null) {
      return Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'NO PDF LOADED',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textColor.withOpacity(0.5),
              letterSpacing: 2,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.darkBackground,
              border: Border(
                bottom: BorderSide(color: AppTheme.primaryBlue.withOpacity(0.3)),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.save, color: AppTheme.primaryBlue),
                  onPressed: () {
                    ref.read(pdfServiceProvider).downloadPDF(
                      pdfData,
                      metadata.fileName,
                    );
                  },
                  tooltip: 'Save PDF',
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        metadata.fileName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${metadata.pageCount} pages • ${metadata.fileSizeKB} KB',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLoading)
                  Container(
                    width: 24,
                    height: 24,
                    padding: const EdgeInsets.all(2),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.darkBackground,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: Theme(
                data: ThemeData(
                  canvasColor: AppTheme.darkBackground,
                ),
                child: SfPdfViewer.memory(
                  pdfData,
                  pageSpacing: 8,
                  canShowScrollHead: false,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}