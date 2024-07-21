import 'dart:convert';

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
  Application application = Application("loading", "loading");
  bool loaded = false;

  void getData(BuildContext context, app) async {
    Application newApp = await getApplication(context, app);
    setState(() {
      application = newApp;
      loaded = true;
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
        backgroundColor: Colors.grey[200],
        appBar: AppBar(
          title: Text("Recette: " + args.app),
          centerTitle: true,
          backgroundColor: Colors.amberAccent,
          actions: [
            TextButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/home');
              },
              icon: const Icon(Icons.home),
              label: const Text('Apps'),
            ),
          ],
        ),
        body: Column(children: [
          Text("mon app:" + application.title),
          Text("Description:" + application.description)
        ]));
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
  return Application(jsonApp['title'], jsonApp['description']);

  return Application("test", "test");
}

class Application {
  final String title;
  final String description;

  Application(String this.title, String this.description);
}
