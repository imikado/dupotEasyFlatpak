import 'dart:convert';
import 'dart:io';

import 'package:dupot_easy_flatpak/Localizations/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import 'recipe.dart';

class RecipeFactory {
  late BuildContext context;

  static final RecipeFactory _singleton = RecipeFactory._internal();

  factory RecipeFactory([BuildContext? newContext]) {
    if (newContext != null) {
      _singleton.context = newContext;
    }
    return _singleton;
  }

  RecipeFactory._internal();

  static bool isDebug = true;

  Future<List<String>> getApplicationList() async {
    String recipiesString =
        await DefaultAssetBundle.of(context).loadString("assets/recipies.json");
    List<String> recipeList = List<String>.from(json.decode(recipiesString));

    final directory = await getApplicationDocumentsDirectory();

    final subDirectory = Directory('${directory.path}/EasyFlatpak');

    if (await subDirectory.exists()) {
      var fileList = subDirectory.listSync();
      for (var fileLoop in fileList) {
        recipeList.add(
            path.basename(fileLoop.path).toString().replaceAll('.json', ''));
      }
    }

    List<String> recipeLowerCaseList = [];
    for (String recipeId in recipeList) {
      recipeLowerCaseList.add(recipeId.toLowerCase());
    }

    return recipeLowerCaseList;
  }

  Future<Recipe> getApplication(id) async {
    final languageCode = AppLocalizations().getLanguageCode();

    print('languageCode:$languageCode');

    final directory = await getApplicationDocumentsDirectory();

    final subDirectory = Directory('${directory.path}/EasyFlatpak');

    String applicaitonRecipieString = '';

    File userFile = File('${subDirectory.path}/$id.json');
    if (await userFile.exists()) {
      applicaitonRecipieString = await userFile.readAsString();
    } else {
      applicaitonRecipieString = await DefaultAssetBundle.of(context)
          .loadString("assets/recipies/$id.json");
    }

    Map jsonApp = json.decode(applicaitonRecipieString);

    List<dynamic> rawList = jsonApp['flatpakPermissionToOverrideList'];

    if (jsonApp.containsKey('description_$languageCode')) {
      jsonApp['description'] = jsonApp['description_$languageCode'];
    }

    List<Map<String, dynamic>> objectList = [];
    for (Map<String, dynamic> rawLoop in rawList) {
      if (rawLoop.containsKey('label_$languageCode')) {
        rawLoop['label'] = rawLoop['label_$languageCode'];
      }
      objectList.add(rawLoop);
    }

    Recipe applicationLoaded = Recipe(id, objectList);

    return applicationLoaded;
  }
}
