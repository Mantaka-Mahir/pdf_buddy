import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:universal_html/html.dart' as html;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:typed_data';
import 'dart:async';
import 'dart:ui';

final pdfServiceProvider = Provider((ref) => PDFService());

class PdfMetadata {
  final int pageCount;
  final int fileSizeKB;
  final String fileName;

  PdfMetadata({
    required this.pageCount,
    required this.fileSizeKB,
    required this.fileName,
  });
}

class PDFService {
  Future<(Uint8List, PdfMetadata)?> readFileAsBytes(html.File file) async {
    try {
      print('Reading file: ${file.name}, size: ${file.size} bytes, type: ${file.type}');
      
      if (file.type != 'application/pdf') {
        print('Invalid file type: ${file.type}');
        return null;
      }

      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      await reader.onLoad.first;
      
      if (reader.result == null) {
        print('Error: FileReader result is null');
        return null;
      }
      
      final bytes = reader.result as Uint8List;
      
      // Validate PDF and extract metadata
      try {
        final document = PdfDocument(inputBytes: bytes);
        final metadata = PdfMetadata(
          pageCount: document.pages.count,
          fileSizeKB: (bytes.length / 1024).round(),
          fileName: file.name,
        );
        document.dispose();
        print('PDF validated successfully: ${metadata.pageCount} pages');
        return (bytes, metadata);
      } catch (e) {
        print('PDF validation failed: $e');
        return null;
      }
    } catch (e) {
      print('Error in readFileAsBytes: $e');
      return null;
    }
  }

  Future<(Uint8List, PdfMetadata)?> mergePDFs(
    List<Uint8List> pdfList,
    String fileName, [
    void Function(double)? onProgress,
  ]) async {
    try {
      print('Merging ${pdfList.length} PDF files');
      onProgress?.call(0.0);
      
      // Instead of creating a new document that might apply default formatting,
      // work with each PDF directly
      List<PdfDocument> documents = [];
      int totalPages = 0;
      
      // First pass: load all documents and count pages
      for (int i = 0; i < pdfList.length; i++) {
        try {
          final document = PdfDocument(inputBytes: pdfList[i]);
          documents.add(document);
          totalPages += document.pages.count;
          onProgress?.call(0.1 * (i + 1) / pdfList.length);
        } catch (e) {
          print('Error loading PDF $i: $e');
        }
      }
      
      if (documents.isEmpty) {
        print('No valid PDF documents to merge');
        return null;
      }

      // Create a new document to hold all merged content
      final PdfDocument combinedDocument = PdfDocument();
      
      // Configure document settings to prevent default formatting
      combinedDocument.pageSettings.margins.all = 0;
      
      // Remove the initial blank page if it exists
      if (combinedDocument.pages.count > 0) {
        combinedDocument.pages.removeAt(0);
      }
      
      // Process all documents
      int processedPages = 0;
      
      // Using the improved page transfer technique to preserve content exactly
      for (int docIndex = 0; docIndex < documents.length; docIndex++) {
        final sourceDoc = documents[docIndex];
        
        for (int pageIndex = 0; pageIndex < sourceDoc.pages.count; pageIndex++) {
          final sourcePage = sourceDoc.pages[pageIndex];
          
          // Use the same approach as in splitPDF for perfect content preservation
          // Create a temporary document with the exact page
          final tempDoc = PdfDocument();
          if (tempDoc.pages.count > 0) {
            tempDoc.pages.removeAt(0);
          }
          
          // Set the page size to match source
          final tempPage = tempDoc.pages.add();
          tempDoc.pageSettings.size = sourcePage.size;
          
          // Copy all content exactly using template
          final template = sourcePage.createTemplate();
          tempPage.graphics.drawPdfTemplate(
            template,
           Offset.zero,
  Size(sourcePage.getClientSize().width, sourcePage.getClientSize().height)
          );
          
          // Get the exact byte representation
          final pageBytes = tempDoc.saveSync();
          tempDoc.dispose();
          
          // Now import the perfectly preserved page
          final importDoc = PdfDocument(inputBytes: Uint8List.fromList(pageBytes));
          if (importDoc.pages.count > 0) {
            // Add to our combined document - use pages.add() and draw template instead of importPage
            final newPage = combinedDocument.pages.add();
            final importedTemplate = importDoc.pages[0].createTemplate();
            newPage.graphics.drawPdfTemplate(
              importedTemplate, 
             Offset.zero,
  Size(sourcePage.getClientSize().width, sourcePage.getClientSize().height)
            );
            processedPages++;
          }
          importDoc.dispose();
          
          onProgress?.call(0.2 + (0.7 * processedPages / totalPages));
          
          if (processedPages % 5 == 0) {
            await Future.delayed(Duration(milliseconds: 1));
          }
        }
      }
      
      onProgress?.call(0.95);
      
      // Save with best compression that won't affect quality
      combinedDocument.compressionLevel = PdfCompressionLevel.best;
      
      final List<int> mergedBytes = combinedDocument.saveSync();
      final resultBytes = Uint8List.fromList(mergedBytes);
      
      final metadata = PdfMetadata(
        pageCount: processedPages,
        fileSizeKB: (resultBytes.length / 1024).round(),
        fileName: fileName,
      );
      
      // Clean up resources
      for (final doc in documents) {
        doc.dispose();
      }
      
      combinedDocument.dispose();
      onProgress?.call(1.0);
      
      print('PDF merge successful, total pages: $processedPages');
      return (resultBytes, metadata);
    } catch (e) {
      print('Error merging PDFs: $e');
      return null;
    }
  }

  Future<(Uint8List, PdfMetadata)?> splitPDF(
    Uint8List pdfBytes,
    List<int> pageNumbers,
    String fileName, [
    void Function(double)? onProgress,
  ]) async {
    try {
      print('Splitting PDF into pages: $pageNumbers');
      onProgress?.call(0.0);

      // Load the input document
      final PdfDocument inputDocument = PdfDocument(inputBytes: pdfBytes);

      // Create a new output document
      final PdfDocument outputDocument = PdfDocument();

      // Remove default blank page if one was created by the constructor
      if (outputDocument.pages.count > 0) {
        outputDocument.pages.removeAt(0);
      }

      var extractedPages = 0;
      onProgress?.call(0.1);
      await Future.delayed(Duration(milliseconds: 50));

      // Sort page numbers to ensure correct order if needed, though import order matters
      pageNumbers.sort(); 

      // Process each selected page number
      for (var i = 0; i < pageNumbers.length; i++) {
        final pageNumber = pageNumbers[i]; // pageNumber is 1-based
        
        // Validate page number
        if (pageNumber > 0 && pageNumber <= inputDocument.pages.count) {
          // Get the source page
          final sourcePage = inputDocument.pages[pageNumber - 1];
          
          // Add a new page to the output document
          final newPage = outputDocument.pages.add();
          
          // Create a template from the source page
          final PdfTemplate template = sourcePage.createTemplate();
          
          // Draw the template onto the new page, ensuring the size matches the source page's client size
          newPage.graphics.drawPdfTemplate(
            template,
            Offset.zero, // Draw at the top-left corner
            Size(sourcePage.getClientSize().width, sourcePage.getClientSize().height) // Use client size for exact dimensions
          );
          
          extractedPages++;
          final progress = 0.1 + (0.8 * (i + 1) / pageNumbers.length); // Adjusted progress calculation
          onProgress?.call(progress);

          // Add a small delay periodically to allow UI updates
          if (i % 5 == 0) { 
            await Future.delayed(Duration(milliseconds: 1));
          }
        } else {
          print('Skipping invalid page number: $pageNumber');
        }
      }

      // Ensure progress reaches near completion before saving
      onProgress?.call(0.95); 
      await Future.delayed(Duration(milliseconds: 50));

      // Check if any pages were actually extracted
      if (extractedPages == 0) {
        print('No valid pages selected or extracted.');
        inputDocument.dispose();
        outputDocument.dispose();
        return null; // Return null if no pages were added
      }

      // Save the output document
      // Using default compression which is usually balanced
      final List<int> splitBytes = outputDocument.saveSync();
      final resultBytes = Uint8List.fromList(splitBytes);

      final metadata = PdfMetadata(
        pageCount: extractedPages,
        fileSizeKB: (resultBytes.length / 1024).round(),
        fileName: 'split_$fileName',
      );

      // Dispose documents to release resources
      inputDocument.dispose();
      outputDocument.dispose();

      onProgress?.call(1.0);
      print('PDF split successful, extracted pages: $extractedPages');
      return (resultBytes, metadata);
      
    } catch (e) {
      print('Error splitting PDF: $e');
      onProgress?.call(1.0); // Ensure progress completes even on error
      return null;
    }
  }

  void downloadPDF(Uint8List bytes, String fileName) {
    try {
      print('Downloading PDF: $fileName, size: ${bytes.length} bytes');
      
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
      print('Download successful');
    } catch (e) {
      print('Error downloading PDF: $e');
    }
  }
}