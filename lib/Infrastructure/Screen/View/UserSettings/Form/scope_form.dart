import 'package:dupot_easy_flatpak/Domain/Entity/user_settings_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/localization_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Entity/radio_bool_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SharedComponents/SubForm/radio_bool_list_subform.dart';
import 'package:flutter/material.dart';

class ScopeForm extends StatefulWidget {
  final UserSettingsEntity userSettings;
  final Function handleUpdateUserSettings;

  const ScopeForm(
      {super.key,
      required this.userSettings,
      required this.handleUpdateUserSettings});
  @override
  State<ScopeForm> createState() => _ScopeFormState();
}

class _ScopeFormState extends State<ScopeForm> {
  updateUserInstallationScope(bool userInstallationScope) {
    widget.userSettings.setUserInstallationScopeEnabled(userInstallationScope);

    widget.handleUpdateUserSettings(widget.userSettings);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      ListTile(
        title: Text(
          LocalizationApi().tr('Installation_scope'),
          style: TextStyle(
              color: Theme.of(context).textTheme.headlineLarge!.color),
        ),
      ),
      Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
          child: RadioBoolListSubform(
              radioBoolEntityList: [
                RadioBoolEntity(label: 'scopeSystem', value: false),
                RadioBoolEntity(label: 'scopeUser', value: true)
              ],
              radioGroupValue:
                  widget.userSettings.getUserInstallationScopeEnabled(),
              handleUpdateValue: updateUserInstallationScope))
    ]);
  }
}
