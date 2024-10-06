import 'package:dupot_easy_flatpak/Localizations/app_localizations.dart';
import 'package:dupot_easy_flatpak/Models/Flathub/appstream_factory.dart';
import 'package:dupot_easy_flatpak/Screens/Shared/menu_item.dart';
import 'package:dupot_easy_flatpak/Screens/Shared/my_drawer.dart';
import 'package:dupot_easy_flatpak/Screens/Shared/sidemenu.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ContentWithSidemenuAndSearch extends StatefulWidget {
  final Widget content;
  final String pageSelected;
  final String categoryIdSelected;

  final Function handleGoToHome;
  final Function handleGoToCategory;
  final Function handleGoToSearch;
  final Function handleGoToInstalledApps;
  final Function handleSearch;
  final Function handleSetLocale;
  final String defaultSearch;

  const ContentWithSidemenuAndSearch(
      {super.key,
      required this.content,
      required this.pageSelected,
      required this.categoryIdSelected,
      required this.handleGoToHome,
      required this.handleGoToCategory,
      required this.handleGoToSearch,
      required this.handleSearch,
      required this.handleGoToInstalledApps,
      required this.handleSetLocale,
      required this.defaultSearch});

  @override
  _ContentWithSidemenuAndSearchState createState() =>
      _ContentWithSidemenuAndSearchState();
}

class _ContentWithSidemenuAndSearchState
    extends State<ContentWithSidemenuAndSearch> {
  List<MenuItem> stateMenuItemList = [];

  String version = '';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _searchController.text = widget.defaultSearch;

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
    }

    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    version = packageInfo.version;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColorDark,
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
        title: TextField(
          autofocus: true,
          controller: _searchController,
          style: Theme.of(context).textTheme.titleLarge,
          cursorColor: Colors.white,
          decoration: InputDecoration(
            hintText: AppLocalizations().tr('Search...'),
            hintStyle: const TextStyle(color: Colors.white54),
            border: InputBorder.none,
          ),
          onChanged: (value) {
            widget.handleSearch(value);
          },
        ),
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
        Expanded(child: widget.content)
      ]),
      drawer: MyDrawer(
        version: version,
        handleSetLocale: widget.handleSetLocale,
      ),
    );
  }
}
