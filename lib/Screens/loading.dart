import 'package:dupot_easy_flatpak/Localizations/app_localizations.dart';
import 'package:dupot_easy_flatpak/Models/Flathub/appstream_factory.dart';
import 'package:dupot_easy_flatpak/Models/settings.dart';
import 'package:dupot_easy_flatpak/Process/commands.dart';
import 'package:dupot_easy_flatpak/Process/first_installation.dart';
import 'package:dupot_easy_flatpak/Process/flathub_api.dart';
import 'package:flutter/material.dart';

class Loading extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _Loading();
}

class _Loading extends State<Loading> {
  bool isLoaded = false;

  Future<void> processInit(BuildContext context) async {
    Settings settingsObj = Settings(context: context);
    await settingsObj.load();

    Commands commands = Commands(settingsObj: settingsObj);

    FirstInstallation firstInstallation = FirstInstallation(commands: commands);
    await firstInstallation.process();

    final appStreamFactory = AppStreamFactory();
    //await appStreamFactory.create();

    FlathubApi flathubApi = FlathubApi(appStreamFactory: appStreamFactory);
    await flathubApi.load();

    setState(() {
      isLoaded = true;
    });

    Navigator.popAndPushNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    if (!isLoaded) {
      processInit(context).then((value) {
        Navigator.popAndPushNamed(context, '/');
      });
    }

    return Text(AppLocalizations.of(context).tr("loading"));
  }
}
