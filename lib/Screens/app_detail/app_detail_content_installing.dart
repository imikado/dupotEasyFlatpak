import 'package:dupot_easy_flatpak/Localizations/app_localizations.dart';
import 'package:flutter/material.dart';

class AppDetailContentInstalling extends StatelessWidget {
  const AppDetailContentInstalling({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const TextStyle contentTitleStyle =
        TextStyle(color: Colors.blueGrey, fontSize: 28.0);

    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Text(AppLocalizations.of(context).tr('installing'),
          style: contentTitleStyle),
      const SizedBox(height: 20),
      CircularProgressIndicator(
        semanticsLabel: AppLocalizations.of(context).tr('installing'),
      )
    ]);
  }
}
