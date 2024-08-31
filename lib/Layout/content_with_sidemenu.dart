import 'package:dupot_easy_flatpak/Models/Flathub/appstream_factory.dart';
import 'package:dupot_easy_flatpak/Screens/Shared/menu_item.dart';
import 'package:dupot_easy_flatpak/Screens/Shared/sidemenu.dart';
import 'package:flutter/material.dart';

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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            leading: const Icon(Icons.home), title: const Text('Easy Flatpak')),
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
          Expanded(child: widget.content)
        ]));
  }
}
