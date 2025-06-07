import 'dart:io';

import 'package:path/path.dart' as p;

class PathApi {
  static String appPath = 'Easyflatpak';
  static String installedJsonFilename = 'installed_apps.json';

  static String getDataPath() {
    if (!Platform.environment.containsKey('XDG_DATA_HOME')) {
      return p.join(Platform.environment['HOME']!, '.data');
    }
    return Platform.environment['XDG_DATA_HOME']!;
  }

  static String getCachePath() {
    return getDataPath();
  }

  static String getConfigPath() {
    if (!Platform.environment.containsKey('XDG_CONFIG_HOME')) {
      return p.join(Platform.environment['HOME']!, '.config');
    }

    return Platform.environment['XDG_CONFIG_HOME']!;
  }

  static String getLogPath() {
    return getDataPath();
  }

  static String getImportConfigPath() {
    return p.join(getConfigPath(), 'Import');
  }

  static String getExportConfigPath() {
    return p.join(getConfigPath(), 'Export');
  }

  static String getImportJsonConfigPath() {
    return p.join(getImportConfigPath(), installedJsonFilename);
  }

  static String getExportJsonConfigPath() {
    return p.join(getExportConfigPath(), installedJsonFilename);
  }

  static String getUserSettingsJsonConfigPath() {
    return p.join(getConfigPath(), 'userSettings.json');
  }

  static String getIconsCachePath() {
    return p.join(getCachePath(), 'Icons');
  }

  static String getBuildConfigPath() {
    return p.join(getConfigPath(), 'build.log');
  }

  static String getDbCachePath() {
    return p.join(getCachePath(), 'flathub_database.db');
  }
}
