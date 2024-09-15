import 'package:dupot_easy_flatpak/Localizations/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MyDrawer extends StatelessWidget {
  MyDrawer({super.key, required this.version, required this.handleSetLocale});

  final String version;
  Function handleSetLocale;

  @override
  Widget build(BuildContext context) {
    return Drawer(
        child: ListView(
            // Important: Remove any padding from the ListView.
            padding: EdgeInsets.zero,
            children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.blue,
            ),
            child: Image.asset('assets/logos/512x512.png'),
          ),
          Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(children: [
                ListTile(
                  title: Text(AppLocalizations.of(context).tr('Language')),
                ),
                Column(
                  children: <Widget>[
                    ListTile(
                      titleTextStyle:
                          const TextStyle(fontSize: 14, color: Colors.black),
                      title: Text(AppLocalizations.of(context).tr('English')),
                      leading: Radio<String>(
                        value: 'en',
                        groupValue:
                            AppLocalizations.of(context).getLanguageCode(),
                        onChanged: (String? value) {
                          handleSetLocale('en');
                        },
                      ),
                    ),
                    ListTile(
                      titleTextStyle:
                          const TextStyle(fontSize: 14, color: Colors.black),
                      title: Text(AppLocalizations.of(context).tr('French')),
                      leading: Radio<String>(
                        value: 'fr',
                        groupValue:
                            AppLocalizations.of(context).getLanguageCode(),
                        onChanged: (String? value) {
                          handleSetLocale('fr');
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 150),
                Text(
                    '${AppLocalizations.of(context).tr('Author')}: Michael Bertocchi'),
                const SizedBox(
                  height: 10,
                ),
                TextButton(
                  child: Text(
                      '${AppLocalizations.of(context).tr('Website')}: www.dupot.org'),
                  onPressed: () {
                    launchUrl(Uri.parse('https://www.dupot.org'));
                  },
                ),
                const SizedBox(
                  height: 10,
                ),
                Text(
                    '${AppLocalizations.of(context).tr('License')}:  LGPL-2.1'),
                const SizedBox(
                  height: 10,
                ),
                Text(version),
              ]))
        ]) // Populate the Drawer in the next step.
        );
  }
}
