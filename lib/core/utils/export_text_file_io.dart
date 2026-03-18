import 'dart:io';

import 'package:file_picker/file_picker.dart';

Future<void> exportTextFileImpl({
  required String filename,
  required String content,
  required String mimeType,
}) async {
  final savePath = await FilePicker.platform.saveFile(
    dialogTitle: 'Save report',
    fileName: filename,
  );
  if (savePath == null || savePath.trim().isEmpty) return;

  final file = File(savePath);
  await file.writeAsString(content, flush: true);
}


