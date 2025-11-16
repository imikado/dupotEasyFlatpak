import 'package:dupot_easy_flatpak/Infrastructure/Api/localization_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/Theme/theme_button_style.dart';
import 'package:flutter/material.dart';

class DialogCancelButton extends StatelessWidget {
  const DialogCancelButton({super.key});

  @override
  Widget build(BuildContext context) {
    ThemeButtonStyle themeButtonStyle = ThemeButtonStyle(context: context);

    return FilledButton(
        style: themeButtonStyle.getDialogButtonStyle(),
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: Text(LocalizationApi().tr('cancel'),
            style: themeButtonStyle.getButtonTextStyle()));
  }
}
