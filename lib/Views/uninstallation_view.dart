import 'dart:convert';
import 'dart:io';

import 'package:dupot_easy_flatpak/Localizations/app_localizations.dart';
import 'package:dupot_easy_flatpak/Models/Flathub/appstream.dart';
import 'package:dupot_easy_flatpak/Models/Flathub/appstream_factory.dart';
import 'package:dupot_easy_flatpak/Models/recipe_factory.dart';
import 'package:dupot_easy_flatpak/Models/settings.dart';
import 'package:dupot_easy_flatpak/Process/commands.dart';
import 'package:dupot_easy_flatpak/Screens/Store/block.dart';
import 'package:dupot_easy_flatpak/Screens/Store/install_button.dart';
import 'package:dupot_easy_flatpak/Screens/Store/install_button_with_recipe.dart';
import 'package:dupot_easy_flatpak/Screens/Store/uninstall_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

class UninstallationView extends StatefulWidget {
  String applicationIdSelected;

  Function handleGoToApplication;

  UninstallationView({
    super.key,
    required this.applicationIdSelected,
    required this.handleGoToApplication,
  });

  @override
  State<UninstallationView> createState() => _UninstallationViewState();
}

class _UninstallationViewState extends State<UninstallationView> {
  AppStream? stateAppStream;
  bool stateIsInstalling = true;
  String stateInstallationOutput = '';

  String applicationIdSelected = '';

  String appPath = '';

  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    install();
  }

  Future<void> install() async {
    applicationIdSelected = widget.applicationIdSelected;

    AppStreamFactory appStreamFactory = AppStreamFactory();
    appPath = await appStreamFactory.getPath();

    AppStream appStream =
        await appStreamFactory.findAppStreamById(applicationIdSelected);

    setState(() {
      stateAppStream = appStream;
    });

    Settings settingsObj = Settings(context: context);
    await settingsObj.load();

    Commands command = Commands(settingsObj: settingsObj);

    String commandBin = 'flatpak';
    List<String> commandArgList = [
      'uninstall',
      '-y',
      '--system',
      applicationIdSelected
    ];

/*
    String stdout = await Commands(settingsObj: settingsObj)
        .uninstallApplicationThenOverrideList(applicationIdSelected, []);
        */

    Process.start(command.getCommand(commandBin),
            command.getFlatpakSpawnArgumentList(commandBin, commandArgList))
        .then((Process process) {
      process.stdout.transform(utf8.decoder).listen((data) {
        print('STDOUT: $data');
        setState(() {
          stateInstallationOutput = data;
        });
      });

      process.stderr.transform(utf8.decoder).listen((data) {
        print('STDERR: $data');
        setState(() {
          stateInstallationOutput = data;
        });
      });

      process.exitCode.then((exitCode) {
        print('Exit code: $exitCode');
        setState(() {
          stateInstallationOutput =
              "$stateInstallationOutput \n ${AppLocalizations.of(context).tr('uninstallation_finished')}";
          stateIsInstalling = false;
        });
      });
    }).catchError((e) {
      print('Error starting process: $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    const TextStyle outputTextStyle =
        TextStyle(color: Colors.white, fontSize: 14.0);

    return Card(
        color: Theme.of(context).cardColor,
        child: stateAppStream == null
            ? const CircularProgressIndicator()
            : Scrollbar(
                interactive: false,
                thumbVisibility: true,
                controller: scrollController,
                child: ListView(controller: scrollController, children: [
                  Row(
                    children: [
                      if (stateAppStream!.icon.length > 10)
                        Image.file(
                            File('$appPath/${stateAppStream!.getIcon()}')),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stateAppStream!.name,
                              style: const TextStyle(
                                  fontSize: 35, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            Text(
                              stateAppStream!.developer_name,
                              style:
                                  const TextStyle(fontStyle: FontStyle.italic),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            stateAppStream!.isVerified()
                                ? TextButton.icon(
                                    style: TextButton.styleFrom(
                                        padding: const EdgeInsets.only(
                                            top: 5,
                                            bottom: 5,
                                            right: 5,
                                            left: 0),
                                        alignment:
                                            AlignmentDirectional.topStart),
                                    icon: const Icon(Icons.verified),
                                    onPressed: () {},
                                    label: Text(
                                        stateAppStream!.getVerifiedLabel()))
                                : const SizedBox(),
                          ],
                        ),
                      ),
                      stateIsInstalling
                          ? const CircularProgressIndicator()
                          : getButton()
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                        constraints: const BoxConstraints(minHeight: 800),
                        decoration: const BoxDecoration(color: Colors.blueGrey),
                        child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: RichText(
                              overflow: TextOverflow.clip,
                              text: TextSpan(
                                style: outputTextStyle,
                                children: <TextSpan>[
                                  TextSpan(text: stateInstallationOutput),
                                ],
                              ),
                            ))),
                  ),
                ])));
  }

  Widget getButton() {
    ButtonStyle buttonStyle = ElevatedButton.styleFrom(
        backgroundColor: Colors.blueGrey,
        padding: const EdgeInsets.all(20),
        textStyle: const TextStyle(fontSize: 14));

    return FilledButton.icon(
      style: buttonStyle,
      onPressed: () {
        widget.handleGoToApplication(widget.applicationIdSelected);
      },
      label: Text(AppLocalizations.of(context).tr('close')),
      icon: const Icon(Icons.close),
    );
  }
}
