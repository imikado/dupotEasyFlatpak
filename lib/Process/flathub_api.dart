import 'dart:convert';

import 'package:dupot_easy_flatpak/Models/Flathub/appstream.dart';
import 'package:dupot_easy_flatpak/Models/Flathub/appstream_category.dart';
import 'package:dupot_easy_flatpak/Models/Flathub/appstream_factory.dart';
import 'package:http/http.dart' as http;

class FlathubApi {
  AppStreamFactory appStreamFactory;

  FlathubApi({required this.appStreamFactory});

  Future<void> load() async {
    int limit = 200;

    List<dynamic> appStreamIdList = await getAppStreamList();

    appStreamFactory.connect();

    List<String> categoryList = await appStreamFactory.findAllCategoryList();

    List<String> applicationIdList =
        await appStreamFactory.findAllApplicationIdList();

    List<AppStream> appStreamList = [];
    List<AppStreamCategory> appStreamCategoryList = [];

    int limitLoaded = 0;
    for (String appStreamIdLoop in appStreamIdList) {
      if (applicationIdList.contains(appStreamIdLoop)) {
        continue;
      }
      AppStream appStream = await getAppStream(appStreamIdLoop);

      limitLoaded++;
      if (limitLoaded > limit) {
        //break;
      }

      appStreamList.add(appStream);
      /*if (!await appStreamFactory.insertAppStream(appStream)) {
        print('insert KO appstream');
      }
      */
      for (String categoryLoop in appStream.categoryList) {
        if (categoryList.contains(categoryLoop)) {
          appStreamCategoryList.add(AppStreamCategory(
              appstream_id: appStreamIdLoop, category_id: categoryLoop));
          /*
          if (!await appStreamFactory.insertAppStreamCategory(
              appStreamIdLoop, categoryLoop)) {
            print('  insert KO appStream category');
          }
          */
        }
      }
    }

    await appStreamFactory.insertAppStreamList(appStreamList);
    await appStreamFactory.insertAppStreamCategoryList(appStreamCategoryList);
  }

  Future<List<dynamic>> getAppStreamList() async {
    var apiContent =
        await http.get(Uri.parse('https://flathub.org/api/v2/appstream'));

    List<dynamic> appStreamIdList = jsonDecode(apiContent.body);
    return appStreamIdList;
  }

  Future<AppStream> getAppStream(String appSteamId) async {
    var apiContent = await http
        .get(Uri.parse('https://flathub.org/api/v2/appstream/$appSteamId'));

    Map<String, dynamic> rawAppStream = jsonDecode(apiContent.body);

    List<String> categoryList = [];
    if (rawAppStream.containsKey('categories')) {
      categoryList = List<String>.from(rawAppStream['categories'] as List);
    }

    String icon = '';
    if (rawAppStream.containsKey('icon') && rawAppStream['icon'] != null) {
      icon = rawAppStream['icon'];
    }

    return AppStream(
        id: rawAppStream['id'],
        name: rawAppStream['name'],
        summary: rawAppStream['summary'],
        icon: icon,
        categoryList: categoryList,
        description: rawAppStream['description']);
  }
}
