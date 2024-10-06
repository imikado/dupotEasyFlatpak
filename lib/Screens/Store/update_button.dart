import 'package:dupot_easy_flatpak/Localizations/app_localizations.dart';
import 'package:dupot_easy_flatpak/Models/Flathub/appstream.dart';
import 'package:flutter/material.dart';

class UpdateButton extends StatelessWidget {
  const UpdateButton(
      {super.key,
      required this.buttonStyle,
      required this.dialogButtonStyle,
      required this.stateAppStream,
      required this.handle});

  final ButtonStyle buttonStyle;
  final ButtonStyle dialogButtonStyle;

  final AppStream? stateAppStream;
  final Function handle;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: buttonStyle,
      onPressed: () {
        handle(stateAppStream!.id);
      },
      label: Text(AppLocalizations().tr('Update')),
      icon: const Icon(Icons.update),
    );
  }
}
