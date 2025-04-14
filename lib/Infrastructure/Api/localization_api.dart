import 'dart:convert';

import 'package:flutter/services.dart';

class LocalizationApi {
  static final LocalizationApi _singleton = LocalizationApi._internal();

  factory LocalizationApi({String newLanguageCode = ''}) {
    if (newLanguageCode.isNotEmpty &&
        _localizedValues.containsKey(newLanguageCode)) {
      _singleton.languageCode = newLanguageCode;
    }
    return _singleton;
  }

  Future<void> load() async {
    for (String languageLoop in languages()) {
      String recipiesString = await rootBundle
          .loadString("assets/localizations/$languageLoop.json");
      _localizedValues[languageLoop] =
          Map<String, String>.from(json.decode(recipiesString));
    }
  }

  void setLanguageCode(String newLanguageCode) {
    if (newLanguageCode.contains('_')) {
      List<String> newLanguageCodeList = newLanguageCode.split('_');
      newLanguageCode = newLanguageCodeList[0];
    }

    if (_localizedValues.containsKey(newLanguageCode)) {
      languageCode = newLanguageCode;
    }
  }

  LocalizationApi._internal();

  String languageCode = 'en';

  static final _localizedValues = <String, Map<String, String>>{
    'en': {},
    'fr': {},
    'it': {},
    'es': {},
    'br': {},
    'ar': {}
  };

  static List<String> languages() => _localizedValues.keys.toList();

  String tr(String key) {
    if (!_localizedValues.containsKey(languageCode)) {
      throw Exception(
          'Missing languageCode "$languageCode" in localization when ask tr("$key") ');
    } else if (!_localizedValues[languageCode]!.containsKey(key)) {
      throw Exception(
          'Missing localization for key: $key in language $languageCode');
    }
    return _localizedValues[languageCode]![key]!;
  }

  String getLanguageCode() {
    return languageCode;
  }
}
