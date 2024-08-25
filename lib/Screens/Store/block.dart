import 'package:dupot_easy_flatpak/Screens/Shared/app_button.dart';
import 'package:dupot_easy_flatpak/Models/Flathub/appstream.dart';
import 'package:dupot_easy_flatpak/Models/Flathub/appstream_factory.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class Block extends StatelessWidget {
  final String categoryId;
  final List<AppStream> appStreamList;

  const Block({required this.categoryId, required this.appStreamList});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 20),
        Text(
          categoryId,
          style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey),
        ),
        SizedBox(height: 10),
        Container(
            height: 550,
            child: GridView.count(
                crossAxisCount: 4,
                children: appStreamList.map((appStreamLoop) {
                  return AppButton(
                      title: appStreamLoop.name,
                      sumary: appStreamLoop.summary,
                      icon: appStreamLoop.icon);
                }).toList()))
      ],
    );
  }

  Widget buildOFf(BuildContext context) {
    int maxNumberPerRow = 3;

    List<Widget> childrenList = [
      SizedBox(
        height: 30,
      ),
      Text(
        categoryId,
        style: TextStyle(fontSize: 32),
      ),
      SizedBox(
        height: 10,
      ),
    ];
    List<Widget> itemRowList = [];

    int appDisplayed = 0;
    int maxAppDisplayed = 9;

    for (AppStream appStreamLoop in appStreamList) {
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
          crossAxisAlignment: CrossAxisAlignment.center,
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
