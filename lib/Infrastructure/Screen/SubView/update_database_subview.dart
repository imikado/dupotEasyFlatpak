import 'dart:async';

import 'package:dupot_easy_flatpak/Infrastructure/Api/flathub_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/localization_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Control/Model/SubView/override_control.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Repository/application_repository.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SharedComponents/Button/close_subview_button.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SharedComponents/Card/card_output_component.dart';
import 'package:flutter/material.dart';

class UpdateDatabaseSubview extends StatefulWidget {
  final Function handleGoToUpdatesAvailables;

  //switch menu
  final Function handleDisableSideMenu;
  final Function handleEnableSideMenu;

  const UpdateDatabaseSubview(
      {super.key,
      required this.handleGoToUpdatesAvailables,
      required this.handleDisableSideMenu,
      required this.handleEnableSideMenu});

  @override
  State<UpdateDatabaseSubview> createState() => _UpdateDatabaseSubviewState();
}

class _UpdateDatabaseSubviewState extends State<UpdateDatabaseSubview> {
  bool stateIsInstalling = true;
  String stateInstallationOutput = '';

  String applicationIdSelected = '';

  String appPath = '';

  final ScrollController scrollController = ScrollController();

  OverrideControl overrideControl = OverrideControl();

  @override
  void initState() {
    super.initState();

    updateDatabase();
  }

  Future<void> updateDatabase() async {
    await widget.handleDisableSideMenu();

    int numberOfNewApplicationFromApi =
        await FlathubApi().getNumberOfNewApplicationFromApi();

    setState(() {
      stateInstallationOutput =
          LocalizationApi().tr('Start_update_application_database');
    });

    // Start periodic progress updater
    Timer? progressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        stateInstallationOutput = LocalizationApi().trAndReplace(
          'Application_processing',
          {
            '_numberProcessed_':
                FlathubApi().loadNumberOfApplicationProcessed.toString(),
            '_numberTotal_':
                FlathubApi().loadTotalNumberOfApplication.toString(),
            '_numberApplicationsAdded_':
                FlathubApi().numberOfApplicationAdded.toString(),
            '_numberTotalApplicationToAdd_':
                numberOfNewApplicationFromApi.toString(),
            '_numberApplicationUpdated_':
                FlathubApi().numberOfApplicationUpdated.toString()
          },
        );
      });
    });

    // Run the long task
    await FlathubApi().load(forceUpdateDatabase: false);

    // Cancel the timer when done
    progressTimer.cancel();

    setState(() {
      stateInstallationOutput =
          LocalizationApi().tr('Application_database_up_to_date');
    });

    await widget.handleEnableSideMenu();

    setState(() {
      stateIsInstalling = false;
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
                  : CloseSubViewButton(
                      handle: widget.handleGoToUpdatesAvailables),
              const SizedBox(width: 20)
            ],
          ),
          CardOutputComponent(outputString: stateInstallationOutput),
          const SizedBox(
            height: 10,
          ),
          if (!stateIsInstalling)
            Center(
                child: Text(
                    LocalizationApi().tr('Application_database_up_to_date')))
        ],
      ),
    );
  }
}
