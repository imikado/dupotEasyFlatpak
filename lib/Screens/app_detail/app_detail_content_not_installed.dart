import 'package:flutter/material.dart';

import 'package:dupot_easy_flatpak/Localizations/app_localizations.dart';
import '../../Models/application.dart';

typedef ApplicationInstallCallback = void Function(Application application);

class AppDetailContentNotInstalled extends StatelessWidget {
  const AppDetailContentNotInstalled(
      {super.key,
      required this.application,
      required this.handleLoadSetupThenInstall});

  final Application application;
  final ApplicationInstallCallback handleLoadSetupThenInstall;

  final navTextColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    const TextStyle contentTitleStyle =
        TextStyle(color: Colors.blueGrey, fontSize: 28.0);

    const TextStyle contentValueStyle =
        TextStyle(color: Color.fromARGB(255, 85, 77, 77), fontSize: 20.0);

    final ButtonStyle buttonStyle = ElevatedButton.styleFrom(
        backgroundColor: Colors.blueGrey,
        padding: const EdgeInsets.all(20),
        textStyle: const TextStyle(fontSize: 14));

    final ButtonStyle dialogButtonStyle = FilledButton.styleFrom(
        backgroundColor: Colors.grey,
        padding: const EdgeInsets.all(20),
        textStyle: const TextStyle(fontSize: 14));

    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Text(AppLocalizations.of(context).tr('application'),
          style: contentTitleStyle),
      Text(application.title, style: contentValueStyle),
      const SizedBox(height: 20),
      Text(AppLocalizations.of(context).tr('description'),
          style: contentTitleStyle),
      Text(application.description, style: contentValueStyle),
      const SizedBox(height: 40),
      FilledButton.icon(
        style: buttonStyle,
        onPressed: () {
          showDialog(
              context: context,
              builder: (context) => AlertDialog(
                    buttonPadding: const EdgeInsets.all(10),
                    actions: [
                      FilledButton(
                          style: dialogButtonStyle,
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child:
                              Text(AppLocalizations.of(context).tr('cancel'))),
                      FilledButton(
                          style: dialogButtonStyle,
                          onPressed: () {
                            Navigator.of(context).pop();
                            handleLoadSetupThenInstall(application);
                          },
                          child:
                              Text(AppLocalizations.of(context).tr('confirm'))),
                    ],
                    title: Text(
                        AppLocalizations.of(context).tr('confirmation_title')),
                    contentPadding: const EdgeInsets.all(20.0),
                    content: Text(
                        '${AppLocalizations.of(context).tr('do_you_confirm_installation_of')} ${application.title} ?'),
                  ));

          //install(application);
        },
        label: Text(AppLocalizations.of(context).tr('install')),
        icon: const Icon(Icons.install_desktop),
      )
    ]);
  }
}
