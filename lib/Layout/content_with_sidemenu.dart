import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:dupot_easy_flatpak/Localizations/app_localizations.dart';
import 'package:dupot_easy_flatpak/Models/Flathub/appstream_factory.dart';
import 'package:dupot_easy_flatpak/Screens/Shared/menu_item.dart';
import 'package:dupot_easy_flatpak/Screens/Shared/sidemenu.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ContentWithSidemenu extends StatefulWidget {
  final Widget content;
  final String pageSelected;
  final String categoryIdSelected;

  final Function handleGoToHome;
  final Function handleGoToCategory;
  final Function handleGoToSearch;
  final Function handleGoToInstalledApps;
  final Function handleToggleDarkMode;

  const ContentWithSidemenu(
      {super.key,
      required this.content,
      required this.pageSelected,
      required this.categoryIdSelected,
      required this.handleGoToHome,
      required this.handleGoToCategory,
      required this.handleGoToSearch,
      required this.handleToggleDarkMode,
      required this.handleGoToInstalledApps});

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
      }, 'home', ''),
      MenuItem('InstalledApps', () {
        widget.handleGoToInstalledApps();
      }, 'installedApps', '')
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
        backgroundColor: Theme.of(context).primaryColorDark,
        //leading: const Icon(Icons.home),
        title: Text(
          'Easy Flatpak',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        leading: Builder(
          builder: (context) {
            return IconButton(
              color: Theme.of(context).primaryTextTheme.titleLarge!.color,
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        actions: [
          IconButton(
              onPressed: () {
                widget.handleToggleDarkMode();
                print('siwth dark');
              },
              icon: Icon(Icons.dark_mode)),
        ],
      ),
      resizeToAvoidBottomInset: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                  const SizedBox(
                    height: 10,
                  ),
                  TextButton(
                    child: Text(
                        '${AppLocalizations.of(context).tr('Website')}: www.dupot.org'),
                    onPressed: () {
                      launchUrl(Uri.parse('https://www.dupot.org'));
                    },
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Text(
                      '${AppLocalizations.of(context).tr('License')}:  LGPL-2.1'),
                  const SizedBox(
                    height: 10,
                  ),
                  Text(version)
                ]))
          ]) // Populate the Drawer in the next step.
          ),
    );
  }
}
