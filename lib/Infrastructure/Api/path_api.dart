import 'dart:io';

import 'package:path/path.dart' as p;

class PathApi {
  static String appPath = 'Easyflatpak';
  static String installedJsonFilename = 'installed_apps.json';

  static String getHomePath() {
    return Platform.environment['HOME']!;
  }

  static String getCachePath() {
    return p.join(getHomePath(), '.cache', appPath);
  }

  static String getConfigPath() {
    return p.join(getHomePath(), '.config', appPath);
  }

  static String getLogPath() {
    return p.join(getHomePath(), '.log', appPath);
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
