import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class AppDetail extends StatefulWidget {
  const AppDetail({
    super.key,
  });

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
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

  void getData(BuildContext context, app) async {
    Application newApp = await getApplication(context, app);
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
        flatpakOutput = result.stdout.toString() + "\n Installation terminée";
        installing = false;
        installationFinished = true;
      });
    });
  }

  Future<String> selectDirectory(String label) async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory == null) {
      return "";
    }

    return selectedDirectory;
  }

  void overrideSetup(Application application) async {
    List<Permission> flatpakPermissionList =
        application.getFlatpakPermissionToOverrideList();

    for (Permission permissionLoop in flatpakPermissionList) {
      if (permissionLoop.isFileSystem()) {
        //browse directory
        String directoryPath = await selectDirectory(permissionLoop.label);

        List<String> argList = [
          'override',
          '--user',
        ];
        argList.add(permissionLoop.getFlatpakOverrideType() + directoryPath);

        argList.add(application.flatpak);

        print('flatpak  ${argList.join(' ')}');

        Process.run('flatpak', argList).then((result) {
          stdout.write(result.stdout);
          stderr.write(result.stderr);

          //flatpak override --user --filesystem=/path/to/steam-library com.valvesoftware.Steam
          // xdg-run/app/com.discordapp.Discord:create;xdg-pictures:ro;xdg-music:ro;
        });
      } else {
        print('permission not fileSystem');
      }
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

    if (!loaded) {
      getData(context, args.app);
    }
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(
          "Application: " + args.app,
          style: navTextStyle,
        ),
        backgroundColor: Colors.blueGrey,
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/home');
            },
            icon: const Icon(
              Icons.home,
              color: navTextColor,
            ),
            label: const Text(
              'Applications',
              style: navTextStyle,
            ),
          ),
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
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Text("mon app:" + application.title),
        Text("Description:" + application.description),
        Visibility(
            visible: installing,
            child: CircularProgressIndicator(
              semanticsLabel: 'Installation...',
            )),
        Visibility(
            visible: alreadyInstalled,
            child: const Text(
              'Déjà installée',
              style: strongTextStyle,
            )),
        Visibility(
            visible: !installing && !alreadyInstalled && !installationFinished,
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
                                  install(application);
                                },
                                child: const Text('Confirmer')),
                          ],
                          title: const Text("Confirmation"),
                          contentPadding: const EdgeInsets.all(20.0),
                          content:
                              const Text('Confirmez-vous l\'installation  '),
                        ));

                //install(application);
              },
              label: Text("Intaller"),
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
    );
  }
}

class AppDetailArguments {
  final String app;

  AppDetailArguments(
    String this.app,
  );
}

Future<Application> getApplication(context, app) async {
  String applicaitonRecipieString = await DefaultAssetBundle.of(context)
      .loadString("assets/recipies/" + app + ".json");
  print(applicaitonRecipieString);

  Map jsonApp = json.decode(applicaitonRecipieString);

  print(jsonApp['flatpakPermissionToOverrideList']);

  List<dynamic> rawList = jsonApp['flatpakPermissionToOverrideList'];

  List<Map<String, dynamic>> objectList = [];
  for (Map<String, dynamic> rawLoop in rawList) {
    objectList.add(rawLoop);
  }

  Application applicationLoaded = Application(
      jsonApp['title'], jsonApp['description'], jsonApp['flatpak'], objectList);

  return applicationLoaded;
}

class Application {
  final String title;
  final String description;
  final String flatpak;
  List<Permission> flatpakPermissionToOverrideList = [];

  Application(String this.title, String this.description, String this.flatpak,
      List<Map<String, dynamic>> rawFlatpakPermissionToOverrideList) {
    //flatpakPermissionToOverrideList=List();
    //flatpakPermissionToOverrideList=rawFlatpakPermissionToOverrideList;

    for (Map<String, dynamic> rawPermissionLoop
        in rawFlatpakPermissionToOverrideList) {
      flatpakPermissionToOverrideList.add(Permission(
          rawPermissionLoop['type'].toString(),
          rawPermissionLoop['default_value']!,
          rawPermissionLoop['label']!));
    }
  }

  List<Permission> getFlatpakPermissionToOverrideList() {
    return flatpakPermissionToOverrideList;
  }
}

class Permission {
  final String type;
  final String default_value;
  final String label;

  static const constTypeFileSystem = 'filesystem';

  Permission(String this.type, String this.default_value, this.label);

  bool isFileSystem() {
    return (type == constTypeFileSystem);
  }

  String getType() {
    return type;
  }

  String getLabel() {
    return label;
  }

  String getFlatpakOverrideType() {
    return '--$type=';
  }
}
