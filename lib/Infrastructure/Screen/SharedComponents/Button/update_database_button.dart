import 'package:dupot_easy_flatpak/Infrastructure/Api/localization_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SharedComponents/Button/dialog_cancel_button.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SharedComponents/Button/dialog_confirm_button.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/Theme/theme_button_style.dart';
import 'package:flutter/material.dart';

class UpdateDatabaseButton extends StatelessWidget {
  final Function handle;
  final bool isActive;
  final Widget? badgeWidget;

  const UpdateDatabaseButton(
      {super.key,
      required this.handle,
      required this.isActive,
      required this.badgeWidget});

  @override
  Widget build(BuildContext context) {
    ThemeButtonStyle themeButtonStyle = ThemeButtonStyle(context: context);

    return FilledButton.icon(
      style: themeButtonStyle.getButtonStyle(),
      onPressed: !isActive
          ? null
          : () {
              showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                        backgroundColor: Theme.of(context).secondaryHeaderColor,
                        buttonPadding: const EdgeInsets.all(10),
                        actions: [
                          const DialogCancelButton(),
                          DialogConfirmButton(onPressedFunction: () {
                            Navigator.of(context).pop();

                            handle();
                          })
                        ],
                        title: Text(LocalizationApi().tr('confirmation_title')),
                        contentPadding: const EdgeInsets.all(20.0),
                        content: Text(LocalizationApi()
                            .tr('do_you_confirm_flathub_sync')),
                      ));
            },
      label: Row(children: [
        Text(LocalizationApi().tr('Update_database_from_flathubapi'),
            style: themeButtonStyle.getButtonTextStyle()),
        SizedBox(
          width: 10,
        ),
        if (badgeWidget != null) badgeWidget!
      ]),
      icon: Icon(Icons.update,
          color: themeButtonStyle.getButtonTextStyle().color),
    );
  }
}
