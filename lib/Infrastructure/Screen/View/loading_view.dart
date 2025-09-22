import 'package:dupot_easy_flatpak/Domain/Entity/user_settings_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/command_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/flathub_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/localization_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/logger_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Control/Process/update_from_flathub_process.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Repository/application_repository.dart';
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
      progressValue = 0.8;
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

    final applicatoinRepository = ApplicationRepository();

    LoggerApi().info('Starting flathub load');
    setState(() {
      stateLoadingInfo = LocalizationApi()
          .tr('loading_Should_update_application_list_from_Flathub_api');
    });

    LoggerApi().info('Flathub load complete');

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
        await applicatoinRepository.findAllApplicationIdList();

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

    setState(() {
      progressValue = 1;
    });

    widget.handle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).secondaryHeaderColor,
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
                value: progressValue,
                color: Theme.of(context).primaryColorDark,
              ),
              SizedBox(
                height: 10,
              ),
              Text(stateLoadingInfo)
            ],
          ),
        ));
  }
}
