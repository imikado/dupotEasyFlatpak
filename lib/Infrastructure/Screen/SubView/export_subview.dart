import 'dart:convert';

import 'package:dupot_easy_flatpak/Domain/Entity/db/application_entity.dart';
import 'package:dupot_easy_flatpak/Domain/Entity/recipe/permission_entity.dart';
import 'package:dupot_easy_flatpak/Domain/Entity/recipe/permission_overrided_entity.dart';
import 'package:dupot_easy_flatpak/Domain/Entity/recipe/recipe_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/command_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/localization_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/recipe_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Control/Model/SubView/override_control.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Repository/application_repository.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SharedComponents/Button/close_subview_button.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SharedComponents/Card/card_output_component.dart';
import 'package:flutter/material.dart';
import 'package:ini/ini.dart';
import 'package:logging/logging.dart';

class ExportSubview extends StatefulWidget {
  final Function handleGoToMore;

  const ExportSubview({
    super.key,
    required this.handleGoToMore,
  });

  @override
  State<ExportSubview> createState() => _ExportSubviewState();
}

class _ExportSubviewState extends State<ExportSubview> {
  static final _logger = Logger('ExportSubview');

  bool stateIsInstalling = true;
  String stateInstallationOutput = '';

  String applicationIdSelected = '';

  String appPath = '';

  final ScrollController scrollController = ScrollController();

  OverrideControl overrideControl = OverrideControl();

  @override
  void initState() {
    super.initState();

    export();
  }

  Future<Config> getOverrideConfig(applicationId) async {
    FlatpakOverrideApplication flatpakOverrideApplication =
        await CommandApi().isApplicationOverrided(applicationId);

    Config overrideConfig = Config.fromStrings(
        flatpakOverrideApplication.flatpakOutput.toString().split("\n"));

    return overrideConfig;
  }

  Future<void> export() async {
    CommandApi commands = CommandApi();

    List<String> installedApplicationIdList =
        await commands.getInstalledApplicationList();

    ApplicationRepository applicationRepository = ApplicationRepository();
    List<ApplicationEntity> applicationEntityList = await applicationRepository
        .findListApplicationEntityByIdList(installedApplicationIdList);

    Map<String, List<PermissionOverridedEntity>>
        overrideSetupListByApplicationId = {};

    for (ApplicationEntity applicationEntityLoop in applicationEntityList) {
      OverrideControl overrideControl = OverrideControl();
      String applicationIdLoop = applicationEntityLoop.id;

      FlatpakOverrideApplication flatpakOverrideApplication =
          await CommandApi().isApplicationOverrided(applicationIdLoop);

      if (flatpakOverrideApplication.isOverrided) {
        await overrideControl.loadOverrideConfig(applicationIdLoop);

        RecipeEntity recipeLoop =
            await RecipeApi().getApplication(applicationIdLoop);

        List<PermissionEntity> recipePermissionList =
            recipeLoop.getFlatpakPermissionToOverrideList();

        List<PermissionOverridedEntity> permissionOverridedEntityList = [];

        for (PermissionEntity permissionRecipeEntityLoop
            in recipePermissionList) {
          if (permissionRecipeEntityLoop.isFileSystem()) {
            String valueLoop = await overrideControl
                .getOverridedConfig(permissionRecipeEntityLoop.type);

            permissionOverridedEntityList.add(PermissionOverridedEntity(
                permissionRecipeEntityLoop.type, valueLoop));
          } else if (permissionRecipeEntityLoop.isInstallFlatpakYesNo()) {
          } else if (permissionRecipeEntityLoop.isEnvYesNo()) {
            String valueYesNo = 'no';
            if (await overrideControl.hasOverridedConfig(
                permissionRecipeEntityLoop.type,
                permissionRecipeEntityLoop.value.toString())) {
              String textValue = await overrideControl.getOverridedSubConfig(
                  permissionRecipeEntityLoop.type,
                  permissionRecipeEntityLoop.value.toString());

              if (textValue == permissionRecipeEntityLoop.subValueYes) {
                valueYesNo = PermissionOverridedEntity.constSubValueTrue;
              }
            }

            permissionOverridedEntityList.add(PermissionOverridedEntity(
                permissionRecipeEntityLoop.type,
                permissionRecipeEntityLoop.value,
                valueYesNo));
          }
        }

        overrideSetupListByApplicationId[applicationIdLoop] =
            permissionOverridedEntityList;
      } else {
        overrideSetupListByApplicationId[applicationIdLoop] = [];
      }
    }

    String data = jsonEncode(overrideSetupListByApplicationId);

    String fileWritten = await CommandApi().exportInstalled(data);

    _logger.info('STDOUT: $data');
    setState(() {
      stateInstallationOutput = LocalizationApi().trAndReplace(
          'Exported_to_pattern_filePath', {'_filePath_': fileWritten});
    });

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
                  : CloseSubViewButton(handle: widget.handleGoToMore),
              const SizedBox(width: 20)
            ],
          ),
          CardOutputComponent(outputString: stateInstallationOutput),
          const SizedBox(
            height: 10,
          ),
          if (!stateIsInstalling)
            Center(child: Text(LocalizationApi().tr('export_finished')))
        ],
      ),
    );
  }
}
