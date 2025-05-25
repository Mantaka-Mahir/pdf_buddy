import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:html' as html;
import 'package:pdf_buddy/utils/theme.dart';

class PDFDropZone extends ConsumerStatefulWidget {
  final Function(List<html.File> files)? onPdfDropped;
  final bool allowMultiple;

  const PDFDropZone({
    super.key, 
    this.onPdfDropped,
    this.allowMultiple = true
  });

  @override
  ConsumerState<PDFDropZone> createState() => _PDFDropZoneState();
}

class _PDFDropZoneState extends ConsumerState<PDFDropZone> {
  bool isHovering = false;
  static const int _maxFileSizeBytes = 100 * 1024 * 1024; // 100MB

  bool _validateFiles(List<html.File> files) {
    if (!widget.allowMultiple && files.length > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select only one PDF file'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return false;
    }

    for (var file in files) {
      if (file.type != 'application/pdf') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${file.name} is not a PDF file'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        return false;
      }

      if (file.size > _maxFileSizeBytes) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${file.name} is larger than 100MB'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        return false;
      }
    }
    return true;
  }

  void _handleFileDrop(html.Event event) {
    event.preventDefault();
    setState(() => isHovering = false);

    if (event is html.MouseEvent) {
      final transfer = (event as dynamic).dataTransfer;
      if (transfer != null) {
        final files = transfer.files;
        if (files.isNotEmpty) {
          final fileList = List<html.File>.from(files);
          if (_validateFiles(fileList)) {
            widget.onPdfDropped?.call(fileList);
          }
        }
      }
    }
  }

  void _handleFileInput(html.Event event) {
    if (event.target is html.InputElement) {
      final input = event.target as html.InputElement;
      if (input.files?.isNotEmpty ?? false) {
        final fileList = List<html.File>.from(input.files!);
        if (_validateFiles(fileList)) {
          widget.onPdfDropped?.call(fileList);
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    html.document.body?.addEventListener('dragover', (event) {
      event.preventDefault();
      setState(() => isHovering = true);
    });
    html.document.body?.addEventListener('dragleave', (event) {
      event.preventDefault();
      setState(() => isHovering = false);
    });
    html.document.body?.addEventListener('drop', _handleFileDrop);
  }

  @override
  void dispose() {
    html.document.body?.removeEventListener('dragover', (event) {
      event.preventDefault();
      setState(() => isHovering = true);
    });
    html.document.body?.removeEventListener('dragleave', (event) {
      event.preventDefault();
      setState(() => isHovering = false);
    });
    html.document.body?.removeEventListener('drop', _handleFileDrop);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: MouseRegion(
          onEnter: (_) => setState(() => isHovering = true),
          onExit: (_) => setState(() => isHovering = false),
          child: GestureDetector(
            onTap: () {
              final input = html.FileUploadInputElement()
                ..accept = 'application/pdf'
                ..multiple = widget.allowMultiple;
              input.click();
              input.onChange.listen(_handleFileInput);
            },
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.all(48),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isHovering ? AppTheme.accentBlue : AppTheme.primaryBlue.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: isHovering ? 5 : 0,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.darkBackground,
                      border: Border.all(
                        color: isHovering ? AppTheme.accentBlue : AppTheme.primaryBlue,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.picture_as_pdf,
                      size: 48,
                      color: isHovering ? AppTheme.accentBlue : AppTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    widget.allowMultiple ? 'Click to select PDF files' : 'Click to select a PDF file',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.textColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'or drop ${widget.allowMultiple ? "them" : "it"} here',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textColor.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.darkBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.accentBlue),
                    ),
                    child: Text(
                      widget.allowMultiple ? 'You can select multiple PDFs' : 'Select one PDF file',
                      style: TextStyle(
                        color: AppTheme.accentBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}