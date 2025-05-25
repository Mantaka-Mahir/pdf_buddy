import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_buddy/services/pdf_service.dart';
import 'package:pdf_buddy/features/pdf_viewer.dart';
import 'package:pdf_buddy/utils/theme.dart';
import 'package:pdf_buddy/providers/processing_providers.dart';
import 'dart:typed_data';

final selectedPagesProvider = StateProvider<List<int>>((ref) => []);
final additionalPdfsProvider = StateProvider<List<(Uint8List, String)>>((ref) => []);

class PDFToolsPanel extends ConsumerWidget {
  const PDFToolsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pdfData = ref.watch(pdfDataProvider);
    final metadata = ref.watch(pdfMetadataProvider);
    final additionalPdfs = ref.watch(additionalPdfsProvider);
    final pdfService = ref.watch(pdfServiceProvider);
    final isLoading = ref.watch(loadingProvider);
    final progress = ref.watch(processingProgressProvider);

    Widget buildProgressIndicator() {
      if (!isLoading) return const SizedBox.shrink();
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            if (progress != null)
              LinearProgressIndicator(
                value: progress,
                backgroundColor: AppTheme.darkBackground,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentBlue),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              )
            else
              LinearProgressIndicator(
                backgroundColor: AppTheme.darkBackground,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentBlue),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            const SizedBox(height: 8),
            Text(
              progress != null 
                ? 'Processing: ${(progress * 100).toStringAsFixed(1)}%'
                : 'Processing...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textColor.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    if (pdfData == null || metadata == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Selected PDFs list
        if (additionalPdfs.isNotEmpty) ...[
          ListView.builder(
            shrinkWrap: true,
            itemCount: additionalPdfs.length,
            itemBuilder: (context, index) {
              final pdf = additionalPdfs[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.darkBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, 
                      color: AppTheme.primaryBlue.withOpacity(0.7),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        pdf.$2,
                        style: TextStyle(color: AppTheme.textColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, 
                        color: AppTheme.primaryBlue.withOpacity(0.7),
                        size: 20,
                      ),
                      onPressed: () {
                        ref.read(additionalPdfsProvider.notifier).update(
                          (state) => state.where((p) => p != pdf).toList()
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],

        // Merge button
        if (additionalPdfs.isNotEmpty)
          ElevatedButton(
            onPressed: isLoading ? null : () async {
              ref.read(loadingProvider.notifier).state = true;
              ref.read(processingProgressProvider.notifier).state = 0.0;
              try {
                final result = await pdfService.mergePDFs(
                  [pdfData, ...additionalPdfs.map((p) => p.$1)],
                  'merged_${metadata.fileName}',
                );
                if (result != null) {
                  ref.read(pdfDataProvider.notifier).state = result.$1;
                  ref.read(pdfMetadataProvider.notifier).state = result.$2;
                  ref.read(additionalPdfsProvider.notifier).state = [];
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('PDFs merged successfully'),
                      backgroundColor: AppTheme.primaryBlue,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  pdfService.downloadPDF(result.$1, 'merged_${metadata.fileName}');
                }
              } finally {
                ref.read(loadingProvider.notifier).state = false;
                ref.read(processingProgressProvider.notifier).state = null;
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'MERGE PDF FILES',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),

        if (isLoading) buildProgressIndicator(),
      ],
    );
  }
}