import 'package:dupot_easy_flatpak/Components/app_button.dart';
import 'package:dupot_easy_flatpak/Localizations/app_localizations.dart';
import 'package:flutter/material.dart';

import '../Models/application_factory.dart';

class AppList extends StatefulWidget {
  const AppList({super.key});

  @override
  State<StatefulWidget> createState() => _AppList();
}

class _AppList extends State<AppList> {
  List<String> applicationList = [];

  @override
  void initState() {
    super.initState();

    applicationList = [AppLocalizations.of(context).tr("loading")];

    getData();
  }

  void getData() async {
    List<String> newAppList =
        await ApplicationFactory.getApplicationList(context);

    setState(() {
      applicationList = newAppList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        leading: const Icon(Icons.apps),
        title: Text(
          AppLocalizations.of(context).tr("applications_available"),
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueGrey,
      ),
      body: GridView(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4),
          primary: false,
          padding: const EdgeInsets.all(10),
          children: applicationList.map((e) {
            return AppButton(
              title: e,
            );
          }).toList()),
    );
  }
}

class Application {
  final String title;

  Application({required this.title});
}
