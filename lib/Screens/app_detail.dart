import 'dart:io';

import 'package:dupot_easy_flatpak/Process/flatpak.dart';
import 'package:dupot_easy_flatpak/Screens/app_detail/app_detail_content_already_installed.dart';
import 'package:dupot_easy_flatpak/Screens/app_detail/app_detail_content_installed.dart';
import 'package:dupot_easy_flatpak/Screens/app_detail/app_detail_content_not_installed.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../Models/application.dart';
import '../Models/application_factory.dart';
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
  Application application = Application("loading", "loading", "", []);
  bool loaded = false;
  String flatpakOutput = "";

  bool displayInstalling = false;
  bool displayInstallationFinished = false;
  bool displayAlreadyInstalled = false;
  bool displayNotInstalled = false;

  String flatpakApplicationInfo = "";

  List<List<String>> processList = [[]];

  void getData(BuildContext context, app) async {
    Application newApp = await ApplicationFactory.getApplication(context, app);
    checkAlreadyInstalled(newApp);
    setState(() {
      application = newApp;
      loaded = true;
    });
  }

  void checkAlreadyInstalled(Application applicationToCheck) {
    Flatpak()
        .isApplicationAlreadyInstalled(applicationToCheck.flatpak)
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
                        visible: displayAlreadyInstalled,
                        child: AppDetailContentAlreadyInstalled(
                            application: application,
                            flatpakInfo: flatpakApplicationInfo)),
                    Visibility(
                        visible: displayInstallationFinished,
                        child: AppDetailContentInstalled(
                          application: application,
                          flatpakOutput: flatpakOutput,
                        )),
                    Visibility(
                        visible: displayInstalling,
                        child: const AppDetailContentInstalling()),
                    Visibility(
                        visible: displayNotInstalled,
                        child: AppDetailContentNotInstalled(
                            application: application,
                            handleLoadSetupThenInstall: loadSetupThenInstall)),
                  ])),
        ));
  }

  Future<void> loadSetup(Application application) async {
    List<Permission> flatpakPermissionList =
        application.getFlatpakPermissionToOverrideList();

    for (Permission permissionLoop in flatpakPermissionList) {
      if (permissionLoop.isFileSystem()) {
        String directoryPath = await selectDirectory(permissionLoop.label);

        List<String> argList = [
          'override',
          '--user',
        ];
        argList.add(permissionLoop.getFlatpakOverrideType() + directoryPath);

        argList.add(application.flatpak);

        processList.add(argList);
      } else if (permissionLoop.isFileSystemNoPrompt()) {
        String directoryPath = 'home';

        List<String> argList = [
          'override',
          '--user',
        ];
        argList.add(permissionLoop.getFlatpakOverrideType() + directoryPath);

        argList.add(application.flatpak);

        processList.add(argList);
      }
    }
  }

  Future<String> selectDirectory(String label) async {
    String? selectedDirectory =
        await FilePicker.platform.getDirectoryPath(dialogTitle: label);

    if (selectedDirectory == null) {
      return "";
    }

    return selectedDirectory;
  }

  void loadSetupThenInstall(Application application) {
    loadSetup(application).then((result) {
      install(application);
    });
  }

  void install(Application application) {
    setState(() {
      displayNotInstalled = false;

      displayInstalling = true;
    });

    Flatpak()
        .installApplicationThenOverrideList(application.flatpak, processList)
        .then((stdout) {
      setState(() {
        flatpakOutput = "$stdout \n Installation terminée";
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
                title: const Text("Installation avec succès"),
                contentPadding: const EdgeInsets.all(20.0),
                content: const Text('Installation avec succès'),
              ));
    });
  }
}
