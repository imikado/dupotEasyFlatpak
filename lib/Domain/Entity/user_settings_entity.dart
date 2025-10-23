import 'dart:convert';
import 'dart:io';

import 'package:dupot_easy_flatpak/Infrastructure/Api/path_api.dart';
import 'package:flutter/material.dart';

import 'package:window_manager/window_manager.dart';

enum AppDisplay { list, grid, table }

const List<(AppDisplay, IconData)> appDisplayOptions = <(AppDisplay, IconData)>[
  (AppDisplay.list, Icons.view_list),
  (AppDisplay.grid, Icons.view_compact),
  (AppDisplay.table, Icons.view_column),
];

class UserSettingsEntity {
  int version = 9;

  String jsonUserSettingsPath = '';

  //language
  bool userOverrideLanguageCode = false; //if not: system
  String languageCode = 'en';

  //theme
  String stringThemeMode = themeModeSystem;

  static const String themeModeSystem = 'themeModeSystem';
  static const String themeModeLight = 'themeModeLight';
  static const String themeModeDark = 'themeModeDark';

  //installation scope
  bool userInstallationScopeEnabled = false; //scope user/system

  //installed app
  bool displayApplicationInstalledNumberInSideMenu = false;
  bool displayApplicationInstalledNumberInPage = false;

  int lastUpdateFromApiTimestamp = 0;

  String displayAppsMode = displayModeList;

  static const String windowManagerNative = 'windowManagerNative';
  static const String windowManagerLibadwaita = 'windowManagerLibadwaita';
  static const String windowManagerNewInterface = 'windowManagerNewInterface';

  String windowManagerString = windowManagerLibadwaita;

  String defaultResolution = defaultResolution1200x800;

  bool useFlathubSearchApi = false;

  late ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

  static const String displayModeList = 'displayModeList';
  static const String displayModeGrid = 'displayModeGrid';
  static const String displayModeTable = 'displayModeTable';

  static const String defaultResolution800x600 = '800x600';
  static const String defaultResolution1100x760 = '1100x760';
  static const String defaultResolution1200x800 = '1200x800';
  static const String defaultResolution1400x900 = '1400x900';
  static const String defaultResolutionFullscreen = '0x0';

  static final UserSettingsEntity _singleton = UserSettingsEntity._internal();

  factory UserSettingsEntity([String? newJsonUserSettingsPath]) {
    if (newJsonUserSettingsPath != null && newJsonUserSettingsPath.isNotEmpty) {
      _singleton.jsonUserSettingsPath = newJsonUserSettingsPath;
      File jsonParametersFile = File(_singleton.jsonUserSettingsPath);
      if (jsonParametersFile.existsSync()) {
        String jsonParameterString = jsonParametersFile.readAsStringSync();
        Map<String, dynamic> jsonParameterObj = jsonDecode(jsonParameterString);
        for (String mandatoryFieldLoop in [
          'version',
          'userOverrideLanguageCode',
          'languageCode',
          'themeMode',
          'userInstallationScopeEnabled',
          'displayApplicationInstalledNumberInSideMenu',
          'displayApplicationInstalledNumberInPage',
          'windowManager',
          'useFlathubSearchApi'
        ]) {
          if (!jsonParameterObj.containsKey(mandatoryFieldLoop)) {
            throw Exception(
                'Missing mandatory userSettings $mandatoryFieldLoop field in $newJsonUserSettingsPath');
          }
        }

        _singleton.userOverrideLanguageCode =
            jsonParameterObj['userOverrideLanguageCode'];

        _singleton.stringThemeMode = jsonParameterObj['themeMode'];

        //theme mode
        _singleton.setStringThemeMode(_singleton.stringThemeMode);

        if (_singleton.userOverrideLanguageCode) {
          _singleton.languageCode = jsonParameterObj['languageCode'];
        }

        _singleton.userInstallationScopeEnabled =
            jsonParameterObj['userInstallationScopeEnabled'];

        _singleton.displayApplicationInstalledNumberInSideMenu =
            jsonParameterObj['displayApplicationInstalledNumberInSideMenu'];

        _singleton.displayApplicationInstalledNumberInPage =
            jsonParameterObj['displayApplicationInstalledNumberInPage'];

        _singleton.windowManagerString = jsonParameterObj['windowManager'];

        if (jsonParameterObj.containsKey('lastUpdateFromApiTimestamp')) {
          _singleton.lastUpdateFromApiTimestamp =
              jsonParameterObj['lastUpdateFromApiTimestamp'];
        }

        if (jsonParameterObj.containsKey('defaultResolution')) {
          _singleton.defaultResolution = jsonParameterObj['defaultResolution'];
        }

        if (jsonParameterObj.containsKey('useFlathubSearchApi')) {
          _singleton.useFlathubSearchApi =
              jsonParameterObj['useFlathubSearchApi'];
        }

        _singleton.displayAppsMode = jsonParameterObj['displayAppsMode'];
      }
    }
    return _singleton;
  }

  UserSettingsEntity._internal();

  bool shouldUpdateApplicationsFromApi() {
    int days = 7;

    if ((DateTime.now().millisecondsSinceEpoch - lastUpdateFromApiTimestamp) >
        days * 86400000) {
      return true;
    }
    return false;
  }

  String getApplicationIconsPath() {
    return PathApi.getIconsCachePath();
  }

  bool isWindowManagerNative() {
    return windowManagerString == windowManagerNative;
  }

  bool isWindowManagerLibadwaita() {
    return windowManagerString == windowManagerLibadwaita;
  }

  bool isWindowManagerNewInterface() {
    return windowManagerString == windowManagerNewInterface;
  }

  void updateLasttimeStampUpdateApplicationsFromApi() {
    lastUpdateFromApiTimestamp = DateTime.now().millisecondsSinceEpoch;
  }

  void setStringThemeMode(String newThemeMode) {
    stringThemeMode = newThemeMode;

    if (stringThemeMode == themeModeSystem) {
      _singleton.themeNotifier.value = ThemeMode.system;
    } else if (stringThemeMode == themeModeLight) {
      _singleton.themeNotifier.value = ThemeMode.light;
    } else if (stringThemeMode == themeModeDark) {
      _singleton.themeNotifier.value = ThemeMode.dark;
    } else {
      throw Exception(
          'Unexpected themeMode, expected : $themeModeSystem, $themeModeLight, $themeModeLight');
    }
  }

  Future<void> saveStringThemeMode(String newThemeMode) async {
    setStringThemeMode(newThemeMode);
    await save();
  }

  Future<void> setLanguageCode(String newLanguageCode) async {
    languageCode = newLanguageCode;
    await save();
  }

  Future<void> setWindowManager(String newWindowManager) async {
    windowManagerString = newWindowManager;

    await reloadWindowManager();

    await save();
  }

  Future<void> setDefaultResolution(String newDefaultResolution) async {
    defaultResolution = newDefaultResolution;

    await reloadWindowManager();

    await save();
  }

  reloadWindowManager() async {
    if (UserSettingsEntity().isWindowManagerLibadwaita()) {
      await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
      await windowManager.setAsFrameless();
    } else {
      await windowManager.setTitleBarStyle(TitleBarStyle.normal);
    }
  }

  String getWindowManager() {
    return windowManagerString;
  }

  Future<void> setUserOverrideLanguageCode(
      bool userOverrideLanguageCode) async {
    this.userOverrideLanguageCode = userOverrideLanguageCode;
    await save();
  }

  Future<void> setUserInstallationScopeEnabled(
      bool newUserInstallationScopeEnabled) async {
    userInstallationScopeEnabled = newUserInstallationScopeEnabled;
    await save();
  }

  Future<void> setDisplayApplicationInstalledNumberInSideMenu(
      bool displayApplicationInstalledNumberInSideMenu) async {
    this.displayApplicationInstalledNumberInSideMenu =
        displayApplicationInstalledNumberInSideMenu;
    await save();
  }

  Future<void> setDisplayApplicationInstalledNumberInPage(
      bool displayApplicationInstalledNumberInPage) async {
    this.displayApplicationInstalledNumberInPage =
        displayApplicationInstalledNumberInPage;
    await save();
  }

  Future<void> setDisplayAppsMode(AppDisplay appDisplay) async {
    if (appDisplay == AppDisplay.list) {
      displayAppsMode = displayModeList;
    } else if (appDisplay == AppDisplay.grid) {
      displayAppsMode = displayModeGrid;
    } else {
      displayAppsMode = displayModeTable;
    }
    await save();
  }

  Future<void> setUseFlathubSearchApi(bool useFlathubSearchApi_) async {
    useFlathubSearchApi = useFlathubSearchApi_;
    await save();
  }

  String getActiveLanguageCode() {
    return getUserLanguageCode();
  }

  String getUserLanguageCode() {
    return languageCode;
  }

  bool getUserInstallationScopeEnabled() {
    return userInstallationScopeEnabled;
  }

  String getInstallationScope() {
    if (userInstallationScopeEnabled) {
      return '--user';
    }
    return '--system';
  }

  bool getDisplayApplicationInstalledNumberInSideMenu() {
    return displayApplicationInstalledNumberInSideMenu;
  }

  bool getDisplayApplicationInstalledNumberInPage() {
    return displayApplicationInstalledNumberInPage;
  }

  String getDefaultResolution() {
    return defaultResolution;
  }

  AppDisplay getDisplayAppsMode() {
    if (displayAppsMode == displayModeList) {
      return AppDisplay.list;
    } else if (displayAppsMode == displayModeGrid) {
      return AppDisplay.grid;
    }
    return AppDisplay.table;
  }

  bool getUseFlathubSearchApi() {
    return useFlathubSearchApi;
  }

  Future<void> save() async {
    Map<String, dynamic> jsonParameterObj = {
      'version': version,
      'userOverrideLanguageCode': userOverrideLanguageCode,
      'languageCode': languageCode,
      'themeMode': stringThemeMode,
      'userInstallationScopeEnabled': userInstallationScopeEnabled,
      'displayApplicationInstalledNumberInSideMenu':
          displayApplicationInstalledNumberInSideMenu,
      'displayApplicationInstalledNumberInPage':
          displayApplicationInstalledNumberInPage,
      'lastUpdateFromApiTimestamp': lastUpdateFromApiTimestamp,
      'displayAppsMode': displayAppsMode,
      'windowManager': windowManagerString,
      'defaultResolution': defaultResolution,
      'useFlathubSearchApi': useFlathubSearchApi
    };

    File jsonParameterFile = File(jsonUserSettingsPath);
    JsonEncoder encoder = const JsonEncoder.withIndent('  ');
    jsonParameterFile.writeAsStringSync(encoder.convert(
      jsonParameterObj,
    ));
  }
}
