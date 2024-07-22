import 'dart:convert';
import 'dart:io';

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
  Application application = Application("loading", "loading", "");
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

      setState(() {
        flatpakOutput = result.stdout.toString() + "\n Installation terminée";
        installing = false;
        installationFinished = true;
      });
    });
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
  Application applicationLoaded =
      Application(jsonApp['title'], jsonApp['description'], jsonApp['flatpak']);

  return applicationLoaded;
}

class Application {
  final String title;
  final String description;
  final String flatpak;

  Application(String this.title, String this.description, String this.flatpak);
}
