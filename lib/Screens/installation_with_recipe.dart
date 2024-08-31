import 'dart:io';

import 'package:dupot_easy_flatpak/Models/permission.dart';
import 'package:dupot_easy_flatpak/Models/recipe.dart';
import 'package:dupot_easy_flatpak/Models/recipe_factory.dart';
import 'package:dupot_easy_flatpak/Models/settings.dart';
import 'package:dupot_easy_flatpak/Process/commands.dart';
import 'package:dupot_easy_flatpak/Screens/Shared/Arguments/applicationIdArgument.dart';
import 'package:dupot_easy_flatpak/Screens/Shared/Arguments/categoryIdArgument.dart';
import 'package:dupot_easy_flatpak/Screens/Shared/menu_item.dart';
import 'package:dupot_easy_flatpak/Screens/Shared/sidemenu.dart';
import 'package:dupot_easy_flatpak/Localizations/app_localizations.dart';
import 'package:dupot_easy_flatpak/Models/Flathub/appstream.dart';
import 'package:dupot_easy_flatpak/Models/Flathub/appstream_factory.dart';
import 'package:flutter/material.dart';
import 'package:prompt_dialog/prompt_dialog.dart';

class InstallationWithRecipe extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _InstallationWithRecipe();
}

class _InstallationWithRecipe extends State<InstallationWithRecipe> {
  late AppStreamFactory appStreamFactory;
  List<String> stateCategoryIdList = [];
  AppStream? stateAppStream;
  List<MenuItem> stateMenuItemList = [];
  final ScrollController scrollController = ScrollController();

  bool stateIsAlreadyInstalled = false;

  String categorySelected = 'aa';
  String applicationId = '';

  bool stateIsLoaded = false;

  String appPath = '';

  bool isInstalling = true;

  String stateFlatpakOutput = '';

  List<List<String>> processList = [[]];

  Future<Recipe> getRecipe(BuildContext context, String applicationId) async {
    Recipe recipe = await RecipeFactory.getApplication(context, applicationId);
    return recipe;
  }

  void getData() async {
    appStreamFactory = AppStreamFactory();
    appPath = await appStreamFactory.getPath();

    List<String> categoryIdList = await appStreamFactory.findAllCategoryList();

    AppStream appStream =
        await appStreamFactory.findAppStreamById(applicationId);

    setState(() {
      stateCategoryIdList = categoryIdList;
      stateAppStream = appStream;
      stateIsLoaded = true;
    });
  }

  Future<bool> loadSetup(Recipe recipe) async {
    List<Permission> flatpakPermissionList =
        recipe.getFlatpakPermissionToOverrideList();

    for (Permission permissionLoop in flatpakPermissionList) {
      if (permissionLoop.isFileSystem()) {
        String directoryPath = await selectDirectory(permissionLoop.label);

        if (directoryPath.length < 2) {
          return false;
        }

        List<String> argList = [
          'override',
          '--user',
        ];
        argList.add(permissionLoop.getFlatpakOverrideType() + directoryPath);

        argList.add(recipe.id);

        processList.add(argList);
      } else if (permissionLoop.isFileSystemNoPrompt()) {
        String directoryPath = 'home';

        List<String> argList = [
          'override',
          '--user',
        ];
        argList.add(permissionLoop.getFlatpakOverrideType() + directoryPath);

        argList.add(recipe.id);

        processList.add(argList);
      }
    }

    return true;
  }

  Future<String> selectDirectory(String label) async {
    String? selectedDirectory = await prompt(context,
        title: Text(label),
        isSelectedInitialValue: false,
        textOK: Text(AppLocalizations.of(context).tr('confirm')),
        textCancel: Text(AppLocalizations.of(context).tr('cancel')),
        hintText: label, validator: (String? value) {
      if (value == null || value.isEmpty) {
        return AppLocalizations.of(context).tr('field_should_not_be_empty');
      }
      return null;
    });

    if (selectedDirectory == null) {
      return "";
    }

    return selectedDirectory;
  }

  void loadSetupThenInstall(BuildContext context, String applicationId) async {
    Recipe recipe = await getRecipe(context, applicationId);

    loadSetup(recipe).then((isSetupOk) {
      if (isSetupOk) {
        install(context, applicationId);
      }
    });
  }

  void install(BuildContext context, String applicationId) async {
    Settings settingsObj = Settings(context: context);
    await settingsObj.load();

    String stdout = await Commands(settingsObj: settingsObj)
        .installApplicationThenOverrideList(applicationId, processList);
    setState(() {
      stateFlatpakOutput =
          "$stdout \n ${AppLocalizations.of(context).tr('installation_finished')}";
      isInstalling = false;
    });

    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.popAndPushNamed(context, '/application',
                          arguments: ApplicationIdArgment(applicationId));
                    },
                    child: const Text('OK')),
              ],
              title: Text(
                  AppLocalizations.of(context).tr('installation_successfully')),
              contentPadding: const EdgeInsets.all(20.0),
              content: Text(
                  AppLocalizations.of(context).tr('installation_successfully')),
            ));
  }

  @override
  Widget build(BuildContext context) {
    if (!stateIsLoaded) {
      ApplicationIdArgment args =
          ModalRoute.of(context)?.settings.arguments as ApplicationIdArgment;

      applicationId = args.applicationId;

      getData();

      loadSetupThenInstall(context, args.applicationId);
    }

    const TextStyle outputTextStyle =
        TextStyle(color: Colors.blueGrey, fontSize: 14.0);

    final ButtonStyle buttonStyle = ElevatedButton.styleFrom(
        backgroundColor: Colors.blueGrey,
        padding: const EdgeInsets.all(20),
        textStyle: const TextStyle(fontSize: 14));

    final ButtonStyle dialogButtonStyle = FilledButton.styleFrom(
        backgroundColor: Colors.grey,
        padding: const EdgeInsets.all(20),
        textStyle: const TextStyle(fontSize: 14));

    return Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.grey[200],
        body: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          SizedBox(width: 10),
          Expanded(
              child: Card(
            child: isInstalling
                ? CircularProgressIndicator()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (stateAppStream!.icon.length > 10)
                            Image.file(File(
                                appPath + '/' + stateAppStream!.getIcon())),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  stateAppStream!.name,
                                  style: const TextStyle(
                                      fontSize: 35,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Text(
                                  stateAppStream!.developer_name,
                                  style: const TextStyle(
                                      fontStyle: FontStyle.italic),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                stateAppStream!.isVerified()
                                    ? TextButton.icon(
                                        style: TextButton.styleFrom(
                                            padding: const EdgeInsets.only(
                                                top: 5,
                                                bottom: 5,
                                                right: 5,
                                                left: 0),
                                            alignment:
                                                AlignmentDirectional.topStart),
                                        icon: Icon(Icons.verified),
                                        onPressed: () {},
                                        label: Text(
                                            stateAppStream!.getVerifiedLabel()))
                                    : SizedBox()
                              ],
                            ),
                          ),
                        ],
                      ),
                      Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stateAppStream!.summary,
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              RichText(
                                overflow: TextOverflow.clip,
                                text: TextSpan(
                                  text:
                                      AppLocalizations.of(context).tr('output'),
                                  style: outputTextStyle,
                                  children: <TextSpan>[
                                    TextSpan(text: stateFlatpakOutput),
                                  ],
                                ),
                              )
                            ],
                          )),
                    ],
                  ),
          ))
        ]));
  }

  Widget getIcon(String type) {
    if (type == 'homepage') {
      return Icon(Icons.home);
    } else if (type == 'bugtracker') {
      return Icon(Icons.bug_report);
    }
    return Icon(Icons.ac_unit);
  }
}
