import 'dart:io';

import 'package:dupot_easy_flatpak/Screens/Shared/Arguments/applicationIdArgument.dart';
import 'package:dupot_easy_flatpak/Screens/Shared/Arguments/categoryIdArgument.dart';
import 'package:dupot_easy_flatpak/Screens/Shared/menu_item.dart';
import 'package:dupot_easy_flatpak/Screens/Shared/sidemenu.dart';
import 'package:dupot_easy_flatpak/Localizations/app_localizations.dart';
import 'package:dupot_easy_flatpak/Models/Flathub/appstream.dart';
import 'package:dupot_easy_flatpak/Models/Flathub/appstream_factory.dart';
import 'package:flutter/material.dart';

class Search extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _Search();
}

class _Search extends State<Search> {
  late AppStreamFactory appStreamFactory;
  List<String> stateCategoryIdList = [];
  List<AppStream> stateAppStreamList = [];
  List<MenuItem> stateMenuItemList = [];
  final ScrollController scrollController = ScrollController();

  String categorySelected = 'Search';

  String stateSearch = '';

  bool stateIsLoaded = false;

  String appPath = '';

  final TextEditingController _searchController = TextEditingController();

  void getData() async {
    appStreamFactory = AppStreamFactory();
    appPath = await appStreamFactory.getPath();

    List<String> categoryIdList = await appStreamFactory.findAllCategoryList();

    List<MenuItem> menuItemList = [
      MenuItem('Search', () {
        Navigator.popAndPushNamed(context, '/search');
      }),
      MenuItem('Home', () {
        Navigator.popAndPushNamed(context, '/');
      })
    ];

    for (String categoryIdLoop in categoryIdList) {
      menuItemList.add(MenuItem(categoryIdLoop, () {
        Navigator.popAndPushNamed(context, '/category',
            arguments: CategoryIdArgment(categoryIdLoop));
      }));
    }

    List<AppStream> appStreamList =
        await appStreamFactory.findListAppStreamBySearch(stateSearch);

    setState(() {
      stateCategoryIdList = categoryIdList;
      stateAppStreamList = appStreamList;
      stateMenuItemList = menuItemList;
      stateIsLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!stateIsLoaded) {
      getData();
    }

    AppStreamFactory appStreamFactory = AppStreamFactory();

    return Scaffold(
        appBar: AppBar(
          leading: Icon(Icons.search),
          title: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            cursorColor: Colors.white,
            decoration: const InputDecoration(
              hintText: 'Search...',
              hintStyle: TextStyle(color: Colors.white54),
              border: InputBorder.none,
            ),
            onChanged: (value) {
              // Perform search functionality here
              if (value.length > 4) {
                setState(() {
                  stateSearch = value;
                  stateIsLoaded = false;
                });
              }
            },
          ),
        ),
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.grey[200],
        body: Row(
          children: [
            Container(
                width: 240,
                child: SideMenu(
                  menuItemList: stateMenuItemList,
                  selected: categorySelected,
                )),
            SizedBox(width: 10),
            Expanded(
                child: Scrollbar(
                    interactive: false,
                    thumbVisibility: true,
                    controller: scrollController,
                    child: ListView.builder(
                        itemCount: stateAppStreamList.length,
                        controller: scrollController,
                        itemBuilder: (context, index) {
                          AppStream appStreamLoop = stateAppStreamList[index];

                          String icon = appStreamLoop.icon;
                          if (icon.length < 10) {
                            return Card(
                              child: Column(
                                children: [
                                  ListTile(
                                      title:
                                          Text(stateAppStreamList[index].id)),
                                ],
                              ),
                            );
                          } else {
                            return Card(
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Image.file(File(appPath +
                                          '/' +
                                          appStreamLoop.getIcon())),
                                      SizedBox(width: 20),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            ListTile(
                                              onTap: () {
                                                Navigator.popAndPushNamed(
                                                    context, '/application',
                                                    arguments:
                                                        ApplicationIdArgment(
                                                            appStreamLoop.id));
                                              },
                                              title: Text(
                                                appStreamLoop.name,
                                                style: TextStyle(fontSize: 30),
                                              ),
                                            ),
                                            SizedBox(
                                              height: 10,
                                            ),
                                            Text(
                                              appStreamLoop.summary,
                                            )
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }
                        })))
          ],
        ));
  }
}
