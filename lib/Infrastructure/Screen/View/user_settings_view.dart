import 'package:dupot_easy_flatpak/Domain/Entity/user_settings_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/View/UserSettings/Form/darkmode_form.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/View/UserSettings/Form/language_form.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/View/UserSettings/Form/parameter_page_form.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/View/UserSettings/Form/scope_form.dart';

import 'package:flutter/material.dart';

class UserSettingsView extends StatefulWidget {
  final Function handleGoTo;
  final Function handleReload;
  final Function handleReloadLanguage;

  const UserSettingsView(
      {super.key,
      required this.handleGoTo,
      required this.handleReload,
      required this.handleReloadLanguage});

  @override
  State<UserSettingsView> createState() => _UserSettingsViewState();
}

class _UserSettingsViewState extends State<UserSettingsView> {
  ScrollController scrollController = ScrollController();

  bool isUserSettingsLoaded = false;
  late UserSettingsEntity stateUserSettingsEntity;

  @override
  void initState() {
    loadData();

    super.initState();
  }

  Future<void> loadData() async {
    setState(() {
      stateUserSettingsEntity = UserSettingsEntity();
      isUserSettingsLoaded = true;
    });
  }

  updateStateUserSettings(UserSettingsEntity newUserSettings) {
    setState(() {
      stateUserSettingsEntity = newUserSettings;
    });

    widget.handleReload();
  }

  @override
  Widget build(BuildContext context) {
    //language
    //darkmode
    //scope install
    //installed app page (badge)
    return !isUserSettingsLoaded
        ? const LinearProgressIndicator()
        : Scrollbar(
            interactive: false,
            thumbVisibility: true,
            controller: scrollController,
            child: ListView(
              controller: scrollController,
              children: [
                Column(
                  children: [
                    LanguageForm(
                        userSettings: stateUserSettingsEntity,
                        handleUpdateUserSettings: updateStateUserSettings,
                        handleReloadLanguage: widget.handleReloadLanguage),
                    DarkmodeForm(
                        userSettings: stateUserSettingsEntity,
                        handleUpdateUserSettings: updateStateUserSettings),
                    ScopeForm(
                        userSettings: stateUserSettingsEntity,
                        handleUpdateUserSettings: updateStateUserSettings),
                    ParameterPageForm(
                        userSettings: stateUserSettingsEntity,
                        handleUpdateUserSettings: updateStateUserSettings)
                  ],
                )
              ],
            ));
  }
}
