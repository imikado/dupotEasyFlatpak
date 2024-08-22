import 'package:dupot_easy_flatpak/Components/app_button.dart';
import 'package:dupot_easy_flatpak/Localizations/app_localizations.dart';
import 'package:dupot_easy_flatpak/Models/flatpak_app.dart';
import 'package:dupot_easy_flatpak/Models/flatpak_factory.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<StatefulWidget> createState() => _Home();
}

class _Home extends State<Home> {
  List<FlatpakApp> flatpakList = [];

  @override
  void initState() {
    super.initState();

    getData();
  }

  @override
  void didChangeDependencies() {
    flatpakList = [];

    super.didChangeDependencies();
  }

  void getData() async {
    List<FlatpakApp> newFlatpakList =
        await FlathubFactory.getFlatpakList(context);

    setState(() {
      flatpakList = newFlatpakList;
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color navTextColor = Colors.white;

    const TextStyle navTextStyle = TextStyle(color: navTextColor);

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
        actions: [],
      ),
      body: GridView(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4),
          primary: false,
          padding: const EdgeInsets.all(10),
          children: flatpakList.map((e) {
            return AppButton(title: e.title, sumary: e.sumary, icon: e.icon);
          }).toList()),
    );
  }
}
