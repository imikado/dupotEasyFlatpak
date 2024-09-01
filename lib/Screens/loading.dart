import 'package:dupot_easy_flatpak/Localizations/app_localizations.dart';
import 'package:dupot_easy_flatpak/Models/Flathub/appstream_factory.dart';
import 'package:dupot_easy_flatpak/Models/settings.dart';
import 'package:dupot_easy_flatpak/Process/commands.dart';
import 'package:dupot_easy_flatpak/Process/first_installation.dart';
import 'package:dupot_easy_flatpak/Process/flathub_api.dart';
import 'package:flutter/material.dart';

class Loading extends StatefulWidget {
  Loading({required this.handle});

  late Function handle;

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
  }

  @override
  Widget build(BuildContext context) {
    if (!isLoaded) {
      processInit(context).then((value) {
        widget.handle();
      });
    }

    return Scaffold(
        backgroundColor: Color.fromARGB(255, 205, 230, 250),
        body: Center(
          child: Column(
            children: [Image.asset('assets/logos/512x512.png')],
          ),
        ));
  }
}
