import 'package:dupot_easy_flatpak/Domain/Entity/user_settings_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/command_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/flathub_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/localization_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Control/Process/update_from_flathub_process.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Repository/application_repository.dart';
import 'package:flutter/material.dart';

class LoadingView extends StatefulWidget {
  LoadingView({super.key, required this.handle});

  Function handle;

  @override
  State<StatefulWidget> createState() => _LoadingView();
}

class _LoadingView extends State<LoadingView> with TickerProviderStateMixin {
  bool isLoaded = false;

  double progressValue = 0.0;

  @override
  void initState() {
    super.initState();

    processInit();
  }

  Future<void> processInit() async {
    setState(() {
      progressValue = 0.1;
    });

    print('Installation');
    UpdateFromFlathubProcess updateFromFlathubProcess =
        UpdateFromFlathubProcess(commandApi: CommandApi());
    await updateFromFlathubProcess.process();
    print('End installation');

    setState(() {
      progressValue = 0.20;
    });

    final applicatoinRepository = ApplicationRepository();
    //await appStreamFactory.create();

    print('start flathub load');
    UserSettingsEntity userSettingsEntity = UserSettingsEntity();

    if (userSettingsEntity.shouldUpdateApplicationsFromApi()) {
      FlathubApi flathubApi =
          FlathubApi(applicationRepository: applicatoinRepository);
      await flathubApi.load();

      userSettingsEntity.updateLasttimeStampUpdateApplicationsFromApi();

      UserSettingsEntity().save();
    } else {
      print(
          'Last applications updates from API is newer than 7 days, not need');
    }
    print('end flathub load');

    setState(() {
      progressValue = 0.50;
    });

    if (!CommandApi().isInsideFlatpak() &&
        await CommandApi().missFlathubInFlatpak()) {
      print('need flathub');
      setState(() {
        progressValue = 0.6;
      });
      await CommandApi().setupFlathub();
    } else {
      print(' flathub ok');
    }

    await LocalizationApi().load();
    setState(() {
      progressValue = 0.7;
    });

    List<String> dbApplicationIdList =
        await applicatoinRepository.findAllApplicationIdList();

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
        backgroundColor: Theme.of(context).primaryColorLight,
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
              LinearProgressIndicator(
                value: progressValue,
                color: Theme.of(context).primaryColorDark,
              )
            ],
          ),
        ));
  }
}
