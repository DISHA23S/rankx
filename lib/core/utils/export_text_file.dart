import 'export_text_file_stub.dart'
    if (dart.library.html) 'export_text_file_web.dart'
    if (dart.library.io) 'export_text_file_io.dart';

/// Saves/Downloads a text file (CSV, JSON, etc.) across platforms.
Future<void> exportTextFile({
  required String filename,
  required String content,
  String mimeType = 'text/plain',
}) =>
    exportTextFileImpl(
      filename: filename,
      content: content,
      mimeType: mimeType,
    );


