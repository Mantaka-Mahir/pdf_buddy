import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_buddy/features/landing_page.dart';
import 'package:pdf_buddy/utils/theme.dart';
import 'package:universal_html/html.dart' as html;
import 'package:pdf_buddy/components/pdf_drop_zone.dart';
import 'package:pdf_buddy/components/pdf_tools_panel.dart';
import 'package:pdf_buddy/features/pdf_viewer.dart';
import 'package:pdf_buddy/services/pdf_service.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'PDF Buddy',
      theme: AppTheme.theme,
      home: const LandingPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pdfService = ref.watch(pdfServiceProvider);
    final pdfData = ref.watch(pdfDataProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.darkBackground,
              Color(0xFF101820),
              AppTheme.darkBackground,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'MERGE PDF',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.textColor,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Main Content
                Expanded(
                  child: pdfData == null 
                    ? PDFDropZone(
                        onPdfDropped: (files) async {
                          if (files.isEmpty) return;
                          ref.read(loadingProvider.notifier).state = true;
                          try {
                            final result = await pdfService.readFileAsBytes(files[0]);
                            if (result != null) {
                              ref.read(pdfDataProvider.notifier).state = result.$1;
                              ref.read(pdfMetadataProvider.notifier).state = result.$2;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('PDF loaded successfully'),
                                  backgroundColor: AppTheme.primaryBlue,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } finally {
                            ref.read(loadingProvider.notifier).state = false;
                          }
                        },
                      )
                    : Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: AppTheme.surfaceColor,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(16),
                                          child: const PDFViewer(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
                                ),
                                child: const PDFToolsPanel(),
                              ),
                            ],
                          ),
                          // Add more files button
                          Positioned(
                            right: 16,
                            top: 16,
                            child: FloatingActionButton(
                              onPressed: () async {
                                final input = html.FileUploadInputElement()
                                  ..accept = 'application/pdf'
                                  ..click();
                                
                                input.onChange.listen((event) async {
                                  if (input.files?.isNotEmpty ?? false) {
                                    ref.read(loadingProvider.notifier).state = true;
                                    try {
                                      final file = input.files![0];
                                      final result = await pdfService.readFileAsBytes(file);
                                      if (result != null) {
                                        ref.read(additionalPdfsProvider.notifier).update(
                                          (state) => [...state, (result.$1, file.name)]
                                        );
                                      }
                                    } finally {
                                      ref.read(loadingProvider.notifier).state = false;
                                    }
                                  }
                                });
                              },
                              backgroundColor: Colors.red,
                              child: const Icon(Icons.add, color: Colors.white, size: 32),
                            ),
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
}
