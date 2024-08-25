import 'package:animated_sidebar/animated_sidebar.dart';
import 'package:dupot_easy_flatpak/Components/app_button.dart';
import 'package:dupot_easy_flatpak/Components/sidemenu.dart';
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
  List<SidebarItem> stateMenuItemList = [];
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

    List<List<AppStream>> appStreamListList = [];

    List<String> categoryIdList = await appStreamFactory.findAllCategoryList();

    List<SidebarItem> sideMenuItemList = [
      SidebarItem(icon: Icons.home, text: 'home'),
    ];

    for (String categoryIdLoop in categoryIdList) {
      List<AppStream> appStreamList =
          await appStreamFactory.findListAppStreamByCategory(categoryIdLoop);

      appStreamListList.add(appStreamList);

      sideMenuItemList.add(
        SidebarItem(icon: Icons.app_blocking_sharp, text: categoryIdLoop),
      );
    }

    setState(() {
      stateCategoryIdList = categoryIdList;
      stateAppStreamListList = appStreamListList;
      stateMenuItemList = sideMenuItemList;
    });
  }

  @override
  Widget build(BuildContext context) {
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
            SideMenu(items: stateMenuItemList),
            Container(
                width: 950,
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
                              appStreamList: stateAppStreamListList[index]);
                        })))
          ],
        ));
  }
}
