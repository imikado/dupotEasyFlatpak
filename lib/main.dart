import 'dart:convert';
import 'dart:io';

import 'package:dupot_easy_flatpak/Domain/Entity/settings_entity.dart';
import 'package:dupot_easy_flatpak/Domain/Entity/user_settings_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/command_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/localization_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/logger_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/path_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/application.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:window_manager/window_manager.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    await windowManager.ensureInitialized();

    Directory configDirectory = Directory(PathApi.getConfigPath());
    Directory cacheDirectory = Directory(PathApi.getCachePath());
    Directory logDirectory = Directory(PathApi.getLogPath());
    Directory iconsCacheDirectory = Directory(PathApi.getIconsCachePath());
    Directory importConfigDirectory = Directory(PathApi.getImportConfigPath());
    Directory exportConfigDirectory = Directory(PathApi.getExportConfigPath());

    for (Directory mandatoryDirectoryLoop in [
      configDirectory,
      cacheDirectory,
      logDirectory,
      iconsCacheDirectory,
      importConfigDirectory,
      exportConfigDirectory
    ]) {
      if (!mandatoryDirectoryLoop.existsSync()) {
        mandatoryDirectoryLoop.createSync(recursive: true);
      }
    }

    LoggerApi(File(p.join(logDirectory.path, 'application.log')));

    bool shouldCopyDb = false;
    bool shouldCopyUserSettings = false;

    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    File buildInstalled = File(PathApi.getBuildConfigPath());

    if (!buildInstalled.existsSync()) {
      shouldCopyDb = true;
      shouldCopyUserSettings = true;
    } else {
      String buildInfo = buildInstalled.readAsStringSync();
      if (buildInfo == packageInfo.version) {
        LoggerApi().info('Build installed is the latest ($buildInfo)');
      } else {
        LoggerApi().info(
            'Build installed $buildInfo different from current ${packageInfo.version}');
        shouldCopyDb = true;
      }
    }

    File userSettingsFile = File(PathApi.getUserSettingsJsonConfigPath());
    if (!userSettingsFile.existsSync()) {
      shouldCopyDb = true;
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

    if (shouldCopyDb) {
      await copyAssetFilePath('db/flathub_database.db', PathApi.getCachePath());
    }
    if (shouldCopyUserSettings) {
      await copyAssetFilePath(
          'json/userSettings.json', PathApi.getConfigPath());
    }

    UserSettingsEntity userSettings = UserSettingsEntity(userSettingsFile.path);

    if (userSettings.userOverrideLanguageCode) {
      LocalizationApi().setLanguageCode(userSettings.getUserLanguageCode());
    } else {
      LocalizationApi().setLanguageCode(Platform.localeName);
    }

    Settings settingsObj = Settings();
    await settingsObj.load();

    CommandApi(settingsObj);

    final result = await CommandApi().runProcessSync(
        'gsettings', ['get', 'org.gnome.desktop.interface', 'gtk-theme']);

    final theme = result.stdout.toString().toLowerCase();
    bool isDarkMode = theme.contains('dark');
    UserSettingsEntity().setDarkModeEnabled(isDarkMode);

    LoggerApi().info('Starting application');

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

    runApp(const Application());
  } on Exception catch (e) {
    LoggerApi().error('Exception: $e');
  }
}

Future<void> copyAssetFilePath(String filePath, String targetPath) async {
  LoggerApi().info('Starting copy of $filePath');
  final bytes = await rootBundle.load('assets/$filePath');
  final targetFile = File('$targetPath/${p.basename(filePath)}');
  await targetFile.writeAsBytes(bytes.buffer.asUint8List());
  LoggerApi().info('Finished copying $filePath');
}
