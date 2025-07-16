import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dupot_easy_flatpak/Domain/Entity/db/application_category_entity.dart';
import 'package:dupot_easy_flatpak/Domain/Entity/db/application_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/logger_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/path_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Repository/application_repository.dart';

import 'package:http/http.dart' as http;

import 'package:path/path.dart' as p;

class FlathubApi {
  ApplicationRepository applicationRepository;

  int loadTotalNumberOfApplication = 0;
  int loadNumberOfApplicationProcessed = 0;

  FlathubApi({required this.applicationRepository});

  Future<bool> updateAppStream(String applicationId) async {
    if (!await applicationExist(applicationId)) {
      return false;
    }

    ApplicationEntity appStream =
        await getApplicationEntityFromApi(applicationId);

    await applicationRepository.updateApplicationEntity(appStream);

    downloadIcon(appStream, PathApi.getIconsCachePath());

    return true;
  }

  Future<int> getNumberOfNewApplicationFromApi() async {
    List<String> appStreamIdList = await getRawApplicationList();

    List<String> applicationIdList =
        await applicationRepository.findAllApplicationIdList();

    int numberOfNewApplicationFromApi = 0;

    for (String appStreamIdLoop in appStreamIdList) {
      if (!applicationIdList.contains(appStreamIdLoop.toLowerCase())) {
        numberOfNewApplicationFromApi += 1;
      }
    }

    return numberOfNewApplicationFromApi;
  }

  Future<void> load({bool forceUpdateDatabase = false}) async {
    ApplicationRepository applicationRepository = ApplicationRepository();

    List<String> appStreamIdList = await getRawApplicationList();

    loadTotalNumberOfApplication = appStreamIdList.length;

    applicationRepository.connect();

    List<String> categoryList =
        await applicationRepository.findAllCategoryList();

    List<String> applicationIdList =
        await applicationRepository.findAllApplicationIdList();

    List<ApplicationEntity> appStreamList = [];
    List<ApplicationCategoryEntity> applicationCategoryEntityList = [];

    // ignore: unused_local_variable
    int limitLoaded = 0;
    for (String appStreamIdLoop in appStreamIdList) {
      if (applicationIdList.contains(appStreamIdLoop.toLowerCase())) {
        if (forceUpdateDatabase) {
          await updateAppStream(appStreamIdLoop);
        } else {
          ApplicationEntity applicationEntityLoop = await applicationRepository
              .findApplicationEntityById(appStreamIdLoop);

          if (applicationEntityLoop.lastUpdateIsOlderThan(7)) {
            await updateAppStream(appStreamIdLoop);
          }
        }
        loadNumberOfApplicationProcessed += 1;
        continue;
      }

      if (appStreamIdLoop.contains('org.freedesktop.platform')) {
        continue;
      }

      LoggerApi()
          .info('New application on flathub: ${appStreamIdLoop.toLowerCase()}');

      ApplicationEntity appStream =
          await getApplicationEntityFromApi(appStreamIdLoop);
      if (appStream.isEmpty) {
        appStream.id = appStreamIdLoop;
        LoggerApi().warning('App not found on api');
      }

      downloadIcon(appStream, PathApi.getIconsCachePath());

      appStreamList.add(appStream);

      for (String categoryLoop in appStream.categoryIdList) {
        if (categoryList.contains(categoryLoop)) {
          applicationCategoryEntityList.add(ApplicationCategoryEntity(
              appstream_id: appStreamIdLoop, category_id: categoryLoop));
        }
      }
      await Future.delayed(const Duration(seconds: 1));
      loadNumberOfApplicationProcessed += 1;
    }

    await applicationRepository.insertApplicationEntityList(appStreamList);
    await applicationRepository
        .insertApplicationCategoryList(applicationCategoryEntityList);
  }

  Future<void> downloadIcon(
      ApplicationEntity appStream, appDocumentsDirPath) async {
    String httpIconPath = appStream.httpIcon;

    if (httpIconPath.length < 10) {
      return;
    }

    Dio dioDownload = Dio();

    await dioDownload.download(httpIconPath,
        p.join(PathApi.getIconsCachePath(), appStream.getAppIcon()));
  }

  Future<List<String>> getRawApplicationList() async {
    /* var apiContent =
        await http.get(Uri.parse('https://flathub.org/api/v2/appstream'));

    List<dynamic> appStreamIdList = jsonDecode(apiContent.body);
  */

    var apiContent = await http
        .get(Uri.parse('https://flathub.org/api/v2/collection/recently-added'));

    Map<String, dynamic> rawAppApplicationAddedObj =
        jsonDecode(apiContent.body);

    List<String> appStreamIdList = [];
    for (Map<String, dynamic> rawAppApplicationAddedLoop
        in rawAppApplicationAddedObj['hits']) {
      appStreamIdList.add(rawAppApplicationAddedLoop['app_id']!);
    }

    return appStreamIdList;
  }

  Future<bool> applicationExist(String appSteamId) async {
    var apiContent = await http
        .get(Uri.parse('https://flathub.org/api/v2/appstream/$appSteamId'));

    if (apiContent.statusCode == 200) {
      return true;
    }
    return false;
  }

  Future<ApplicationEntity> getApplicationEntityFromApi(
      String appSteamId) async {
    var apiContent = await http
        .get(Uri.parse('https://flathub.org/api/v2/appstream/$appSteamId'));

    if (apiContent.statusCode == 404) {
      return ApplicationEntity.generateEmpty();
    }

    Map<String, dynamic> rawAppStream = jsonDecode(apiContent.body);

    var apiSummaryContent = await http
        .get(Uri.parse('https://flathub.org/api/v2/summary/$appSteamId'));

    Map<String, dynamic> rawAppSummary = jsonDecode(apiSummaryContent.body);

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

      if (rawAppSummary.containsKey('download_size')) {
        metadataObj['download_size'] = rawAppSummary['download_size'];
      }
      if (rawAppSummary.containsKey('installed_size')) {
        metadataObj['installed_size'] = rawAppSummary['installed_size'];
      }

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

    int lastReleaseTimestamp = 0;
    for (Map<String, dynamic> rawReleaseObjLoop in rawReleaseObjList) {
      if (rawReleaseObjLoop.containsKey('timestamp') &&
          rawReleaseObjLoop['timestamp'] != null &&
          int.parse(rawReleaseObjLoop['timestamp']) > lastReleaseTimestamp) {
        lastReleaseTimestamp = int.parse(rawReleaseObjLoop['timestamp']);
      }
    }

    // ignore: non_constant_identifier_names
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

    return ApplicationEntity(
        id: rawAppStream['id'],
        name: rawAppStream['name'],
        summary: rawAppStream['summary'],
        httpIcon: icon,
        categoryIdList: categoryList,
        description: rawAppStream['description'],
        lastUpdate: DateTime.now().millisecondsSinceEpoch,
        metadataObj: metadataObj,
        urlObj: rawUrls,
        releaseObjList: rawReleaseObjList,
        projectLicense: projectLicense,
        developer_name: developer_name,
        screenshotObjList: screenshotObjList,
        lastReleaseTimestamp: lastReleaseTimestamp);
  }
}
