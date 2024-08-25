import 'package:dupot_easy_flatpak/Components/app_button.dart';
import 'package:dupot_easy_flatpak/Models/Flathub/appstream.dart';
import 'package:dupot_easy_flatpak/Models/Flathub/appstream_factory.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class Block extends StatefulWidget {
  final String category;

  const Block({
    super.key,
    required this.category,
  });

  @override
  State<StatefulWidget> createState() {
    return _Block();
  }
}

class _Block extends State<Block> {
  List<AppStream> applicationList = [];

  late AppStreamFactory appStreamFactory;

  @override
  void initState() {
    super.initState();

    getData();
  }

  void getData() async {
    appStreamFactory = AppStreamFactory();

    List<AppStream> newAppList =
        await appStreamFactory.findListAppStreamByCategory(widget.category);

    setState(() {
      applicationList = newAppList;
    });
  }

  @override
  Widget build(BuildContext context) {
    int maxNumberPerRow = 3;

    List<Widget> childrenList = [];
    List<Widget> itemRowList = [];

    int appDisplayed = 0;
    int maxAppDisplayed = 9;

    for (AppStream appStreamLoop in applicationList) {
      appDisplayed++;
      if (appDisplayed > maxAppDisplayed) {
        break;
      }

      itemRowList.add(SizedBox(
          width: 300,
          height: 300,
          child: AppButton(
              title: appStreamLoop.name,
              sumary: appStreamLoop.summary,
              icon: appStreamLoop.icon)));
      if (itemRowList.length >= maxNumberPerRow) {
        childrenList.add(Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: itemRowList.toList(),
        ));
        itemRowList.clear();
      }
    }
    if (itemRowList.isNotEmpty) {
      childrenList.add(Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: itemRowList,
      ));
      itemRowList.clear();
    }

    return Column(children: childrenList.toList());
    /*
    Container(
        height: 600,
        child: GridView.count(
            clipBehavior: Clip.hardEdge,
            crossAxisCount: 6,
            children: applicationList.map((e) {
              return AppButton(title: e.name, sumary: e.summary, icon: e.icon);
            }).toList()));
            */
  }
}
