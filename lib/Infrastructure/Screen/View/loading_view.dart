import 'dart:convert';

import 'package:dupot_easy_flatpak/Domain/Entity/db/apicache_entity.dart';
import 'package:dupot_easy_flatpak/Domain/Entity/user_settings_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/command_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/flathub_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/localization_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/logger_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Control/Process/update_from_flathub_process.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Repository/application_repository.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SharedComponents/Button/choice_no_button.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SharedComponents/Button/choice_yes_button.dart';
import 'package:flutter/material.dart';

class LoadingView extends StatefulWidget {
  final Function handle;

  const LoadingView({super.key, required this.handle});

  @override
  State<StatefulWidget> createState() => _LoadingView();
}

class _LoadingView extends State<LoadingView> with TickerProviderStateMixin {
  bool isLoaded = false;

  double progressValue = 0.0;

  String stateLoadingInfo = '';
  bool stateDisplayChoiceUpdate = false;

  bool shouldSyncFromApi = false;

  @override
  void initState() {
    super.initState();

    processInit();
  }

  Future<void> processInit() async {
    setState(() {
      progressValue = 0.1;
    });

    await LocalizationApi().load();
    setState(() {
      progressValue = 0.15;
    });

    setState(() {
      stateLoadingInfo = LocalizationApi().tr('loading_Check_installation');
    });

    LoggerApi().info('Starting installation');
    UpdateFromFlathubProcess updateFromFlathubProcess =
        UpdateFromFlathubProcess(commandApi: CommandApi());
    await updateFromFlathubProcess.process();
    LoggerApi().info('Installation complete');

    setState(() {
      stateLoadingInfo = LocalizationApi().tr('loading_Installation_ok');
    });

    setState(() {
      progressValue = 0.20;
    });

    LoggerApi().info('Starting flathub load');

    final applicationRepository = ApplicationRepository();

    ApiCacheEntity parametersRow =
        await applicationRepository.findApiCacheById('parameters');
    Map<String, dynamic> parametersObj = jsonDecode(parametersRow.content);
    int lastApiSyncTimeStamp = parametersObj['lastApiSyncTimeStamp'];

    if (UserSettingsEntity().shouldSyncApi(lastApiSyncTimeStamp)) {
      setState(() {
        stateLoadingInfo = LocalizationApi()
            .tr('loading_Should_update_application_list_from_Flathub_api');

        stateDisplayChoiceUpdate = true;
      });
    } else {
      processNext();
    }
  }

  Future<void> processNext() async {
    final applicationRepository = ApplicationRepository();

    setState(() {
      stateLoadingInfo = LocalizationApi()
          .tr('loading_Starting_update_application_list_from_Flathub_api');
    });
    if (shouldSyncFromApi) {
      await FlathubApi().getRawRecentApplicationList();
      setState(() {
        progressValue = 0.30;
      });

      await FlathubApi().load();

      LoggerApi().info('Flathub load complete');
    } else {
      LoggerApi().info('Flathub sync skipped');
    }
    setState(() {
      progressValue = 0.50;
    });

    if (await CommandApi().missFlathubInFlatpak()) {
      LoggerApi().info('Need flathub setup');
      setState(() {
        progressValue = 0.6;
      });
      await CommandApi().setupFlathub();
    } else {
      LoggerApi().info('Flathub already setup');
    }

    List<String> dbApplicationIdList =
        await applicationRepository.findAllApplicationIdList();

    setState(() {
      stateLoadingInfo =
          LocalizationApi().tr('loading_Looking_for_applications_updates');
    });
    CommandApi().setDbApplicationIdList(dbApplicationIdList);
    await CommandApi().loadApplicationInstalledList();
    setState(() {
      progressValue = 0.8;
    });
    await CommandApi().checkUpdates();

    FlathubApi flathubApi = FlathubApi();

    setState(() {
      stateLoadingInfo =
          LocalizationApi().tr('loading_recently_update_from_api');
    });

    if (shouldSyncFromApi) {
      //recently updated
      List<String> recentlyUpdatedApplicationIdList =
          await flathubApi.getUpdatedRawApplicationIdList();

      ApiCacheEntity recentlyUpdatedApiCacheEntity = ApiCacheEntity(
          id: 'recentlyUpdatedApi',
          content: jsonEncode(recentlyUpdatedApplicationIdList));

      await applicationRepository
          .updateApiCacheById(recentlyUpdatedApiCacheEntity);
    }

    setState(() {
      stateLoadingInfo = LocalizationApi().tr('loading_popular_from_api');
    });

    if (shouldSyncFromApi) {
      //popular
      List<String> popularApplicationIdList =
          await flathubApi.getPopularRawApplicationIdList();

      ApiCacheEntity popularApiCacheEntity = ApiCacheEntity(
          id: 'popularApi', content: jsonEncode(popularApplicationIdList));

      await applicationRepository.updateApiCacheById(popularApiCacheEntity);
    }

    setState(() {
      stateLoadingInfo = LocalizationApi().tr('loading_trending_from_api');
    });

    if (shouldSyncFromApi) {
      //trending
      List<String> trendingApplicationIdList =
          await flathubApi.getTrendingRawApplicationIdList();

      ApiCacheEntity trendingApiCacheEntity = ApiCacheEntity(
          id: 'trendingApi', content: jsonEncode(trendingApplicationIdList));

      await applicationRepository.updateApiCacheById(trendingApiCacheEntity);
    }

    if (shouldSyncFromApi) {
      await applicationRepository.updateApiCacheById(ApiCacheEntity(
          id: 'parameters',
          content: jsonEncode({
            'lastApiSyncTimeStamp': UserSettingsEntity().getTodayTimeStamp()
          })));
    }

    setState(() {
      progressValue = 1;
    });

    widget.handle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: Column(
        children: [
          const SizedBox(
            height: 200,
          ),
          Image.asset(
            'assets/logos/splash.png',
            width: 200,
          ),
          const SizedBox(
            height: 10,
          ),
          LinearProgressIndicator(
            minHeight: 20,
            value: progressValue,
            color: Theme.of(context).primaryColorDark,
            backgroundColor: Theme.of(context).secondaryHeaderColor,
          ),
          SizedBox(
            height: 10,
          ),
          Text(stateLoadingInfo),
          SizedBox(
            height: 30,
          ),
          if (stateDisplayChoiceUpdate)
            Row(
              children: [
                Spacer(),
                ChoiceNoButton(handle: () {
                  stateDisplayChoiceUpdate = false;
                  shouldSyncFromApi = false;
                  processNext();
                }),
                SizedBox(width: 20),
                ChoiceYesButton(handle: () {
                  stateDisplayChoiceUpdate = false;
                  shouldSyncFromApi = true;
                  processNext();
                }),
                Spacer()
              ],
            )
        ],
      ),
    ));
  }
}
