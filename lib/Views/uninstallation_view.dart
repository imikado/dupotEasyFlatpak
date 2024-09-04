import 'dart:io';

import 'package:dupot_easy_flatpak/Localizations/app_localizations.dart';
import 'package:dupot_easy_flatpak/Models/Flathub/appstream.dart';
import 'package:dupot_easy_flatpak/Models/Flathub/appstream_factory.dart';
import 'package:dupot_easy_flatpak/Models/recipe_factory.dart';
import 'package:dupot_easy_flatpak/Models/settings.dart';
import 'package:dupot_easy_flatpak/Process/commands.dart';
import 'package:dupot_easy_flatpak/Screens/Store/block.dart';
import 'package:dupot_easy_flatpak/Screens/Store/install_button.dart';
import 'package:dupot_easy_flatpak/Screens/Store/install_button_with_recipe.dart';
import 'package:dupot_easy_flatpak/Screens/Store/uninstall_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

class UninstallationView extends StatefulWidget {
  String applicationIdSelected;

  Function handleGoToApplication;

  UninstallationView({
    super.key,
    required this.applicationIdSelected,
    required this.handleGoToApplication,
  });

  @override
  State<UninstallationView> createState() => _UninstallationViewState();
}

class _UninstallationViewState extends State<UninstallationView> {
  AppStream? stateAppStream;
  bool stateIsInstalling = true;
  String stateInstallationOutput = '';

  String applicationIdSelected = '';

  String appPath = '';

  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    install();
  }

  Future<void> install() async {
    applicationIdSelected = widget.applicationIdSelected;

    AppStreamFactory appStreamFactory = AppStreamFactory();
    appPath = await appStreamFactory.getPath();

    AppStream appStream =
        await appStreamFactory.findAppStreamById(applicationIdSelected);

    setState(() {
      stateAppStream = appStream;
    });

    Settings settingsObj = Settings(context: context);
    await settingsObj.load();

    String stdout = await Commands(settingsObj: settingsObj)
        .uninstallApplicationThenOverrideList(applicationIdSelected, []);

    setState(() {
      stateInstallationOutput =
          "$stdout \n ${AppLocalizations.of(context).tr('uninstallation_finished')}";
      stateIsInstalling = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const TextStyle outputTextStyle =
        TextStyle(color: Colors.blueGrey, fontSize: 14.0);

    return Card(
      color: Theme.of(context).cardColor,
      child: stateIsInstalling
          ? const CircularProgressIndicator()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (stateAppStream!.icon.length > 10)
                      Image.file(
                          File(appPath + '/' + stateAppStream!.getIcon())),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stateAppStream!.name,
                            style: const TextStyle(
                                fontSize: 35, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Text(
                            stateAppStream!.developer_name,
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          stateAppStream!.isVerified()
                              ? TextButton.icon(
                                  style: TextButton.styleFrom(
                                      padding: const EdgeInsets.only(
                                          top: 5, bottom: 5, right: 5, left: 0),
                                      alignment: AlignmentDirectional.topStart),
                                  icon: Icon(Icons.verified),
                                  onPressed: () {},
                                  label:
                                      Text(stateAppStream!.getVerifiedLabel()))
                              : SizedBox(),
                        ],
                      ),
                    ),
                    getButton()
                  ],
                ),
                Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stateAppStream!.summary,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        RichText(
                          overflow: TextOverflow.clip,
                          text: TextSpan(
                            text: AppLocalizations.of(context).tr('output'),
                            style: outputTextStyle,
                            children: <TextSpan>[
                              TextSpan(text: stateInstallationOutput),
                            ],
                          ),
                        )
                      ],
                    )),
              ],
            ),
    );
  }

  Widget getButton() {
    ButtonStyle buttonStyle = ElevatedButton.styleFrom(
        backgroundColor: Colors.blueGrey,
        padding: const EdgeInsets.all(20),
        textStyle: const TextStyle(fontSize: 14));

    return FilledButton.icon(
      style: buttonStyle,
      onPressed: () {
        widget.handleGoToApplication(widget.applicationIdSelected);
      },
      label: Text(AppLocalizations.of(context).tr('close')),
      icon: const Icon(Icons.close),
    );
  }
}
