import 'dart:convert';
import 'dart:io';

import 'package:dupot_easy_flatpak/Infrastructure/Api/command_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/localization_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/logger_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Entity/navigation_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SharedComponents/Button/close_subview_button.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SharedComponents/Card/card_output_component.dart';
import 'package:flutter/material.dart';

class UpdateAvailableProcessingAllSubview extends StatefulWidget {
  final Function handleGoTo;

  const UpdateAvailableProcessingAllSubview({
    super.key,
    required this.handleGoTo,
  });

  @override
  State<UpdateAvailableProcessingAllSubview> createState() =>
      _UpdateAvailableProcessingSubviewState();
}

class _UpdateAvailableProcessingSubviewState
    extends State<UpdateAvailableProcessingAllSubview> {
  bool stateIsInstalling = true;
  String stateInstallationOutput = '';

  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    updateAll();
  }

  Future<void> updateAll() async {
    CommandApi command = CommandApi();

    String commandBin = 'flatpak';
    List<String> commandArgList = [
      'update',
      '-y',
      //UserSettingsEntity().getInstallationScope(),
    ];

    Process process = await Process.start(command.getCommand(commandBin),
        command.getFlatpakSpawnArgumentList(commandBin, commandArgList));

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

    process.exitCode.then((exitCode) {
      LoggerApi().info('Exit code: $exitCode');

      CommandApi().checkUpdates().then((value) {
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
                  : CloseSubViewButton(handle: () {
                      NavigationEntity.goToUpdatesAvailables(
                          handleGoTo: widget.handleGoTo);
                    }),
              const SizedBox(width: 20)
            ],
          ),
          CardOutputComponent(outputString: stateInstallationOutput),
          const SizedBox(
            height: 10,
          ),
          if (!stateIsInstalling)
            Center(child: Text(LocalizationApi().tr('update_finished')))
        ],
      ),
    );
  }
}
