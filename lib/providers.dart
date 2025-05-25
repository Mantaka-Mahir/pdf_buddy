import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import 'services/pdf_service.dart';

final pdfDataProvider = StateProvider<Uint8List?>((ref) => null);
final pdfMetadataProvider = StateProvider<PdfMetadata?>((ref) => null);
final loadingProvider = StateProvider<bool>((ref) => false);
final additionalPdfsProvider = StateProvider<List<(Uint8List, String)>>((ref) => []);