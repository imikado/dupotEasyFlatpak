import 'package:dupot_easy_flatpak/Localizations/app_localizations.dart';
import 'package:dupot_easy_flatpak/Process/flatpak.dart';
import 'package:flutter/material.dart';
import 'package:prompt_dialog/prompt_dialog.dart';

import '../Models/recipe.dart';
import '../Models/recipe_factory.dart';
import '../Models/permission.dart';
import 'app_detail/app_detail_appbar.dart';
import 'app_detail/app_detail_arguments.dart';
import 'app_detail/app_detail_content_installing.dart';

class AppDetail extends StatefulWidget {
  const AppDetail({
    super.key,
  });

  @override
  State<StatefulWidget> createState() {
    return _AppDetail();
  }
}

class _AppDetail extends State<AppDetail> {
  Recipe application = Recipe("", []);
  bool loaded = false;
  String flatpakOutput = "";

  bool displayInstalling = false;
  bool displayInstallationFinished = false;
  bool displayAlreadyInstalled = false;
  bool displayNotInstalled = false;

  String flatpakApplicationInfo = "";

  List<List<String>> processList = [[]];

  void getData(BuildContext context, app) async {
    Recipe newApp = await RecipeFactory.getApplication(context, app);
    checkAlreadyInstalled(newApp);
    setState(() {
      application = newApp;
      loaded = true;
    });
  }

  void checkAlreadyInstalled(Recipe applicationToCheck) {
    Flatpak()
        .isApplicationAlreadyInstalled(applicationToCheck.id)
        .then((flatpakApplication) {
      setState(() {
        if (flatpakApplication.isInstalled) {
          displayAlreadyInstalled = true;
          flatpakApplicationInfo = flatpakApplication.flatpakOutput;
        } else {
          displayNotInstalled = true;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as AppDetailArguments;

    if (!loaded) {
      getData(context, args.app);
    }
    return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.grey[200],
        appBar: AppDetailAppBar(args: args),
        body: SingleChildScrollView(
          child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Visibility(
                        visible: displayInstalling,
                        child: const AppDetailContentInstalling()),
                  ])),
        ));
  }

  Future<bool> loadSetup(Recipe application) async {
    List<Permission> flatpakPermissionList =
        application.getFlatpakPermissionToOverrideList();

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

        argList.add(application.id);

        processList.add(argList);
      } else if (permissionLoop.isFileSystemNoPrompt()) {
        String directoryPath = 'home';

        List<String> argList = [
          'override',
          '--user',
        ];
        argList.add(permissionLoop.getFlatpakOverrideType() + directoryPath);

        argList.add(application.id);

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

  void loadSetupThenInstall(Recipe application) {
    loadSetup(application).then((isSetupOk) {
      if (isSetupOk) {
        install(application);
      }
    });
  }

  void install(Recipe application) {
    setState(() {
      displayNotInstalled = false;

      displayInstalling = true;
    });

    Flatpak()
        .installApplicationThenOverrideList(application.id, processList)
        .then((stdout) {
      setState(() {
        flatpakOutput =
            "$stdout \n ${AppLocalizations.of(context).tr('installation_finished')}";
        displayInstalling = false;
        displayInstallationFinished = true;
      });

      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.popAndPushNamed(context, '/home');
                      },
                      child: const Text('OK')),
                ],
                title: Text(AppLocalizations.of(context)
                    .tr('installation_successfully')),
                contentPadding: const EdgeInsets.all(20.0),
                content: Text(AppLocalizations.of(context)
                    .tr('installation_successfully')),
              ));
    });
  }
}
