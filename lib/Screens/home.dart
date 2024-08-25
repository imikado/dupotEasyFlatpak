import 'package:dupot_easy_flatpak/Components/app_button.dart';
import 'package:dupot_easy_flatpak/Localizations/app_localizations.dart';
import 'package:dupot_easy_flatpak/Models/Flathub/appstream_factory.dart';
import 'package:dupot_easy_flatpak/Screens/Store/block.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<StatefulWidget> createState() => _Home();
}

class _Home extends State<Home> {
  late AppStreamFactory appStreamFactory;
  List<String> categoryList = [];
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    getData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  void getData() async {
    appStreamFactory = AppStreamFactory();

    List<String> newCategoryList = await appStreamFactory.findAllCategoryList();

    setState(() {
      categoryList = newCategoryList;
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color navTextColor = Colors.white;

    const TextStyle navTextStyle = TextStyle(color: navTextColor);

    List<Widget> childrenList = [];
    for (String categoryIdLoop in categoryList) {
      childrenList.add(Text(categoryIdLoop));
      childrenList.add(Block(
        category: categoryIdLoop,
      ));
    }

    return Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.grey[200],
        appBar: AppBar(
          leading: const Icon(Icons.apps),
          title: Text(
            AppLocalizations.of(context).tr("applications_available"),
            style: const TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: Colors.blueGrey,
          actions: const [],
        ),
        body: Scrollbar(
            interactive: false,
            thumbVisibility: true,
            controller: scrollController,
            child: ListView(
              controller: scrollController,
              children: childrenList,
            )));
  }
}
