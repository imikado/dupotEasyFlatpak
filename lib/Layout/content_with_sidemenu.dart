import 'package:dupot_easy_flatpak/Localizations/app_localizations.dart';
import 'package:dupot_easy_flatpak/Models/Flathub/appstream_factory.dart';
import 'package:dupot_easy_flatpak/Screens/Shared/menu_item.dart';
import 'package:dupot_easy_flatpak/Screens/Shared/sidemenu.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ContentWithSidemenu extends StatefulWidget {
  late Widget content;
  late String pageSelected;
  late String categoryIdSelected;

  late Function handleGoToHome;
  late Function handleGoToCategory;
  late Function handleGoToSearch;

  ContentWithSidemenu(
      {super.key,
      required this.content,
      required this.pageSelected,
      required this.categoryIdSelected,
      required this.handleGoToHome,
      required this.handleGoToCategory,
      required this.handleGoToSearch});

  @override
  _ContentWithSidemenuState createState() => _ContentWithSidemenuState();
}

class _ContentWithSidemenuState extends State<ContentWithSidemenu> {
  List<MenuItem> stateMenuItemList = [];

  String version = '';

  @override
  void initState() {
    super.initState();

    loadData();
  }

  Future<void> loadData() async {
    AppStreamFactory appStreamFactory = AppStreamFactory();
    List<MenuItem> menuItemList = [
      MenuItem('Search', () {
        widget.handleGoToSearch();
      }, 'search', ''),
      MenuItem('Home', () {
        widget.handleGoToHome();
      }, 'home', '')
    ];
    List<String> categoryIdList = await appStreamFactory.findAllCategoryList();

    for (String categoryIdLoop in categoryIdList) {
      menuItemList.add(MenuItem(categoryIdLoop, () {
        widget.handleGoToCategory(categoryIdLoop);
      }, 'category', categoryIdLoop));

      setState(() {
        stateMenuItemList = menuItemList;
      });

      PackageInfo packageInfo = await PackageInfo.fromPlatform();

      version = packageInfo.version;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        //leading: const Icon(Icons.home),
        title: const Text('Easy Flatpak'),
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
      ),
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.grey[200],
      body: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Container(
            width: 240,
            child: SideMenu(
              menuItemList: stateMenuItemList,
              pageSelected: widget.pageSelected,
              categoryIdSelected: widget.categoryIdSelected,
            )),
        const SizedBox(width: 10),
        Expanded(child: widget.content),
      ]),
      drawer: Drawer(
          child: ListView(
              // Important: Remove any padding from the ListView.
              padding: EdgeInsets.zero,
              children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.blue,
              ),
              child: Image.asset('assets/logos/512x512.png'),
            ),
            Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(children: [
                  Text(
                      '${AppLocalizations.of(context).tr('Author')}: Michael Bertocchi'),
                  SizedBox(
                    height: 10,
                  ),
                  Text(
                      '${AppLocalizations.of(context).tr('Website')}: www.dupot.org'),
                  SizedBox(
                    height: 10,
                  ),
                  Text(
                      '${AppLocalizations.of(context).tr('License')}:  LGPL-2.1'),
                  SizedBox(
                    height: 10,
                  ),
                  Text(version)
                ]))
          ]) // Populate the Drawer in the next step.
          ),
    );
  }
}
