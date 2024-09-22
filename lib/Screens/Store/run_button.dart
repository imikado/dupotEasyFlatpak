import 'package:dupot_easy_flatpak/Localizations/app_localizations.dart';
import 'package:dupot_easy_flatpak/Models/Flathub/appstream.dart';
import 'package:dupot_easy_flatpak/Models/settings.dart';
import 'package:dupot_easy_flatpak/Process/commands.dart';
import 'package:flutter/material.dart';

class RunButton extends StatelessWidget {
  const RunButton(
      {super.key, required this.buttonStyle, required this.stateAppStream});

  final ButtonStyle buttonStyle;
  final AppStream? stateAppStream;

  Future<void> run(BuildContext context, String applicationId) async {
    Settings settingsObj = Settings(context: context);
    await settingsObj.load();

    Commands commands = Commands(settingsObj: settingsObj);
    commands.run(applicationId);
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: buttonStyle,
      onPressed: () {
        run(context, stateAppStream!.id);
      },
      label: Text(AppLocalizations.of(context).tr('Run')),
      icon: const Icon(Icons.launch),
    );
  }
}
