import 'dart:convert';

import 'package:dupot_easy_flatpak/Domain/Entity/recipe/recipe_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/localization_api.dart';
import 'package:flutter/services.dart';

class RecipeApi {
  static bool isDebug = true;

  Future<List<String>> getRecipeApplicationIdList() async {
    String recipiesString = await rootBundle.loadString("assets/recipies.json");
    return List<String>.from(json.decode(recipiesString));
  }

  Future<List<String>> getApplicationList() async {
    List<String> recipeList = await getRecipeApplicationIdList();

    List<String> recipeLowerCaseList = [];
    for (String recipeId in recipeList) {
      recipeLowerCaseList.add(recipeId.toLowerCase());
    }

    return recipeLowerCaseList;
  }

  Future<bool> hasApplication(String id) async {
    List<String> recipeList = await getRecipeApplicationIdList();

    return recipeList.contains(id);
  }

  Future<RecipeEntity> getApplication(id) async {
    final languageCode = LocalizationApi().getLanguageCode();

    String applicaitonRecipieString = '';

    applicaitonRecipieString =
        await rootBundle.loadString("assets/recipies/$id.json");

    Map jsonApp = json.decode(applicaitonRecipieString);

    List<dynamic> rawList = jsonApp['flatpakPermissionToOverrideList'];

    if (jsonApp.containsKey('description_$languageCode')) {
      jsonApp['description'] = jsonApp['description_$languageCode'];
    }

    List<Map<String, dynamic>> objectList = [];
    for (Map<String, dynamic> rawLoop in rawList) {
      objectList.add(rawLoop);
    }

    RecipeEntity applicationLoaded = RecipeEntity(id, objectList);

    return applicationLoaded;
  }
}
