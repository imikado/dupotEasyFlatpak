import 'dart:convert';
import 'dart:io';

import 'package:adwaita/adwaita.dart';
import 'package:dupot_easy_flatpak/Domain/Entity/info_entity.dart';
import 'package:dupot_easy_flatpak/Domain/Entity/settings_entity.dart';
import 'package:dupot_easy_flatpak/Domain/Entity/user_settings_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/command_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/flathub_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/localization_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/logger_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/path_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Repository/application_repository.dart';
import 'package:dupot_easy_flatpak/Infrastructure/application.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:window_manager/window_manager.dart';

enum OpenPayloadType { flatpakBundle, flatpakRef, flatpakRepo, urlUnknown }

class OpenFilePayload {
  final OpenPayloadType type;
  final String value; // path or URL
  OpenFilePayload(this.type, this.value);
}

OpenFilePayload? parseOpenPayload(List<String> args) {
  // Accept both file paths and URLs. If your .desktop uses %u, URLs may arrive.
  // Filter out flags like 'sync'
  final candidates =
      args.where((a) => !a.startsWith('-') && a != argSync).toList();
  if (candidates.isEmpty) return null;

  // Only handle the first item for now; you can extend to multiple later.
  final input = candidates.first.trim();

  // URL case (xdg-open may pass http/https)
  final isUrl = input.startsWith('http://') || input.startsWith('https://');

  if (isUrl) {
    final uri = Uri.tryParse(input);
    if (uri == null) return null;
    // Heuristics: many .flatpakref are http(s) links
    if (uri.path.endsWith('.flatpakref')) {
      return OpenFilePayload(OpenPayloadType.flatpakRef, input);
    }
    if (uri.path.endsWith('.flatpakrepo')) {
      return OpenFilePayload(OpenPayloadType.flatpakRepo, input);
    }
    if (uri.path.endsWith('.flatpak')) {
      return OpenFilePayload(OpenPayloadType.flatpakBundle, input);
    }
    return OpenFilePayload(OpenPayloadType.urlUnknown, input);
  }

  // Local file path case
  final lower = input.toLowerCase();
  if (lower.endsWith('.flatpak')) {
    return OpenFilePayload(OpenPayloadType.flatpakBundle, input);
  }
  if (lower.endsWith('.flatpakref')) {
    return OpenFilePayload(OpenPayloadType.flatpakRef, input);
  }
  if (lower.endsWith('.flatpakrepo')) {
    return OpenFilePayload(OpenPayloadType.flatpakRepo, input);
  }

  return null;
}

bool isOsDarkMode = false;

const argSync = 'sync';

void main(List<String> args) async {
  try {
    print(args.toString());
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

    print('log directory : ${logDirectory.path}');
    LoggerApi(File(p.join(logDirectory.path, 'application.log')));
    LoggerApi().info('config directory:${configDirectory.path}');
    LoggerApi().info('cache directory:${cacheDirectory.path}');
    LoggerApi().info('icons directory:${iconsCacheDirectory.path}');

    String applicationVersion =
        await rootBundle.loadString('assets/version.txt');

    InfoEntity(applicationVersion);

    bool shouldCopyDb = false;
    bool shouldCopyUserSettings = false;

    File buildInstalled = File(PathApi.getBuildConfigPath());

    if (!buildInstalled.existsSync()) {
      shouldCopyDb = true;
      shouldCopyUserSettings = true;
    } else {
      String buildInfo = buildInstalled.readAsStringSync();
      if (buildInfo == applicationVersion) {
        LoggerApi().info('Build installed is the latest ($buildInfo)');
      } else {
        LoggerApi().info(
            'Build installed $buildInfo different from current $applicationVersion');
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

    LoggerApi().info('Starting application');

    sqfliteFfiInit();

    databaseFactory = databaseFactoryFfi;

    await windowManager.ensureInitialized();

    FlathubApi(ApplicationRepository());

    if (args.contains(argSync)) {
      print('sync');
      await FlathubApi().sync();
    }

    Size defaultResolution = Size(1200, 800);
    bool defaultFullScreen = false;
    if (UserSettingsEntity().getDefaultResolution() ==
        UserSettingsEntity.defaultResolutionFullscreen) {
      defaultResolution = Size(1100, 760);
      defaultFullScreen = true;
    } else {
      List defaultResolutionList =
          UserSettingsEntity().getDefaultResolution().split('x');

      defaultResolution = Size(double.parse(defaultResolutionList[0]),
          double.parse(defaultResolutionList[1]));
    }

    WindowOptions windowOptions = WindowOptions(
      size: defaultResolution,
      minimumSize: defaultResolution,
      skipTaskbar: false,
      fullScreen: defaultFullScreen,
      //windowButtonVisibility: true,
      backgroundColor: Colors.transparent,
      titleBarStyle: TitleBarStyle.normal,
      title: "Easy flatpak",
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      // Force apply size and position
      await windowManager.setMinimumSize(defaultResolution);
      await windowManager.setSize(defaultResolution);
      await windowManager.center(); // optional: center on screen

      await windowManager.show();
      await windowManager.focus();
    });

    final openPayload = parseOpenPayload(args);

    runApp(MyApp(initialOpenPayload: openPayload));

    //runApp(MyApp());
  } on Exception catch (e) {
    LoggerApi().error('Exception: $e');
  }
}

class MyApp extends StatelessWidget {
  final OpenFilePayload? initialOpenPayload;
  const MyApp({super.key, this.initialOpenPayload});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: UserSettingsEntity().themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: "Easy flatpak",
          builder: (context, child) {
            final virtualWindowFrame = VirtualWindowFrameInit();

            return virtualWindowFrame(context, child);
          },
          theme: AdwaitaThemeData.light(),
          darkTheme: AdwaitaThemeData.dark(),
          debugShowCheckedModeBanner: false,
          home: Application(initialOpenPayload: initialOpenPayload),
          themeMode: currentMode,
        );
      },
    );
  }
}

Future<void> copyAssetFilePath(String filePath, String targetPath) async {
  LoggerApi().info('Starting copy of $filePath');
  final bytes = await rootBundle.load('assets/$filePath');
  final targetFile = File('$targetPath/${p.basename(filePath)}');
  await targetFile.writeAsBytes(bytes.buffer.asUint8List());
  LoggerApi().info('Finished copying $filePath');
}
