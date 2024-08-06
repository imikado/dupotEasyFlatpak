import 'package:dupot_easy_flatpak/Localizations/app_localizations.dart';
import 'package:flutter/material.dart';

class Loading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(AppLocalizations.of(context).tr("loading"));
  }
}
