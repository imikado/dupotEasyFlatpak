import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../Models/application.dart';
import '../Models/application_factory.dart';
import '../Models/permission.dart';

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
  bool installing = false;
  bool installationFinished = false;
  bool alreadyInstalled = false;

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
    Process.run('flatpak', ['info', applicationToCheck.flatpak]).then((result) {
      stdout.write(result.stdout);

      var isAlreadyInstalled = false;

      if (result.stdout.toString().length > 2) {
        isAlreadyInstalled = true;
      }

      setState(() {
        alreadyInstalled = isAlreadyInstalled;
      });
    });
  }

  void install(Application application) {
    setState(() {
      installing = true;
    });

    Process.run('flatpak', ['install', '-y', application.flatpak])
        .then((result) {
      stdout.write(result.stdout);
      stderr.write(result.stderr);

      overrideSetup(application);

      setState(() {
        flatpakOutput = "${result.stdout}\n Installation terminée";
        installing = false;
        installationFinished = true;
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

  Future<String> selectDirectory(String label) async {
    String? selectedDirectory =
        await FilePicker.platform.getDirectoryPath(dialogTitle: label);

    if (selectedDirectory == null) {
      return "";
    }

    return selectedDirectory;
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
      }
    }
  }

  void overrideSetup(Application application) async {
    for (List<String> argListLoop in processList) {
      Process.run('flatpak', argListLoop).then((result) {
        stdout.write(result.stdout);
        stderr.write(result.stderr);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as AppDetailArguments;

    const navTextColor = Colors.white;

    const TextStyle navTextStyle = TextStyle(color: navTextColor);

    const TextStyle outputTextStyle =
        TextStyle(color: Colors.blueGrey, fontSize: 14.0);

    const TextStyle strongTextStyle =
        TextStyle(color: Colors.blueGrey, fontSize: 24.0);

    const TextStyle contentTitleStyle =
        TextStyle(color: Colors.blueGrey, fontSize: 28.0);

    const TextStyle contentValueStyle =
        TextStyle(color: Color.fromARGB(255, 85, 77, 77), fontSize: 20.0);

    if (!loaded) {
      getData(context, args.app);
    }
    return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.grey[200],
        appBar: AppBar(
          leading: IconButton(
            onPressed: () {
              Navigator.popAndPushNamed(context, '/home');
            },
            icon: const Icon(
              Icons.home,
              color: navTextColor,
            ),
          ),
          title: Text(
            "Application: ${args.app}",
            style: navTextStyle,
          ),
          backgroundColor: Colors.blueGrey,
          actions: [
            TextButton.icon(
                onPressed: () {},
                icon: const Icon(
                  Icons.settings,
                  color: navTextColor,
                ),
                label: const Text(
                  'Settings',
                  style: navTextStyle,
                )),
          ],
        ),
        body: SingleChildScrollView(
          child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(25.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text("Application", style: contentTitleStyle),
                    Text(application.title, style: contentValueStyle),
                    SizedBox(height: 20),
                    Text("Description", style: contentTitleStyle),
                    Text(application.description, style: contentValueStyle),
                    SizedBox(height: 40),
                    Visibility(
                        visible: installing,
                        child: const CircularProgressIndicator(
                          semanticsLabel: 'Installation...',
                        )),
                    SizedBox(height: 20),
                    Visibility(
                        visible: alreadyInstalled,
                        child: const Text(
                          'Déjà installée',
                          style: strongTextStyle,
                        )),
                    Visibility(
                        visible: !installing &&
                            !alreadyInstalled &&
                            !installationFinished,
                        child: TextButton.icon(
                          onPressed: () {
                            showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                      actions: [
                                        TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: const Text('Annuler')),
                                        TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                              loadSetup(application)
                                                  .then((result) {
                                                install(application);
                                              });
                                            },
                                            child: const Text('Confirmer')),
                                      ],
                                      title: const Text("Confirmation"),
                                      contentPadding:
                                          const EdgeInsets.all(20.0),
                                      content: const Text(
                                          'Confirmez-vous l\'installation  '),
                                    ));

                            //install(application);
                          },
                          label: const Text("Intaller"),
                          icon: const Icon(Icons.install_desktop),
                        )),
                    Visibility(
                        visible: installationFinished,
                        child: RichText(
                          overflow: TextOverflow.clip,
                          text: TextSpan(
                            text: 'Output ',
                            style: outputTextStyle,
                            children: <TextSpan>[
                              TextSpan(text: flatpakOutput),
                            ],
                          ),
                        )),
                  ])),
        ));
  }
}

class AppDetailArguments {
  final String app;

  AppDetailArguments(
    this.app,
  );
}
