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
      documentsTargetDirectory.createSync();

      io.Directory assetsIconsDirectory = io.Directory('assets/icons/');
      var assetIconList = assetsIconsDirectory.listSync();
      for (io.FileSystemEntity assetIconLoop in assetIconList) {
        io.File assetIconFileLoop = io.File(assetIconLoop.path);
        assetIconFileLoop.copySync(
            '${documentsTargetDirectory.path}/${p.basename(assetIconFileLoop.path)}');
        print('Copy asset icon ${assetIconLoop.path} ');
      }

      io.File databaseFile = io.File('assets/db/flathub_database.db');
      databaseFile
          .copySync('${documentsTargetDirectory.path}/flathub_database.db');
      print('Copy asset icon ${databaseFile.path} ');
    } else {
      print('already installed');
    }
  }
}
