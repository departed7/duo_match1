import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportService {
  static const String apkFileName = "DuoMatch_Setup.apk";

  static Future<void> generateAndShareApk() async {
    try {
      final directory = await getTemporaryDirectory();
      final devicePath = "${directory.path}/$apkFileName";
      final file = File(devicePath);

      if (await file.exists()) {
        await file.delete();
      }

      final ByteData data = await rootBundle.load('assets/apk/app.apk');
      final List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

      if (bytes.isEmpty) {
        throw Exception("Файл в ассетах пустой");
      }

      await file.writeAsBytes(bytes, flush: true);

      final int fileSize = await file.length();
      
      if (fileSize > 1000) {
        await Share.shareXFiles(
          [XFile(devicePath, mimeType: 'application/vnd.android.package-archive')],
          text: 'Установочный пакет DuoMatch APK (Размер: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} МБ)',
        );
      } else {
        throw Exception("Ошибка: Файл слишком маленький ($fileSize байт). Пересоберите проект через flutter clean!");
      }
    } catch (e) {
      throw Exception("Системная ошибка: $e");
    }
  }
}