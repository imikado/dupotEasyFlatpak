import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import 'application.dart';

class ApplicationFactory {
  static bool isDebug = true;

  static Future<List<String>> getApplicationList(context) async {
    String recipiesString =
        await DefaultAssetBundle.of(context).loadString("assets/recipies.json");
    List<String> recipieList = List<String>.from(json.decode(recipiesString));

    final directory = await getApplicationDocumentsDirectory();

    final subDirectory = Directory('${directory.path}/EasyFlatpak');

    if (await subDirectory.exists()) {
      var fileList = await subDirectory.listSync();
      for (var fileLoop in fileList) {
        recipieList.add(
            path.basename(fileLoop.path).toString().replaceAll('.json', ''));
      }
    }

    if (isDebug) {
      print(recipieList);
    }

    return recipieList;
  }

  static Future<Application> getApplication(context, app) async {
    final directory = await getApplicationDocumentsDirectory();

    final subDirectory = Directory('${directory.path}/EasyFlatpak');

    String applicaitonRecipieString = '';

    File userFile = File('${subDirectory.path}/$app.json');
    if (await userFile.exists()) {
      applicaitonRecipieString = await userFile.readAsString();
    } else {
      applicaitonRecipieString = await DefaultAssetBundle.of(context)
          .loadString("assets/recipies/$app.json");
    }

    Map jsonApp = json.decode(applicaitonRecipieString);

    List<dynamic> rawList = jsonApp['flatpakPermissionToOverrideList'];

    List<Map<String, dynamic>> objectList = [];
    for (Map<String, dynamic> rawLoop in rawList) {
      objectList.add(rawLoop);
    }

    Application applicationLoaded = Application(jsonApp['title'],
        jsonApp['description'], jsonApp['flatpak'], objectList);

    return applicationLoaded;
  }
}
