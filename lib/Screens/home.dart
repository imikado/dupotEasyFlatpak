import 'package:dupot_easy_flatpak/Screens/Shared/Arguments/categoryIdArgument.dart';
import 'package:dupot_easy_flatpak/Screens/Shared/app_menu.dart';
import 'package:dupot_easy_flatpak/Screens/Shared/menu_item.dart';
import 'package:dupot_easy_flatpak/Screens/Shared/sidemenu.dart';
import 'package:dupot_easy_flatpak/Models/Flathub/appstream.dart';
import 'package:dupot_easy_flatpak/Models/Flathub/appstream_factory.dart';
import 'package:dupot_easy_flatpak/Screens/Store/block.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  final TextEditingController _searchController = TextEditingController();

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

    /*List<SidebarItem> sideMenuItemList = [
      SidebarItem(icon: Icons.home, text: 'home'),
    ];*/

    for (String categoryIdLoop in categoryIdList) {
      List<AppStream> appStreamList = await appStreamFactory
          .findListAppStreamByCategoryLimited(categoryIdLoop, 8);

      appStreamListList.add(appStreamList);

      /*
      sideMenuItemList.add(
        SidebarItem(icon: Icons.app_blocking_sharp, text: categoryIdLoop),
      );*/
    }

    setState(() {
      stateCategoryIdList = categoryIdList;
      stateAppStreamListList = appStreamListList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(leading: Icon(Icons.home), title: Text('Easy Flatpak')),
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.grey[200],
        body: Container(
            child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
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
        )));
  }
}
