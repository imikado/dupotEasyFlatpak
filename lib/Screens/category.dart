import 'package:dupot_easy_flatpak/Screens/Shared/Arguments/categoryIdArgument.dart';
import 'package:dupot_easy_flatpak/Screens/Shared/menu_item.dart';
import 'package:dupot_easy_flatpak/Screens/Shared/sidemenu.dart';
import 'package:dupot_easy_flatpak/Localizations/app_localizations.dart';
import 'package:dupot_easy_flatpak/Models/Flathub/appstream.dart';
import 'package:dupot_easy_flatpak/Models/Flathub/appstream_factory.dart';
import 'package:flutter/material.dart';

class Category extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _Category();
}

class _Category extends State<Category> {
  late AppStreamFactory appStreamFactory;
  List<String> stateCategoryIdList = [];
  List<AppStream> stateAppStreamList = [];
  List<MenuItem> stateMenuItemList = [];
  final ScrollController scrollController = ScrollController();

  String categorySelected = 'aa';

  bool stateIsLoaded = false;

  void getData() async {
    appStreamFactory = AppStreamFactory();

    List<String> categoryIdList = await appStreamFactory.findAllCategoryList();

    List<MenuItem> menuItemList = [
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

    List<AppStream> appStreamList = await appStreamFactory
        .findListAppStreamByCategoryLimited(categorySelected, 30);

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
      CategoryIdArgment args =
          ModalRoute.of(context)?.settings.arguments as CategoryIdArgment;

      categorySelected = args.categoryId;

      getData();
    }

    return Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.grey[200],
        body: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
                width: 240,
                child: SideMenu(
                  menuItemList: stateMenuItemList,
                  selected: categorySelected,
                )),
            Container(
                width: 950,
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
                                      Image.network(icon),
                                      SizedBox(width: 20),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              appStreamLoop.name,
                                              style: TextStyle(fontSize: 30),
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
