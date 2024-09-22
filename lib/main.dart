import 'dart:io';
import 'dart:io';
import 'dart:io';

import 'package:dupot_easy_flatpak/Process/parameters.dart';
import 'package:dupot_easy_flatpak/dupot_easy_flatpak.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    String appDocumentsDirPath = appDocumentsDir.path;

    Directory documentsTargetDirectory =
        Directory(p.join(appDocumentsDirPath, "EasyFlatpak"));

    bool shouldCopyDb = false;

    if (!documentsTargetDirectory.existsSync()) {
      print('missing app directory, install database');
      await documentsTargetDirectory.create();

      shouldCopyDb = true;
    } else {
      print('app directory already there');

      PackageInfo packageInfo = await PackageInfo.fromPlatform();

      File buildInstalled = File('${documentsTargetDirectory.path}/build.log');

      if (buildInstalled.existsSync()) {
        String buildInfo = buildInstalled.readAsStringSync();
        if (buildInfo == packageInfo.version) {
          print('build installed is the latest ($buildInfo)');
        } else {
          print(
              'build installed $buildInfo different current ${packageInfo.version}');
          shouldCopyDb = true;
        }
      }

      Parameters('${documentsTargetDirectory.path}/parameters.json');
    }

    if (shouldCopyDb) {
      print('Start copy db');
      final bytes = await rootBundle.load('assets/db/flathub_database.db');
      final targetFile =
          File('${documentsTargetDirectory.path}/flathub_database.db');
      await targetFile.writeAsBytes(bytes.buffer.asUint8List());
      print('End copy db');
    }
    print('start application');

    sqfliteFfiInit();

    databaseFactory = databaseFactoryFfi;

    runApp(const DupotEasyFlatpak());
  } on Exception catch (e) {
    print('Exception::');
    print(e);
  }
}
