import 'package:dupot_easy_flatpak/Domain/Entity/user_settings_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/localization_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Entity/radio_bool_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SharedComponents/SubForm/radio_bool_list_subform.dart';
import 'package:flutter/material.dart';

class FlathubapiForm extends StatefulWidget {
  final UserSettingsEntity userSettings;
  final Function handleUpdateUserSettings;

  const FlathubapiForm(
      {super.key,
      required this.userSettings,
      required this.handleUpdateUserSettings});

  @override
  State<FlathubapiForm> createState() => _FlathubapiFormState();
}

class _FlathubapiFormState extends State<FlathubapiForm> {
  updateFlathubApi(bool flathubApiEnabled) {
    widget.userSettings.setFlathubApiEnabled(flathubApiEnabled);

    widget.handleUpdateUserSettings(widget.userSettings);
  }

  updateFlathubApiEnabled(bool flathubApiEnabled) {
    widget.userSettings.setFlathubApiEnabled(flathubApiEnabled);
    widget.handleUpdateUserSettings(widget.userSettings);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      ListTile(
        title: Text(
          LocalizationApi().tr('FlathubApiEnabled'),
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
              radioGroupValue: widget.userSettings.getFlathubApiEnabled(),
              handleUpdateValue: updateFlathubApiEnabled))
    ]);
  }
}
