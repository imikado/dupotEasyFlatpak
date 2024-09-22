import 'dart:io' as io;
import 'package:dupot_easy_flatpak/Process/commands.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:archive/archive_io.dart';

import 'dart:io';

class FirstInstallation {
  late Commands commands;

  FirstInstallation({required this.commands});

  Future<void> mkdir(String path) async {
    io.ProcessResult result =
        await commands.runProcessSync('/usr/bin/mkdir', [path]);
    print(result.stdout);
    print(result.stderr);
  }

  Future<void> copyTo(String fromPath, String targetPath) async {
    io.ProcessResult result = await commands.runProcessSync(
      '/usr/bin/cp',
      [fromPath, targetPath],
    );
    print(result.stdout);
    print(result.stderr);
  }

  Future<void> unarchive(String archivePath, String targetPath) async {
    final inputStream = InputFileStream(archivePath);
    final archive = ZipDecoder().decodeBuffer(inputStream);

    await extractArchiveToDisk(archive, targetPath);
  }

  Future<void> process() async {
    final io.Directory appDocumentsDir =
        await getApplicationDocumentsDirectory();
    String appDocumentsDirPath = appDocumentsDir.path;

    io.Directory documentsTargetDirectory =
        io.Directory(p.join(appDocumentsDirPath, "EasyFlatpak"));

    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    io.File buildInstalled = File('${documentsTargetDirectory.path}/build.log');

    if (buildInstalled.existsSync()) {
      String buildInfo = buildInstalled.readAsStringSync();
      if (buildInfo == packageInfo.version) {
        return;
      } else {
        print(
            'build installed $buildInfo different current ${packageInfo.version}');
      }
    }

    print('install icons');

    String targetIconsArchive = '${documentsTargetDirectory.path}/Archive.zip';

    await copyAssetTo('assets/icons/Archive.zip', targetIconsArchive);

    await unarchive(targetIconsArchive, documentsTargetDirectory.path);

    buildInstalled.writeAsStringSync(packageInfo.version);
  }

  Future<void> copyAssetTo(String assetPath, String targetPath) async {
    final bytes = await rootBundle.load(assetPath);
    final targetFile = File(targetPath);
    await targetFile.writeAsBytes(bytes.buffer.asUint8List());
  }
}
