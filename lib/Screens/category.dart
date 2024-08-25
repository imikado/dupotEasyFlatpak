import 'package:animated_sidebar/animated_sidebar.dart';
import 'package:dupot_easy_flatpak/Screens/Shared/Arguments/categoryIdArgument.dart';
import 'package:dupot_easy_flatpak/Screens/Shared/app_button.dart';
import 'package:dupot_easy_flatpak/Screens/Shared/menu_item.dart';
import 'package:dupot_easy_flatpak/Screens/Shared/sidemenu.dart';
import 'package:dupot_easy_flatpak/Localizations/app_localizations.dart';
import 'package:dupot_easy_flatpak/Models/Flathub/appstream.dart';
import 'package:dupot_easy_flatpak/Models/Flathub/appstream_factory.dart';
import 'package:dupot_easy_flatpak/Screens/Store/block.dart';
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
      MenuItem('home', () {
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
        appBar: AppBar(
          leading: Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            },
          ),
          title: Text(
            AppLocalizations.of(context).tr("applications_available"),
            style: const TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: Colors.blueGrey,
          actions: const [],
        ),
        body: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SideMenu(
              menuItemList: stateMenuItemList,
              selected: categorySelected,
            ),
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
                                      Text(appStreamLoop.name)
                                    ],
                                  ),
                                  Text(
                                    appStreamLoop.summary,
                                    textAlign: TextAlign.left,
                                  )
                                ],
                              ),
                            );
                          }
                        })))
          ],
        ));
  }
}
