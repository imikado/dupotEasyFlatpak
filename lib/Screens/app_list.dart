import 'dart:convert';

import 'package:dupot_easy_flatpak/Components/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    List<String> newAppList = await getApplicationList();

    setState(() {
      applicationList = newAppList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text("Recettes disponibles"),
        centerTitle: true,
        backgroundColor: Colors.amberAccent,
      ),
      body: Column(
          children: applicationList.map((e) {
        return AppButton(
          title: e,
        );
      }).toList()),
    );
  }

  Future<List<String>> getApplicationList() async {
    String recipiesString =
        await DefaultAssetBundle.of(context).loadString("assets/recipies.json");
    print(recipiesString);
    List<String> recipieList = List<String>.from(json.decode(recipiesString));
    print(recipieList);
    return recipieList;
  }
}

class Application {
  final String title;

  Application({required this.title});
}
