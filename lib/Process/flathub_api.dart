import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dupot_easy_flatpak/Models/Flathub/appstream.dart';
import 'package:dupot_easy_flatpak/Models/Flathub/appstream_category.dart';
import 'package:dupot_easy_flatpak/Models/Flathub/appstream_factory.dart';
import 'package:http/http.dart' as http;

import 'package:path/path.dart' as p;
import 'dart:io' as io;
import 'package:path_provider/path_provider.dart';

class FlathubApi {
  AppStreamFactory appStreamFactory;

  FlathubApi({required this.appStreamFactory});

  Future<void> updateAppStream(String applicationId) async {
    AppStream appStream = await getAppStream(applicationId);

    await appStreamFactory.updateAppStream(appStream);
  }

  Future<void> load() async {
    final io.Directory appDocumentsDir =
        await getApplicationDocumentsDirectory();

    final appDocumentsDirPath = appDocumentsDir.path;

    List<dynamic> appStreamIdList = await getAppStreamList();

    appStreamFactory.connect();

    List<String> categoryList = await appStreamFactory.findAllCategoryList();

    List<String> applicationIdList =
        await appStreamFactory.findAllApplicationIdList();

    List<AppStream> appStreamList = [];
    List<AppStreamCategory> appStreamCategoryList = [];

    int limitLoaded = 0;
    for (String appStreamIdLoop in appStreamIdList) {
      if (applicationIdList.contains(appStreamIdLoop.toLowerCase())) {
        continue;
      }
      print('$appStreamIdLoop missing, should insert');
      AppStream appStream = await getAppStream(appStreamIdLoop);

      downloadIcon(appStream, appDocumentsDirPath);

      appStreamList.add(appStream);
      /*if (!await appStreamFactory.insertAppStream(appStream)) {
        print('insert KO appstream');
      }
      */
      for (String categoryLoop in appStream.categoryIdList) {
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

  Future<void> downloadIcon(AppStream appStream, appDocumentsDirPath) async {
    String httpIconPath = appStream.icon;

    if (httpIconPath.length < 10) {
      return;
    }

    String iconName = p.basename(httpIconPath);

    Dio dioDownload = Dio();

    await dioDownload.download(
        httpIconPath, p.join(appDocumentsDirPath, 'EasyFlatpak', iconName));
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

    Map<String, dynamic> metadataObj = {};
    if (rawAppStream.containsKey('metadata')) {
      Map<String, dynamic> rawMetadata =
          Map<String, dynamic>.from(rawAppStream['metadata'] as Map);

      bool flathubVerified = false;
      if (rawMetadata.containsKey('flathub::verification::verified') &&
          rawMetadata['flathub::verification::verified'] == 'true') {
        flathubVerified = true;
      }

      metadataObj['flathub_verified'] = flathubVerified;

      if (rawMetadata.containsKey('flathub::verification::method')) {
        String method = rawMetadata['flathub::verification::method'];

        if (method == 'website') {
          metadataObj['flathub_verified_url'] =
              'https://${rawMetadata['flathub::verification::website']}';

          metadataObj['flathub_verified_label'] =
              rawMetadata['flathub::verification::website'];
        } else if (method == 'login_provider') {
          metadataObj['flathub_verified_url'] =
              'https://${rawMetadata['flathub::verification::login_provider']}.com/${rawMetadata['flathub::verification::login_name']}';

          metadataObj['flathub_verified_label'] =
              '@${rawMetadata['flathub::verification::login_name']} on ${rawMetadata['flathub::verification::login_provider']}';
        }
      }
    }

    Map<String, String> rawUrls = {};
    if (rawAppStream.containsKey('urls')) {
      rawUrls = Map<String, String>.from(rawAppStream['urls'] as Map);
    }

    List<Map<String, dynamic>> rawReleaseObjList = [];
    if (rawAppStream.containsKey('releases')) {
      rawReleaseObjList =
          List<Map<String, dynamic>>.from(rawAppStream['releases'] as List);
    }

    String developer_name = '';
    if (rawAppStream.containsKey('developer_name')) {
      developer_name = rawAppStream['developer_name'];
    }

    String projectLicense = '';
    if (rawAppStream.containsKey('project_license')) {
      projectLicense = rawAppStream['project_license'];
    }

    List<Map<String, String>> screenshotObjList = [];
    if (rawAppStream.containsKey('screenshots')) {
      List<Map<String, dynamic>> rawScreenshotList =
          List<Map<String, dynamic>>.from(rawAppStream['screenshots'] as List);

      for (Map<String, dynamic> rawScreenshotLoop in rawScreenshotList) {
        if (rawScreenshotLoop.containsKey('sizes')) {
          Map<String, String> screenshotLoop = {};
          for (Map<String, dynamic> rawSizeLoop in rawScreenshotLoop['sizes']) {
            if (int.parse(rawSizeLoop['width']) < 600) {
              screenshotLoop['preview'] = rawSizeLoop['src'];
            }
            if (int.parse(rawSizeLoop['width']) > 700) {
              screenshotLoop['large'] = rawSizeLoop['src'];
            }
          }

          if (screenshotLoop.containsKey('preview') &&
              screenshotLoop.containsKey('large')) {
            screenshotObjList.add(screenshotLoop);
          }
        }
      }
    }

    return AppStream(
        id: rawAppStream['id'],
        name: rawAppStream['name'],
        summary: rawAppStream['summary'],
        icon: icon,
        categoryIdList: categoryList,
        description: rawAppStream['description'],
        lastUpdate: DateTime.now().millisecondsSinceEpoch,
        metadataObj: metadataObj,
        urlObj: rawUrls,
        releaseObjList: rawReleaseObjList,
        projectLicense: projectLicense,
        developer_name: developer_name,
        screenshotObjList: screenshotObjList);
  }
}
