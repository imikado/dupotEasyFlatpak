import 'dart:io' as io;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'dart:io';

class FirstInstallation {
  Future<void> mkdir(String path) async {
    var result = Process.runSync('/usr/bin/mkdir', [path]);
    print(result.stdout);
    print(result.stderr);

    await cwd();
  }

  Future<void> cwd() async {
    var result = Process.runSync('/usr/bin/pwd', []);
    print(result.stdout);
    print(result.stderr);
  }

  Future<void> copyTo(String fromPath, String targetPath) async {
    var result = Process.runSync('/usr/bin/cp', [fromPath, targetPath],
        runInShell: true);
    print(result.stdout);
    print(result.stderr);
  }

  Future<void> unarchive(String archivePath, String targetPath) async {
    var result = Process.runSync(
        '/usr/bin/tar', ['-xvzf', archivePath, '-C', targetPath]);
    print(result.stdout);
    print(result.stderr);
  }

  Future<void> process() async {
    final io.Directory appDocumentsDir =
        await getApplicationDocumentsDirectory();
    String appDocumentsDirPath = appDocumentsDir.path;

    io.Directory documentsTargetDirectory =
        io.Directory(p.join(appDocumentsDirPath, "EasyFlatpak"));

    if (!documentsTargetDirectory.existsSync()) {
      await mkdir(documentsTargetDirectory.path);

      await copyAssetTo('assets/db/flathub_database.db',
          '${documentsTargetDirectory.path}/flathub_database.db');

      String targetIconsArchive =
          '${documentsTargetDirectory.path}/Archive.tar.gz';

      await copyAssetTo('assets/icons/Archive.tar.gz', targetIconsArchive);

      await unarchive(targetIconsArchive, documentsTargetDirectory.path);

/*
      await copyTo('./assets/db/flathub_database.db',
          '${documentsTargetDirectory.path}/flathub_database.db');

      await unarchive(
          './assets/icons/Archive.tar.gz', documentsTargetDirectory.path);
          */
    } else {
      print('already installed');
    }
  }

  Future<void> copyAssetTo(String assetPath, String targetPath) async {
    final bytes = await rootBundle.load(assetPath);
    final targetFile = File(targetPath);
    await targetFile.writeAsBytes(bytes.buffer.asUint8List());
  }
}
