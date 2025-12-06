import 'package:dupot_easy_flatpak/Domain/Entity/db/application_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/command_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/localization_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/Theme/theme_button_style.dart';
import 'package:flutter/material.dart';

class RunButton extends StatelessWidget {
  final ApplicationEntity applicationEntity;
  final bool isActive;

  const RunButton(
      {super.key, required this.applicationEntity, required this.isActive});

  @override
  Widget build(BuildContext context) {
    ThemeButtonStyle themeButtonStyle = ThemeButtonStyle(context: context);

    return FilledButton.icon(
      style: themeButtonStyle.getButtonStyle(),
      onPressed: !isActive
          ? null
          : () {
              CommandApi().run(applicationEntity.id);
            },
      label: Text(LocalizationApi().tr('Run'),
          style: themeButtonStyle.getButtonTextStyle()),
      icon: Icon(Icons.launch,
          color: themeButtonStyle.getButtonTextStyle().color),
    );
  }
}
