import 'package:dupot_easy_flatpak/Domain/Entity/user_settings_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/localization_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Entity/radio_string_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SharedComponents/SubForm/radio_string_list_subform.dart';
import 'package:flutter/material.dart';

class LanguageForm extends StatefulWidget {
  final UserSettingsEntity userSettings;
  final Function handleUpdateUserSettings;
  final Function handleReloadLanguage;

  const LanguageForm(
      {super.key,
      required this.userSettings,
      required this.handleUpdateUserSettings,
      required this.handleReloadLanguage});

  @override
  State<LanguageForm> createState() => _LanguageFormState();
}

class _LanguageFormState extends State<LanguageForm> {
  updateLanguage(String language) {
    widget.userSettings.setLanguageCode(language);

    widget.handleUpdateUserSettings(widget.userSettings);

    if (widget.userSettings.userOverrideLanguageCode) {
      LocalizationApi().setLanguageCode(language);
    }
  }

  updateOverrideLanguage(bool override) {
    widget.userSettings.setUserOverrideLanguageCode(override);
    widget.handleUpdateUserSettings(widget.userSettings);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text(
            LocalizationApi().tr('Language'),
            style: TextStyle(
                color: Theme.of(context).textTheme.headlineLarge!.color),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
          child: Column(
            children: <Widget>[
              ListTile(
                titleTextStyle: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.headlineLarge!.color),
                title: Text(LocalizationApi().tr('Use_system_language')),
                leading: Radio<bool>(
                  value: false,
                  groupValue: widget.userSettings.userOverrideLanguageCode,
                  onChanged: (bool? value) {
                    updateOverrideLanguage(false);
                  },
                ),
              ),
              ListTile(
                titleTextStyle: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.headlineLarge!.color),
                title: Text(LocalizationApi().tr('Override_language')),
                leading: Radio<bool>(
                  value: true,
                  groupValue: widget.userSettings.userOverrideLanguageCode,
                  onChanged: (bool? value) {
                    updateOverrideLanguage(true);
                  },
                ),
              ),
              if (widget.userSettings.userOverrideLanguageCode)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
                  child: RadioStringListSubform(
                      radioStringEntityList: [
                        RadioStringEntity(label: 'English', value: 'en'),
                        RadioStringEntity(label: 'French', value: 'fr'),
                        RadioStringEntity(label: 'Italian', value: 'it'),
                        RadioStringEntity(label: 'Spanish', value: 'es'),
                        RadioStringEntity(label: 'Brazilian', value: 'br'),
                        RadioStringEntity(label: 'Arabic', value: 'ar'),
                        RadioStringEntity(label: 'Romanian', value: 'ro'),
                      ],
                      value: widget.userSettings.getUserLanguageCode(),
                      handleUpdateValue: updateLanguage),
                )
            ],
          ),
        )
      ],
    );
  }
}
