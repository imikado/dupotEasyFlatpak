import 'package:dupot_easy_flatpak/Domain/Entity/user_settings_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/localization_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Entity/radio_string_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SharedComponents/SubForm/radio_string_list_subform.dart';
import 'package:flutter/material.dart';

class DarkmodeForm extends StatefulWidget {
  final UserSettingsEntity userSettings;
  final Function handleUpdateUserSettings;

  const DarkmodeForm(
      {super.key,
      required this.userSettings,
      required this.handleUpdateUserSettings});

  @override
  State<DarkmodeForm> createState() => _DarkmodeFormState();
}

class _DarkmodeFormState extends State<DarkmodeForm> {
  updateThemeMode(String newThemeMode) {
    widget.userSettings.saveStringThemeMode(newThemeMode);
    widget.handleUpdateUserSettings(widget.userSettings);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text(
            LocalizationApi().tr('parameter_thememode'),
            style: TextStyle(
                color: Theme.of(context).textTheme.headlineLarge!.color),
          ),
        ),
        Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
            child: Column(
              children: <Widget>[
                RadioStringListSubform(
                    radioStringEntityList: [
                      RadioStringEntity(
                          label: 'parameter_thememode_system',
                          value: UserSettingsEntity.themeModeSystem),
                      RadioStringEntity(
                          label: 'parameter_thememode_light',
                          value: UserSettingsEntity.themeModeLight),
                      RadioStringEntity(
                          label: 'parameter_thememode_dark',
                          value: UserSettingsEntity.themeModeDark),
                    ],
                    value: widget.userSettings.stringThemeMode,
                    handleUpdateValue: updateThemeMode),
              ],
            )),
      ],
    );
  }
}
