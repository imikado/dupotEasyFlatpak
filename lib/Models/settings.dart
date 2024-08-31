import 'dart:convert';

import 'package:flutter/material.dart';

class Settings {
  BuildContext context;
  late Map<String, dynamic> settingsObj;

  Settings({required this.context});

  Future<void> load() async {
    String settingsString =
        await DefaultAssetBundle.of(context).loadString("assets/settings.json");
    settingsObj = Map<String, dynamic>.from(json.decode(settingsString));
  }

  bool useFlatpakSpawn() {
    if (settingsObj.containsKey('useFlatpakSpawn')) {
      return settingsObj['useFlatpakSpawn'];
    }
    return false;
  }

  String getFlatpakSpawnCommand() {
    return 'flatpak-spawn';
  }
}
