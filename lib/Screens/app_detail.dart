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
  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as AppDetailArguments;

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
        body: Column(children: [Text("mon app:" + args.app)]));
  }
}

class AppDetailArguments {
  final String app;

  AppDetailArguments(
    String this.app,
  );
}
