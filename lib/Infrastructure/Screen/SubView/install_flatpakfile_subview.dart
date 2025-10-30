import 'dart:convert';
import 'dart:io';

import 'package:dupot_easy_flatpak/Domain/Entity/db/application_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/command_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/localization_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/logger_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Repository/application_repository.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SharedComponents/Button/close_subview_button.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SharedComponents/Card/card_output_component.dart';
import 'package:flutter/material.dart';

class InstallFlatpakFileSubview extends StatefulWidget {
  final String flatpakId;
  final String flatpakFile;
  final Function handleGoToFlatpakFile;
  final String installScope;

  //switch menu
  final Function handleDisableSideMenu;
  final Function handleEnableSideMenu;

  const InstallFlatpakFileSubview(
      {super.key,
      required this.flatpakId,
      required this.flatpakFile,
      required this.handleGoToFlatpakFile,
      required this.installScope,
      required this.handleDisableSideMenu,
      required this.handleEnableSideMenu});

  @override
  State<InstallFlatpakFileSubview> createState() =>
      _InstallFlatpakFileSubviewState();
}

class _InstallFlatpakFileSubviewState extends State<InstallFlatpakFileSubview> {
  bool stateIsInstalling = true;
  String stateInstallationOutput = '';

  String flatpakFile = '';

  String appPath = '';

  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    install();
  }

  Future<void> install() async {
    await widget.handleDisableSideMenu();

    flatpakFile = widget.flatpakFile;

    CommandApi command = CommandApi();

    String commandBin = 'flatpak';
    List<String> commandArgList = [
      'install',
      '-y',
      '--bundle',
      widget.installScope,
      flatpakFile
    ];

    Process.start(command.getCommand(commandBin),
            command.getFlatpakSpawnArgumentList(commandBin, commandArgList))
        .then((Process process) {
      process.stdout.transform(utf8.decoder).listen((data) {
        LoggerApi().info('STDOUT: $data');
        setState(() {
          stateInstallationOutput = data;
        });
      });

      process.stderr.transform(utf8.decoder).listen((data) {
        LoggerApi().warning('STDERR: $data');
        setState(() {
          stateInstallationOutput = data;
        });
      });

      process.exitCode.then((exitCode) async {
        LoggerApi().info('Exit code: $exitCode');
        CommandApi().loadApplicationInstalledList();

        await widget.handleEnableSideMenu();

        setState(() {
          stateIsInstalling = false;
        });
      });
    }).catchError((e) {
      LoggerApi().error('Error starting process: $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      interactive: false,
      thumbVisibility: true,
      controller: scrollController,
      child: ListView(
        controller: scrollController,
        children: [
          Wrap(
            alignment: WrapAlignment.end,
            children: [
              const SizedBox(width: 20),
              stateIsInstalling
                  ? const LinearProgressIndicator()
                  : CloseSubViewButton(handle: widget.handleGoToFlatpakFile),
              const SizedBox(width: 20)
            ],
          ),
          CardOutputComponent(outputString: stateInstallationOutput),
          const SizedBox(
            height: 10,
          ),
          if (!stateIsInstalling)
            Center(child: Text(LocalizationApi().tr('installation_finished')))
        ],
      ),
    );
  }
}
