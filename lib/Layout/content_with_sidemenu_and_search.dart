import 'package:dupot_easy_flatpak/Models/Flathub/appstream_factory.dart';
import 'package:dupot_easy_flatpak/Screens/Shared/menu_item.dart';
import 'package:dupot_easy_flatpak/Screens/Shared/sidemenu.dart';
import 'package:flutter/material.dart';

class ContentWithSidemenuAndSearch extends StatefulWidget {
  late Widget content;
  late String pageSelected;
  late String categoryIdSelected;

  late Function handleGoToHome;
  late Function handleGoToCategory;
  late Function handleGoToSearch;
  late Function handleSearch;

  ContentWithSidemenuAndSearch(
      {super.key,
      required this.content,
      required this.pageSelected,
      required this.categoryIdSelected,
      required this.handleGoToHome,
      required this.handleGoToCategory,
      required this.handleGoToSearch,
      required this.handleSearch});

  @override
  _ContentWithSidemenuAndSearchState createState() =>
      _ContentWithSidemenuAndSearchState();
}

class _ContentWithSidemenuAndSearchState
    extends State<ContentWithSidemenuAndSearch> {
  List<MenuItem> stateMenuItemList = [];

  final TextEditingController _searchController = TextEditingController();

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
          leading: const Icon(Icons.home),
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
              if (value.length > 2) {
                widget.handleSearch(value);
              }
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
          Expanded(child: widget.content)
        ]));
  }
}
