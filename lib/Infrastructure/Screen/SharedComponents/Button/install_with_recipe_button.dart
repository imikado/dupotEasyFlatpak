import 'package:dupot_easy_flatpak/Domain/Entity/db/application_entity.dart';
import 'package:dupot_easy_flatpak/Domain/Entity/user_settings_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/localization_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SharedComponents/Button/dialog_cancel_button.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SharedComponents/Button/dialog_confirm_button.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/Theme/theme_button_style.dart';
import 'package:flutter/material.dart';

class InstallWithRecipeButton extends StatefulWidget {
  final ApplicationEntity applicationEntity;
  final Function handle;
  final bool isActive;

  const InstallWithRecipeButton(
      {super.key,
      required this.applicationEntity,
      required this.handle,
      required this.isActive});

  @override
  State<InstallWithRecipeButton> createState() =>
      _InstallWithRecipeButtonState();
}

class _InstallWithRecipeButtonState extends State<InstallWithRecipeButton> {
  bool loaded = false;

  @override
  Widget build(BuildContext context) {
    ThemeButtonStyle themeButtonStyle = ThemeButtonStyle(context: context);

    bool stateUserInstallationScopeEnabled = false;

    if (!loaded) {
      setState(() {
        stateUserInstallationScopeEnabled =
            UserSettingsEntity().getUserInstallationScopeEnabled();
        loaded = true;
      });
    }

    return FilledButton.icon(
      style: themeButtonStyle.getButtonStyle(),
      onPressed: !widget.isActive
          ? null
          : () {
              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return StatefulBuilder(
                        builder: (context, StateSetter setState) {
                      return AlertDialog(
                        buttonPadding: const EdgeInsets.all(10),
                        actions: [
                          const DialogCancelButton(),
                          DialogConfirmButton(onPressedFunction: () {
                            Navigator.of(context).pop();

                            widget.handle(stateUserInstallationScopeEnabled);
                          })
                        ],
                        title: Text(LocalizationApi().tr('confirmation_title')),
                        contentPadding: const EdgeInsets.all(20.0),
                        content: SizedBox(
                            height: 250,
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '${LocalizationApi().tr('do_you_confirm_installation_of')} ${widget.applicationEntity.getName()} ?',
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 20,
                                ),
                                Column(children: [
                                  ListTile(
                                    title: Text(
                                      LocalizationApi()
                                          .tr('Installation_scope'),
                                      style: TextStyle(
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          10, 0, 0, 0),
                                      child: Row(
                                        children: [
                                          Switch(
                                            value:
                                                stateUserInstallationScopeEnabled,
                                            onChanged: (bool value) {
                                              setState(() {
                                                stateUserInstallationScopeEnabled =
                                                    value;
                                              });
                                            },
                                          ),
                                          Text(
                                            LocalizationApi().tr('scopeUser'),
                                          )
                                        ],
                                      ))
                                ])
                              ],
                            )),
                      );
                    });
                  });
            },
      label: Text(LocalizationApi().tr('install_with_recipe'),
          style: themeButtonStyle.getButtonTextStyle()),
      icon: Icon(Icons.install_desktop,
          color: themeButtonStyle.getButtonTextStyle().color),
    );
  }
}
