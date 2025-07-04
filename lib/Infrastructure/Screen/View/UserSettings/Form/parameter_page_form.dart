import 'package:dupot_easy_flatpak/Domain/Entity/user_settings_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/localization_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Entity/radio_bool_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Entity/radio_string_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SharedComponents/SubForm/radio_bool_list_subform.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SharedComponents/SubForm/radio_string_list_subform.dart';
import 'package:flutter/material.dart';

class ParameterPageForm extends StatefulWidget {
  final UserSettingsEntity userSettings;
  final Function handleUpdateUserSettings;

  const ParameterPageForm(
      {super.key,
      required this.userSettings,
      required this.handleUpdateUserSettings});
  @override
  State<ParameterPageForm> createState() => _ParameterPageFormState();
}

class _ParameterPageFormState extends State<ParameterPageForm> {
  setDisplayApplicationInstalledNumberInSideMenu(
      bool displayNumberOfInstalledAppsInSideMenu) {
    widget.userSettings.setDisplayApplicationInstalledNumberInSideMenu(
        displayNumberOfInstalledAppsInSideMenu);

    widget.handleUpdateUserSettings(widget.userSettings);
  }

  updateWindowManager(String newWindowManager) {
    widget.userSettings.setWindowManager(newWindowManager);

    widget.handleUpdateUserSettings(widget.userSettings);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      ListTile(
        title: Text(
          LocalizationApi().tr('Display_number_of_installedapps_in_sidemenu'),
          style: TextStyle(
              color: Theme.of(context).textTheme.headlineLarge!.color),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
        child: RadioBoolListSubform(
            radioBoolEntityList: [
              RadioBoolEntity(label: 'Yes', value: true),
              RadioBoolEntity(label: 'No', value: false)
            ],
            radioGroupValue: widget.userSettings
                .getDisplayApplicationInstalledNumberInSideMenu(),
            handleUpdateValue: setDisplayApplicationInstalledNumberInSideMenu),
      ),
      ListTile(
        title: Text(
          LocalizationApi().tr('parameter_Window_manager'),
          style: TextStyle(
              color: Theme.of(context).textTheme.headlineLarge!.color),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
        child: RadioStringListSubform(
            radioStringEntityList: [
              RadioStringEntity(
                  label: 'parameter_windowManagerLibadwaita',
                  value: 'windowManagerLibadwaita'),
              RadioStringEntity(
                  label: 'parameter_windowManagerNative',
                  value: 'windowManagerNative')
            ],
            value: widget.userSettings.getWindowManager(),
            handleUpdateValue: updateWindowManager),
      )
    ]);
  }
}
