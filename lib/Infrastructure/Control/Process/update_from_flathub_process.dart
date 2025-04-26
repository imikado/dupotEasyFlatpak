import 'dart:io' as io;
import 'package:dupot_easy_flatpak/Domain/Entity/user_settings_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/command_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/logger_api.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:archive/archive_io.dart';

import 'dart:io';

class UpdateFromFlathubProcess {
  CommandApi commandApi;

  UpdateFromFlathubProcess({required this.commandApi});

  Future<void> mkdir(String path) async {
    await commandApi.runProcessSync('/usr/bin/mkdir', [path]);
  }

  Future<void> copyTo(String fromPath, String targetPath) async {
    await commandApi.runProcessSync(
      '/usr/bin/cp',
      [fromPath, targetPath],
    );
  }

  Future<void> unarchive(String archivePath, String targetPath) async {
    final inputStream = InputFileStream(archivePath);
    final archive = ZipDecoder().decodeStream(inputStream);

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
        LoggerApi().info(
            'Build installed $buildInfo different from current ${packageInfo.version}');
      }
    }

    LoggerApi().info('Installing icons');

    String targetIconsArchive = '${documentsTargetDirectory.path}/Archive.zip';

    await copyAssetTo('assets/icons/Archive.zip', targetIconsArchive);

    await unarchive(
        targetIconsArchive, UserSettingsEntity().getApplicationIconsPath());

    buildInstalled.writeAsStringSync(packageInfo.version);
  }

  Future<void> copyAssetTo(String assetPath, String targetPath) async {
    final bytes = await rootBundle.load(assetPath);
    final targetFile = File(targetPath);
    await targetFile.writeAsBytes(bytes.buffer.asUint8List());
  }
}
