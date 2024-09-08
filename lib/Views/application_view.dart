import 'dart:io';
import 'dart:math';

import 'package:dupot_easy_flatpak/Localizations/app_localizations.dart';
import 'package:dupot_easy_flatpak/Models/Flathub/appstream.dart';
import 'package:dupot_easy_flatpak/Models/Flathub/appstream_factory.dart';
import 'package:dupot_easy_flatpak/Models/recipe_factory.dart';
import 'package:dupot_easy_flatpak/Models/settings.dart';
import 'package:dupot_easy_flatpak/Process/commands.dart';
import 'package:dupot_easy_flatpak/Process/flathub_api.dart';
import 'package:dupot_easy_flatpak/Screens/Store/install_button.dart';
import 'package:dupot_easy_flatpak/Screens/Store/install_button_with_recipe.dart';
import 'package:dupot_easy_flatpak/Screens/Store/run_button.dart';
import 'package:dupot_easy_flatpak/Screens/Store/uninstall_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:url_launcher/url_launcher.dart';

class ApplicationView extends StatefulWidget {
  String applicationIdSelected;

  Function handleGoToInstallation;
  Function handleGoToInstallationWithRecipe;
  Function handleGoToUninstallation;

  ApplicationView({
    super.key,
    required this.applicationIdSelected,
    required this.handleGoToInstallation,
    required this.handleGoToInstallationWithRecipe,
    required this.handleGoToUninstallation,
  });

  @override
  State<ApplicationView> createState() => _ApplicationViewState();
}

class _ApplicationViewState extends State<ApplicationView> {
  AppStream? stateAppStream;
  bool stateIsAlreadyInstalled = false;
  bool stateHasRecipe = false;

  String applicationIdSelected = '';

  String appPath = '';

  final ScrollController scrollController = ScrollController();

  final ScrollController scrollControllerScreenshot = ScrollController();

  @override
  void initState() {
    super.initState();

    loadData();
  }

  Future<void> loadData() async {
    applicationIdSelected = widget.applicationIdSelected;
    AppStreamFactory appStreamFactory = AppStreamFactory();
    appPath = await appStreamFactory.getPath();

    AppStream appStream =
        await appStreamFactory.findAppStreamById(applicationIdSelected);

    if (appStream.lastUpdateIsOlderThan(7)) {
      print('update from api');
      await FlathubApi(appStreamFactory: appStreamFactory)
          .updateAppStream(applicationIdSelected);

      appStream =
          await appStreamFactory.findAppStreamById(applicationIdSelected);
    }

    checkAlreadyInstalled(context, applicationIdSelected);

    checkHasRecipe(applicationIdSelected, context);

    setState(() {
      stateAppStream = appStream;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (applicationIdSelected != widget.applicationIdSelected) {
      loadData();
    }

    return Card(
        color: Theme.of(context).cardColor,
        child: stateAppStream == null
            ? const CircularProgressIndicator()
            : Scrollbar(
                interactive: false,
                thumbVisibility: true,
                controller: scrollController,
                child: ListView(
                  controller: scrollController,
                  children: [
                    Row(
                      children: [
                        if (stateAppStream!.icon.length > 10)
                          Image.file(
                              File('$appPath/${stateAppStream!.getIcon()}')),
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
                                '${AppLocalizations.of(context).tr('By')} ${stateAppStream!.developer_name}',
                                style: const TextStyle(
                                    fontStyle: FontStyle.italic, fontSize: 15),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              if (stateAppStream!.projectLicense.isNotEmpty)
                                Text(
                                    '${AppLocalizations.of(context).tr('License')}: ${stateAppStream!.projectLicense}'),
                              const SizedBox(
                                height: 10,
                              ),
                              if (stateAppStream!.isVerified())
                                TextButton.icon(
                                    style: TextButton.styleFrom(
                                        padding: const EdgeInsets.only(
                                            top: 5,
                                            bottom: 5,
                                            right: 5,
                                            left: 0),
                                        alignment:
                                            AlignmentDirectional.topStart),
                                    icon: const Icon(Icons.verified),
                                    onPressed: () {
                                      String verifiedUrl =
                                          stateAppStream!.getVerifiedUrl();
                                      if (verifiedUrl.isNotEmpty) {
                                        launchUrl(Uri.parse(verifiedUrl));
                                      }
                                    },
                                    label: Text(
                                        stateAppStream!.getVerifiedLabel())),
                            ],
                          ),
                        ),
                        getButton(),
                        const SizedBox(width: 5),
                        getRunButton()
                      ],
                    ),
                    Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stateAppStream!.summary,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(
                              height: 15,
                            ),
                            HtmlWidget(
                              stateAppStream!.description,
                            ),
                          ],
                        )),
                    if (stateAppStream!.screenshotObjList.isNotEmpty)
                      const ListTile(
                          title: Text(
                        'Screenshots',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      )),
                    if (stateAppStream!.screenshotObjList.isNotEmpty)
                      Padding(
                          padding: const EdgeInsets.all(20),
                          child: Scrollbar(
                              interactive: false,
                              thumbVisibility: true,
                              controller: scrollControllerScreenshot,
                              child: SingleChildScrollView(
                                  controller: scrollControllerScreenshot,
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                      children: stateAppStream!
                                          .screenshotObjList
                                          .map((screenshotLoop) {
                                    return IconButton(
                                        onPressed: () {
                                          showDialog(
                                              context: context,
                                              builder: (_) => AlertDialog(
                                                  buttonPadding:
                                                      const EdgeInsets.all(0),
                                                  content: Image.network(
                                                      screenshotLoop[
                                                          'large'])));
                                        },
                                        icon: Image.network(
                                            screenshotLoop['preview']));
                                  }).toList())))),
                    const SizedBox(
                      height: 15,
                    ),
                    const ListTile(
                        title: Text(
                      'Links',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    )),
                    Padding(
                        padding: const EdgeInsets.only(
                            top: 5, bottom: 5, right: 5, left: 10),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: stateAppStream!
                                .getUrlObjList()
                                .map((urlObjLoop) {
                              String url = urlObjLoop['value'].toString();

                              return TextButton.icon(
                                icon: getIcon(urlObjLoop['key'].toString()),
                                onPressed: () {
                                  launchUrl(Uri.parse(url));
                                },
                                label: Text(url),
                              );
                            }).toList()))
                  ],
                ),
              ));
  }

  Widget getRunButton() {
    final ButtonStyle buttonStyle = ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        padding: const EdgeInsets.all(20),
        textStyle: const TextStyle(fontSize: 14, color: Colors.white));

    if (stateIsAlreadyInstalled) {
      return RunButton(
        buttonStyle: buttonStyle,
        stateAppStream: stateAppStream,
      );
    } else {
      return const SizedBox();
    }
  }

  Widget getButton() {
    final ButtonStyle buttonStyle = ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        padding: const EdgeInsets.all(20),
        textStyle: const TextStyle(fontSize: 14, color: Colors.white));

    final ButtonStyle dialogButtonStyle = FilledButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        padding: const EdgeInsets.all(20),
        textStyle: const TextStyle(fontSize: 14));

    if (stateIsAlreadyInstalled) {
      return UninstallButton(
          buttonStyle: buttonStyle,
          dialogButtonStyle: dialogButtonStyle,
          stateAppStream: stateAppStream,
          handle: widget.handleGoToUninstallation);
    } else if (stateHasRecipe) {
      return InstallWithRecipeButton(
          buttonStyle: buttonStyle,
          dialogButtonStyle: dialogButtonStyle,
          stateAppStream: stateAppStream,
          handle: widget.handleGoToInstallationWithRecipe);
    }

    return InstallButton(
      buttonStyle: buttonStyle,
      dialogButtonStyle: dialogButtonStyle,
      stateAppStream: stateAppStream,
      handle: widget.handleGoToInstallation,
    );
  }

  Widget getIcon(String type) {
    if (type == 'homepage') {
      return const Icon(Icons.home);
    } else if (type == 'bugtracker') {
      return const Icon(Icons.bug_report);
    }
    return const Icon(Icons.ac_unit);
  }

  void checkHasRecipe(String applicationId, context) async {
    List<String> recipeList = await RecipeFactory.getApplicationList(context);
    if (recipeList.contains(applicationId.toLowerCase())) {
      setState(() {
        stateHasRecipe = true;
      });
    }
  }

  void checkAlreadyInstalled(BuildContext context, String applicationId) async {
    Settings settingsObj = Settings(context: context);
    await settingsObj.load();

    Commands(settingsObj: settingsObj)
        .isApplicationAlreadyInstalled(applicationId)
        .then((flatpakApplication) {
      setState(() {
        stateIsAlreadyInstalled = flatpakApplication.isInstalled;
      });
    });
  }
}
