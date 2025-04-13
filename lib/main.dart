import 'dart:convert';
import 'dart:io';

import 'package:dupot_easy_flatpak/Domain/Entity/settings_entity.dart';
import 'package:dupot_easy_flatpak/Domain/Entity/user_settings_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/command_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/localization_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/application.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:window_manager/window_manager.dart';
import 'package:logging/logging.dart';

final _logger = Logger('Main');

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    await windowManager.ensureInitialized();

    final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    String appDocumentsDirPath = appDocumentsDir.path;

    Directory applicationDataDirectory =
        Directory(p.join(appDocumentsDirPath, "EasyFlatpak"));

    Directory applicationDataIconsDirectory =
        Directory(p.join(applicationDataDirectory.path, "icons"));

    bool shouldCopyDb = false;
    bool shouldCopyUserSettings = false;

    if (!applicationDataDirectory.existsSync()) {
      _logger.info('Missing app directory, installing database');
      await applicationDataDirectory.create();

      await applicationDataIconsDirectory.create();

      shouldCopyDb = true;
      shouldCopyUserSettings = true;
    } else {
      _logger.info('App directory already exists');

      if (!applicationDataIconsDirectory.existsSync()) {
        await applicationDataIconsDirectory.create();
      }

      PackageInfo packageInfo = await PackageInfo.fromPlatform();

      File buildInstalled = File('${applicationDataDirectory.path}/build.log');

      if (buildInstalled.existsSync()) {
        String buildInfo = buildInstalled.readAsStringSync();
        if (buildInfo == packageInfo.version) {
          _logger.info('Build installed is the latest ($buildInfo)');
        } else {
          _logger.info(
              'Build installed $buildInfo different from current ${packageInfo.version}');
          shouldCopyDb = true;
        }
      }

      File userSettingsFile =
          File('${applicationDataDirectory.path}/userSettings.json');
      if (!userSettingsFile.existsSync()) {
        shouldCopyUserSettings = true;
      } else {
        String userSettingsString = userSettingsFile.readAsStringSync();
        Map<String, dynamic> userSettingsObj = jsonDecode(userSettingsString);

        String jsonDefaultUserSettingsString =
            await rootBundle.loadString('assets/json/userSettings.json');
        Map<String, dynamic> defaultUserSettingObj =
            jsonDecode(jsonDefaultUserSettingsString);
        if (!userSettingsObj.containsKey('version')) {
          shouldCopyUserSettings = true;
        } else if (defaultUserSettingObj['version'] == 2 &&
            userSettingsObj['version'] == 1) {
          userSettingsObj['flathubApiEnabled'] = true;
        } else if (defaultUserSettingObj['version'] !=
            userSettingsObj['version']) {
          shouldCopyUserSettings = true;
        }
      }
    }

    if (shouldCopyDb) {
      await copyAssetFilePath(
          'db/flathub_database.db', applicationDataDirectory.path);
    }
    if (shouldCopyUserSettings) {
      await copyAssetFilePath(
          'json/userSettings.json', applicationDataDirectory.path);
    }

    File userSettingsFile =
        File('${applicationDataDirectory.path}/userSettings.json');
    if (!userSettingsFile.existsSync()) {
      throw Exception('Unable to find UserSettings.json');
    }

    UserSettingsEntity userSettings = UserSettingsEntity(userSettingsFile.path);
    userSettings.setApplicationDataPath(applicationDataDirectory.path);

    if (userSettings.userOverrideLanguageCode) {
      LocalizationApi().setLanguageCode(userSettings.getUserLanguageCode());
    } else {
      LocalizationApi().setLanguageCode(Platform.localeName);
    }

    Settings settingsObj = Settings();
    settingsObj.load().then((value) {
      CommandApi(settingsObj);
    });

    _logger.info('Starting application');

    sqfliteFfiInit();

    databaseFactory = databaseFactoryFfi;

    WindowOptions windowOptions = WindowOptions(
      size: Size(1280, 800),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });

    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      stderr.writeln('${record.level.name}: ${record.time}: ${record.message}');
    });

    runApp(const Application());
  } on Exception catch (e) {
    _logger.severe('Exception:', e);
  }
}

Future<void> copyAssetFilePath(String filePath, String targetPath) async {
  _logger.info('Starting copy of $filePath');
  final bytes = await rootBundle.load('assets/$filePath');
  final targetFile = File('$targetPath/${p.basename(filePath)}');
  await targetFile.writeAsBytes(bytes.buffer.asUint8List());
  _logger.info('Finished copying $filePath');
}
