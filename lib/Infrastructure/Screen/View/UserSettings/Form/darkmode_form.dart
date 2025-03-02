import 'package:dupot_easy_flatpak/Domain/Entity/user_settings_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/localization_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Entity/radio_bool_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SharedComponents/SubForm/radio_bool_list_subform.dart';
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
  updateDarkMode(bool darkmodeEnabled) {
    widget.userSettings.setDarkModeEnabled(darkmodeEnabled);

    widget.handleUpdateUserSettings(widget.userSettings);
  }

  updateOverrideDarkMode(bool override) {
    widget.userSettings.setUserOverrideDarkMode(override);
    widget.handleUpdateUserSettings(widget.userSettings);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text(
            LocalizationApi().tr('DarkMode'),
            style: TextStyle(
                color: Theme.of(context).textTheme.headlineLarge!.color),
          ),
        ),
        Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
            child: Column(
              children: <Widget>[
                RadioBoolListSubform(
                    radioBoolEntityList: [
                      // RadioBoolEntity(
                      //    label: 'Use_system_darkmode', value: false),
                      RadioBoolEntity(label: 'Override_darkmode', value: true)
                    ],
                    radioGroupValue:
                        widget.userSettings.userOverrideDarkModeEnabled,
                    handleUpdateValue: updateOverrideDarkMode),
                if (widget.userSettings.userOverrideDarkModeEnabled)
                  Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
                      child: RadioBoolListSubform(
                          radioBoolEntityList: [
                            RadioBoolEntity(label: 'Yes', value: true),
                            RadioBoolEntity(label: 'No', value: false)
                          ],
                          radioGroupValue:
                              widget.userSettings.getUserDarkModeEnabled(),
                          handleUpdateValue: updateDarkMode)),
              ],
            )),
      ],
    );
  }
}
