import 'dart:convert';

import 'package:flutter/material.dart';

import 'application.dart';

class ApplicationFactory {
  static Future<List<String>> getApplicationList(context) async {
    String recipiesString =
        await DefaultAssetBundle.of(context).loadString("assets/recipies.json");
    print(recipiesString);
    List<String> recipieList = List<String>.from(json.decode(recipiesString));
    print(recipieList);
    return recipieList;
  }

  static Future<Application> getApplication(context, app) async {
    String applicaitonRecipieString = await DefaultAssetBundle.of(context)
        .loadString("assets/recipies/$app.json");

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
