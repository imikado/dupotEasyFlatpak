import 'package:dupot_easy_flatpak/Infrastructure/Api/localization_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/Theme/theme_button_style.dart';
import 'package:flutter/material.dart';

class DialogConfirmButton extends StatelessWidget {
  final Function onPressedFunction;

  const DialogConfirmButton({super.key, required this.onPressedFunction});

  @override
  Widget build(BuildContext context) {
    ThemeButtonStyle themeButtonStyle = ThemeButtonStyle(context: context);

    return FilledButton(
      style: themeButtonStyle.getDialogButtonStyle(),
      onPressed: () {
        onPressedFunction();
      },
      child: Text(LocalizationApi().tr('confirm'),
          style: themeButtonStyle.getButtonTextStyle()),
    );
  }
}
