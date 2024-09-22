import 'dart:convert';
import 'dart:io';

class Parameters {
  late bool isLoaded = false;
  String jsonParametersPath = '';

  String languageCode = 'en';
  bool darkModeEnabled = false;

  static final Parameters _singleton = Parameters._internal();

  factory Parameters([String? newJsonParametersPath]) {
    if (newJsonParametersPath != null && newJsonParametersPath.isNotEmpty) {
      _singleton.jsonParametersPath = newJsonParametersPath;
      File jsonParametersFile = File(_singleton.jsonParametersPath);
      if (jsonParametersFile.existsSync()) {
        String jsonParameterString = jsonParametersFile.readAsStringSync();
        Map<String, dynamic> jsonParameterObj = jsonDecode(jsonParameterString);
        if (jsonParameterObj.containsKey('languageCode')) {
          _singleton.languageCode = jsonParameterObj['languageCode'];
        }
        if (jsonParameterObj.containsKey('darkModeEnabled')) {
          _singleton.darkModeEnabled = jsonParameterObj['darkModeEnabled'];
        }
      }
    }
    return _singleton;
  }

  Parameters._internal();

  Future<void> setLanguageCode(String newLanguageCode) async {
    languageCode = newLanguageCode;
    await save();
  }

  Future<void> setDarModeEnabled(bool newDarkModeEnabled) async {
    darkModeEnabled = newDarkModeEnabled;
    await save();
  }

  String getLanguageCode() {
    return languageCode;
  }

  bool getDarkModeEnabled() {
    return darkModeEnabled;
  }

  Future<void> save() async {
    Map<String, dynamic> jsonParameterObj = {
      'languageCode': languageCode,
      'darkModeEnabled': darkModeEnabled
    };

    File jsonParameterFile = File(jsonParametersPath);
    jsonParameterFile.writeAsStringSync(jsonEncode(jsonParameterObj));
  }
}
