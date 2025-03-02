import 'package:dupot_easy_flatpak/Domain/Entity/db/application_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/localization_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/Theme/theme_button_style.dart';
import 'package:flutter/material.dart';

class RemoveFromCartButton extends StatelessWidget {
  final ApplicationEntity applicationEntity;
  final Function handle;
  final bool isActive;

  const RemoveFromCartButton(
      {super.key,
      required this.applicationEntity,
      required this.handle,
      required this.isActive});

  @override
  Widget build(BuildContext context) {
    ThemeButtonStyle themeButtonStyle = ThemeButtonStyle(context: context);

    return FilledButton.icon(
      style: themeButtonStyle.getButtonStyle(),
      onPressed: !isActive
          ? null
          : () {
              handle();
            },
      label: Text(LocalizationApi().tr('remove_from_cart'),
          style: themeButtonStyle.getButtonTextStyle()),
      icon: Icon(Icons.remove_shopping_cart,
          color: themeButtonStyle.getButtonTextStyle().color),
    );
  }
}
