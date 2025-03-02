import 'package:dupot_easy_flatpak/Infrastructure/Api/localization_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/Theme/theme_button_style.dart';
import 'package:flutter/material.dart';

class CloseSubViewButton extends StatelessWidget {
  final Function handle;

  const CloseSubViewButton({super.key, required this.handle});

  @override
  Widget build(BuildContext context) {
    ThemeButtonStyle themeButtonStyle = ThemeButtonStyle(context: context);

    return FilledButton.icon(
      style: themeButtonStyle.getButtonStyle(),
      onPressed: () {
        handle();
      },
      label: Text(LocalizationApi().tr('close'),
          style: themeButtonStyle.getButtonTextStyle()),
      icon:
          Icon(Icons.close, color: themeButtonStyle.getButtonTextStyle().color),
    );
  }
}
