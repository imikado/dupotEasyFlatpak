import 'dart:io' as io;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class FirstInstallation {
  Future<void> process() async {
    final io.Directory appDocumentsDir =
        await getApplicationDocumentsDirectory();
    String appDocumentsDirPath = appDocumentsDir.path;

    io.Directory documentsTargetDirectory =
        io.Directory(p.join(appDocumentsDirPath, "EasyFlatpak"));

    if (!documentsTargetDirectory.existsSync()) {
      io.Directory newDocumentsTargetDirectory =
          io.Directory(documentsTargetDirectory.path);

      newDocumentsTargetDirectory.createSync();

      String dbPath =
          p.join(appDocumentsDirPath, "EasyFlatpak", "flathub_database.db");

      io.Directory iconsDirectory = io.Directory('assets/icons/');
      if (await iconsDirectory.exists()) {
        var fileList = iconsDirectory.listSync();
        for (var filePathLoop in fileList) {
          final assetIcon = await rootBundle.load(filePathLoop.path);
          final buffer = assetIcon.buffer;

          io.File fileTarget = io.File(
              '${documentsTargetDirectory.path}/${p.basename(filePathLoop.path)}');

          await fileTarget.writeAsBytes(buffer.asUint8List(
              assetIcon.offsetInBytes, assetIcon.lengthInBytes));
        }
      }

      final assetIcon = await rootBundle.load('assets/db/flathub_database.db');
      final buffer = assetIcon.buffer;

      io.File fileTarget =
          io.File('${documentsTargetDirectory.path}/flathub_database.db');

      await fileTarget.writeAsBytes(
          buffer.asUint8List(assetIcon.offsetInBytes, assetIcon.lengthInBytes));
    } else {
      print('already installed');
    }
  }
}
