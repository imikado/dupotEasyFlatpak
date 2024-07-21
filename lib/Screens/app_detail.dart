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
  String flatpakOutput = "test";

  void getData(BuildContext context, app) async {
    Application newApp = await getApplication(context, app);
    setState(() {
      application = newApp;
      loaded = true;
    });
  }

  void install(Application application) {
    Process.run('flatpak', ['install', application.flatpak]).then((result) {
      stdout.write(result.stdout);
      stderr.write(result.stderr);

      setState(() {
        flatpakOutput = result.stdout.toString();
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
        TextButton.icon(
          onPressed: () {
            install(application);
          },
          label: Text("Intaller"),
          icon: const Icon(Icons.install_desktop),
        ),
        RichText(
          overflow: TextOverflow.clip,
          text: TextSpan(
            text: 'Output ',
            style: outputTextStyle,
            children: <TextSpan>[
              TextSpan(text: flatpakOutput),
            ],
          ),
        ),
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
  return Application(
      jsonApp['title'], jsonApp['description'], jsonApp['flatpak']);
}

class Application {
  final String title;
  final String description;
  final String flatpak;

  Application(String this.title, String this.description, String this.flatpak);
}
