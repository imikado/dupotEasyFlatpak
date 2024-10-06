import 'dart:convert';
import 'dart:io';

import 'package:dupot_easy_flatpak/Localizations/app_localizations.dart';
import 'package:dupot_easy_flatpak/Models/Flathub/appstream.dart';
import 'package:dupot_easy_flatpak/Models/Flathub/appstream_factory.dart';
import 'package:dupot_easy_flatpak/Process/commands.dart';
import 'package:flutter/material.dart';

class UpdateView extends StatefulWidget {
  String applicationIdSelected;

  Function handleGoToApplication;

  UpdateView({
    super.key,
    required this.applicationIdSelected,
    required this.handleGoToApplication,
  });

  @override
  State<UpdateView> createState() => _UpdateViewState();
}

class _UpdateViewState extends State<UpdateView> {
  AppStream? stateAppStream;
  bool stateIsInstalling = true;
  String stateInstallationOutput = '';

  String applicationIdSelected = '';

  String appPath = '';

  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    update();
  }

  Future<void> update() async {
    applicationIdSelected = widget.applicationIdSelected;

    AppStreamFactory appStreamFactory = AppStreamFactory();
    appPath = await appStreamFactory.getPath();

    AppStream appStream =
        await appStreamFactory.findAppStreamById(applicationIdSelected);

    setState(() {
      stateAppStream = appStream;
    });

    Commands command = Commands();

    String commandBin = 'flatpak';
    List<String> commandArgList = [
      'update',
      '-y',
      '--system',
      applicationIdSelected
    ];

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
        Commands().checkUpdates();
        setState(() {
          stateInstallationOutput =
              "$stateInstallationOutput \n ${AppLocalizations().tr('update_finished')}";
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

    return stateAppStream == null
        ? const CircularProgressIndicator()
        : Card(
            color: Theme.of(context).cardColor,
            child: Scrollbar(
              interactive: false,
              thumbVisibility: true,
              controller: scrollController,
              child: ListView(
                controller: scrollController,
                children: [
                  Row(
                    children: [
                      if (stateAppStream!.icon.length > 10)
                        Image.file(
                            File(appPath + '/' + stateAppStream!.getIcon())),
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
                ],
              ),
            ));
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
      label: Text(AppLocalizations().tr('close')),
      icon: const Icon(Icons.close),
    );
  }
}
