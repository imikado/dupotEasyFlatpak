import 'dart:io' as io;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'dart:io';

class FirstInstallation {
  Future<void> copyTo(String fromPath, String targetPath) async {
    Process.run('cp', [fromPath, targetPath]);
  }

  Future<void> copyRecrusiveTo(String fromPath, String targetPath) async {
    Process.run('cp', ['-R', fromPath, targetPath]);
  }

  Future<void> unarchive(String archivePath, String targetPath) async {
    var result =
        await Process.run('tar', ['-xvzf', archivePath, '-C', targetPath]);
    print(result.stdout);
  }

  Future<void> process() async {
    final io.Directory appDocumentsDir =
        await getApplicationDocumentsDirectory();
    String appDocumentsDirPath = appDocumentsDir.path;

    io.Directory documentsTargetDirectory =
        io.Directory(p.join(appDocumentsDirPath, "EasyFlatpak"));

    if (!documentsTargetDirectory.existsSync()) {
      documentsTargetDirectory.createSync();

      await copyTo('assets/db/flathub_database.db',
          '${documentsTargetDirectory.path}/flathub_database.db');

      await unarchive(
          'assets/icons/Archive.tar.gz', documentsTargetDirectory.path);
    } else {
      print('already installed');
    }
  }
}
