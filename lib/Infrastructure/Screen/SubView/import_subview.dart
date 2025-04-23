import 'dart:convert';

import 'package:dupot_easy_flatpak/Domain/Entity/recipe/permission_overrided_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/command_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/localization_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Control/Model/SubView/override_control.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SharedComponents/Button/close_subview_button.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SharedComponents/Card/card_output_component.dart';
import 'package:flutter/material.dart';
import 'package:ini/ini.dart';
import 'package:logging/logging.dart';

class ImportSubview extends StatefulWidget {
  final Function handleGoToMore;
  final Function handleAddToCart;
  final Function handleSaveImportedPermissionOverridedEntity;

  const ImportSubview(
      {super.key,
      required this.handleGoToMore,
      required this.handleAddToCart,
      required this.handleSaveImportedPermissionOverridedEntity});

  @override
  State<ImportSubview> createState() => _ImportSubviewState();
}

class _ImportSubviewState extends State<ImportSubview> {
  static final _logger = Logger('ImportSubview');

  bool stateIsInstalling = true;
  String stateInstallationOutput = '';

  String applicationIdSelected = '';

  String appPath = '';

  final ScrollController scrollController = ScrollController();

  OverrideControl overrideControl = OverrideControl();

  @override
  void initState() {
    super.initState();

    import();
  }

  Future<Config> getOverrideConfig(applicationId) async {
    FlatpakOverrideApplication flatpakOverrideApplication =
        await CommandApi().isApplicationOverrided(applicationId);

    Config overrideConfig = Config.fromStrings(
        flatpakOverrideApplication.flatpakOutput.toString().split("\n"));

    return overrideConfig;
  }

  Future<void> import() async {
    CommandApi commands = CommandApi();

    if (!await commands.doesImportJsonFileExist()) {
      String importJsonPath = await commands.getImportJsonPath();

      setState(() {
        stateInstallationOutput = LocalizationApi().trAndReplace(
            'Missing_import_pattern_filePath', {'_filePath_': importJsonPath});
      });

      setState(() {
        stateIsInstalling = false;
      });

      return;
    }

    List<String> installedApplicationIdList =
        await commands.getInstalledApplicationList();

    String jsonData = await commands.importFromJson();

    Map<String, dynamic> installedJsonObj = jsonDecode(jsonData);

    Map<String, List<PermissionOverridedEntity>>
        importedPermissionOverridedEntityList = {};

    for (String applicationIdLoop in installedJsonObj.keys) {
      if (!installedApplicationIdList
          .contains(applicationIdLoop.toLowerCase())) {
        widget.handleAddToCart(applicationIdLoop);

        List<PermissionOverridedEntity> permissionOverrideEntityList = [];

        for (dynamic rawPermissionOverridedEntityLoop
            in installedJsonObj[applicationIdLoop]!) {
          permissionOverrideEntityList.add(PermissionOverridedEntity(
            rawPermissionOverridedEntityLoop['type']!,
            rawPermissionOverridedEntityLoop['value']!,
            rawPermissionOverridedEntityLoop['valueYesNo'],
          ));
        }

        importedPermissionOverridedEntityList[applicationIdLoop] =
            permissionOverrideEntityList;
      }
    }

    widget.handleSaveImportedPermissionOverridedEntity(
        importedPermissionOverridedEntityList);

    _logger.info('STDOUT: imported in cart');
    setState(() {
      stateInstallationOutput = importedPermissionOverridedEntityList.isNotEmpty
          ? LocalizationApi().tr('Successfully_imported_in_cart')
          : LocalizationApi().tr('Already_synced_nothing_to_import');
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
