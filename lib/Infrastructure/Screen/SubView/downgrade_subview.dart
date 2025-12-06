import 'dart:convert';
import 'dart:io';

import 'package:dupot_easy_flatpak/Infrastructure/Api/command_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/localization_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/logger_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SharedComponents/Button/close_subview_button.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SharedComponents/Card/card_output_component.dart';
import 'package:flutter/material.dart';

class DowngradeSubview extends StatefulWidget {
  final String applicationId;
  final Function handleGoToApplication;
  final String installScope;
  final String commit;

  //switch menu
  final Function handleDisableSideMenu;
  final Function handleEnableSideMenu;

  const DowngradeSubview(
      {super.key,
      required this.applicationId,
      required this.handleGoToApplication,
      required this.installScope,
      required this.commit,
      required this.handleDisableSideMenu,
      required this.handleEnableSideMenu});

  @override
  State<DowngradeSubview> createState() => _DowngradeSubviewState();
}

class _DowngradeSubviewState extends State<DowngradeSubview> {
  bool stateIsInstalling = true;
  String stateInstallationOutput = '';

  String applicationIdSelected = '';

  String appPath = '';

  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    downgrade();
  }

  Future<void> downgrade() async {
    await widget.handleDisableSideMenu();

    applicationIdSelected = widget.applicationId;

    CommandApi command = CommandApi();

//flatpak update --commit=25271a241210447920e29b31b37ba5ea6fd35b7bb3c498e7988c8e58e6397081

    String commandBin = 'flatpak';
    List<String> commandArgList = [
      'update',
      '-y',
      '--noninteractive',
      '--commit=${widget.commit}',
      widget.installScope,
      applicationIdSelected
    ];

    Process.start(command.getCommand(commandBin),
            command.getFlatpakSpawnArgumentList(commandBin, commandArgList))
        .then((Process process) {
      process.stdout.transform(utf8.decoder).listen((data) {
        LoggerApi().info('STDOUT: $data');
        setState(() {
          stateInstallationOutput = "$stateInstallationOutput\n$data";
        });
      });

      process.stderr.transform(utf8.decoder).listen((data) {
        LoggerApi().warning('STDERR: $data');
        setState(() {
          stateInstallationOutput = "$stateInstallationOutput\n\n$data";
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
                  ? SizedBox()
                  : CloseSubViewButton(handle: widget.handleGoToApplication),
              const SizedBox(width: 20)
            ],
          ),
          CardOutputComponent(outputString: stateInstallationOutput),
          const SizedBox(
            height: 10,
          ),
          stateIsInstalling
              ? Row(
                  children: [
                    Text(LocalizationApi().tr("installing")),
                    SizedBox(width: 8),
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ],
                )
              : Center(
                  child: Text(LocalizationApi().tr('installation_finished')))
        ],
      ),
    );
  }
}
