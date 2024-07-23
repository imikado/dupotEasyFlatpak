import 'package:dupot_easy_flatpak/Components/app_button.dart';
import 'package:flutter/material.dart';

import '../Models/application_factory.dart';

class AppList extends StatefulWidget {
  const AppList({super.key});

  @override
  State<StatefulWidget> createState() => _AppList();
}

class _AppList extends State<AppList> {
  List<String> applicationList = ["loading"];

  @override
  void initState() {
    super.initState();

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
        title: const Text(
          "Applications disponibles",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueGrey,
      ),
      body: Column(
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
