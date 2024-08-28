import 'package:dupot_easy_flatpak/Screens/Shared/Arguments/categoryIdArgument.dart';
import 'package:dupot_easy_flatpak/Screens/Shared/menu_item.dart';
import 'package:dupot_easy_flatpak/Screens/Shared/sidemenu.dart';
import 'package:dupot_easy_flatpak/Localizations/app_localizations.dart';
import 'package:dupot_easy_flatpak/Models/Flathub/appstream.dart';
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
  List<String> stateCategoryIdList = [];
  List<List<AppStream>> stateAppStreamListList = [];
  List<MenuItem> stateMenuItemList = [];
  final ScrollController scrollController = ScrollController();

  String menuSelected = 'Home';
  String appPath = '';

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
    appPath = await appStreamFactory.getPath();

    List<List<AppStream>> appStreamListList = [];

    List<String> categoryIdList = await appStreamFactory.findAllCategoryList();

    List<MenuItem> menuItemList = [
      MenuItem(menuSelected, () {
        Navigator.popAndPushNamed(context, '/');
      })
    ];

    /*List<SidebarItem> sideMenuItemList = [
      SidebarItem(icon: Icons.home, text: 'home'),
    ];*/

    for (String categoryIdLoop in categoryIdList) {
      List<AppStream> appStreamList = await appStreamFactory
          .findListAppStreamByCategoryLimited(categoryIdLoop, 8);

      appStreamListList.add(appStreamList);

      menuItemList.add(MenuItem(categoryIdLoop, () {
        Navigator.popAndPushNamed(context, '/category',
            arguments: CategoryIdArgment(categoryIdLoop));
        //print(categoryIdLoop);
      }));

      /*
      sideMenuItemList.add(
        SidebarItem(icon: Icons.app_blocking_sharp, text: categoryIdLoop),
      );*/
    }

    setState(() {
      stateCategoryIdList = categoryIdList;
      stateAppStreamListList = appStreamListList;
      stateMenuItemList = menuItemList;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  selected: menuSelected,
                )),
            Container(
                width: 980,
                child: Scrollbar(
                    interactive: false,
                    thumbVisibility: true,
                    controller: scrollController,
                    child: ListView.builder(
                        itemCount: stateCategoryIdList.length,
                        controller: scrollController,
                        itemBuilder: (context, index) {
                          return Block(
                              categoryId: stateCategoryIdList[index],
                              appStreamList: stateAppStreamListList[index],
                              appPath: appPath);
                        })))
          ],
        ));
  }
}
