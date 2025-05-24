import 'dart:io';

import 'package:dupot_easy_flatpak/Domain/Entity/application_update_entity.dart';
import 'package:dupot_easy_flatpak/Domain/Entity/db/application_entity.dart';
import 'package:dupot_easy_flatpak/Domain/Entity/user_settings_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/command_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/localization_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Entity/navigation_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Repository/application_repository.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SharedComponents/Button/update_all_button.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SharedComponents/Button/update_button.dart';
import 'package:flutter/material.dart';

class UpdatesAvailablesView extends StatefulWidget {
  final Function handleGoTo;
  final bool isMain;

  const UpdatesAvailablesView(
      {super.key, required this.handleGoTo, required this.isMain});

  @override
  State<UpdatesAvailablesView> createState() => _UpdatesAvailablesViewState();
}

class _UpdatesAvailablesViewState extends State<UpdatesAvailablesView> {
  List<ApplicationUpdate> stateApplicationUpdateList = [];
  List<ApplicationEntity> stateApplicationEntityList = [];

  Map<String, bool> stateCheckboxList = {};

  ScrollController scrollController = ScrollController();

  @override
  void initState() {
    loadData();

    super.initState();
  }

  Future<void> loadData() async {
    Map<String, bool> checkboxList = {};

    List<ApplicationUpdate> applicationUpdateList =
        await CommandApi().checkUpdates();

    List<ApplicationUpdate> distinctApplicationUpdateList = [];

    List<String> applicationUpdateIdList = [];
    for (ApplicationUpdate applicationUpdateLoop in applicationUpdateList) {
      if (!applicationUpdateIdList.contains(applicationUpdateLoop.id)) {
        applicationUpdateIdList.add(applicationUpdateLoop.id);

        checkboxList[applicationUpdateLoop.id] = false;

        distinctApplicationUpdateList.add(applicationUpdateLoop);
      }
    }

    List<ApplicationEntity> applicationEntityList =
        await ApplicationRepository()
            .findListApplicationEntityByIdList(applicationUpdateIdList);

    setState(() {
      stateCheckboxList = checkboxList;

      stateApplicationUpdateList = distinctApplicationUpdateList;
      stateApplicationEntityList = applicationEntityList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: stateApplicationUpdateList.isEmpty
                ? []
                : [
                    getUpdateAllButton(),
                    const SizedBox(
                      width: 10,
                    ),
                    getUpdateButton()
                  ],
          )),
      Expanded(
          child: ListView(
              controller: scrollController,
              children: stateApplicationUpdateList.isEmpty
                  ? [
                      SizedBox(
                        height: 150,
                      ),
                      Center(child: Text(LocalizationApi().tr('NoUpdates')))
                    ]
                  : stateApplicationUpdateList
                      .map((ApplicationUpdate applicationUpdate) =>
                          getLine(applicationUpdate))
                      .toList()))
    ]);
  }

  ApplicationEntity? getApplicationEntity(String id) {
    for (ApplicationEntity appLoop in stateApplicationEntityList) {
      if (appLoop.id.toLowerCase() == id.toLowerCase()) {
        return appLoop;
      }
    }
    return null;
  }

  Widget getLine(ApplicationUpdate applicationUpdate) {
    ApplicationEntity? applicationEntityFound =
        getApplicationEntity(applicationUpdate.id);

    return Card(
        color: Theme.of(context).primaryColorLight,
        child: CheckboxListTile(
          visualDensity: VisualDensity(horizontal: 0, vertical: -4),
          onChanged: (bool? value) {
            Map<String, bool> checkboxList = stateCheckboxList;

            checkboxList[applicationUpdate.id] = value!;

            setState(() {
              stateCheckboxList = checkboxList;
            });
          },
          enabled: applicationEntityFound != null,
          value: stateCheckboxList[applicationUpdate.id],
          title: Column(
            spacing: 0,
            children: [
              Row(
                children: [
                  applicationEntityFound == null ||
                          !applicationEntityFound.hasAppIcon()
                      ? Image.asset('assets/images/no-image.png', height: 60)
                      : Image.file(
                          height: 60,
                          File(
                              '${UserSettingsEntity().getApplicationIconsPath()}/${applicationEntityFound.getAppIcon()}')),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      spacing: 0,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          applicationEntityFound != null
                              ? applicationEntityFound.getName()
                              : applicationUpdate.id,
                          style: TextStyle(
                              fontSize: 20,
                              color: Theme.of(context)
                                  .textTheme
                                  .headlineLarge!
                                  .color),
                        ),
                        Text(
                            applicationEntityFound != null
                                ? applicationEntityFound.getSummary()
                                : '',
                            style: TextStyle(fontSize: 14)),
                        Text(applicationUpdate.version,
                            style: TextStyle(fontSize: 14))
                      ],
                    ),
                  )
                ],
              ),
            ],
          ),
        ));
  }

  Widget getUpdateButton() {
    return UpdateButton(
      isActive: widget.isMain,
      handle: () {
        List<String> applicationIdSelectedList = [];

        for (ApplicationUpdate applicationUpdateLoop
            in stateApplicationUpdateList) {
          if (stateCheckboxList[applicationUpdateLoop.id]!) {
            applicationIdSelectedList.add(applicationUpdateLoop.id);
          }
        }

        if (applicationIdSelectedList.isNotEmpty) {
          NavigationEntity.goToUpdatesAvailablesPocessing(
              handleGoTo: widget.handleGoTo,
              applicationIdSelectedList: applicationIdSelectedList);
        }
      },
    );
  }

  Widget getUpdateAllButton() {
    return UpdateAllButton(
      isActive: widget.isMain,
      handle: () {
        NavigationEntity.goToUpdatesAvailablesPocessingAll(
          handleGoTo: widget.handleGoTo,
        );
      },
    );
  }
}
