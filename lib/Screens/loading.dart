import 'package:dupot_easy_flatpak/Models/Flathub/appstream_factory.dart';
import 'package:dupot_easy_flatpak/Process/commands.dart';
import 'package:dupot_easy_flatpak/Process/first_installation.dart';
import 'package:dupot_easy_flatpak/Process/flathub_api.dart';
import 'package:dupot_easy_flatpak/Process/parameters.dart';
import 'package:flutter/material.dart';

class Loading extends StatefulWidget {
  Loading({required this.handle});

  late Function handle;

  @override
  State<StatefulWidget> createState() => _Loading();
}

class _Loading extends State<Loading> {
  bool isLoaded = false;

  Future<void> processInit() async {
    Commands commands = Commands();

    print('Installation');
    FirstInstallation firstInstallation = FirstInstallation(commands: commands);
    await firstInstallation.process();
    print('End installation');

    final appStreamFactory = AppStreamFactory();
    //await appStreamFactory.create();

    FlathubApi flathubApi = FlathubApi(appStreamFactory: appStreamFactory);
    await flathubApi.load();

    if (!commands.isInsideFlatpak() && await commands.missFlathubInFlatpak()) {
      print('need flathub');
      await commands.setupFlathub();
    } else {
      print(' flathub ok');
    }

    await commands.checkUpdates();

    setState(() {
      isLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!isLoaded) {
      processInit().then((value) {
        widget.handle();
      });
    }

    return Scaffold(
        backgroundColor: const Color.fromARGB(255, 205, 230, 250),
        body: Center(
          child: Column(
            children: [Image.asset('assets/logos/512x512.png')],
          ),
        ));
  }
}
