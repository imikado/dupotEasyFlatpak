import 'package:dupot_easy_flatpak/Infrastructure/Api/command_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/localization_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Control/Model/View/side_menu_view_model.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Entity/menu_item_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Entity/navigation_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/Theme/theme_text_style.dart';
import 'package:flutter/material.dart';

class SideMenuView extends StatefulWidget {
  final String pageSelected;
  final Map<String, String> argumentMapSelected;
  final Function handleGoTo;
  final List<String> applicationIdListInCart;
  final int interfaceVersion;
  final String searched;
  final int numberOfUpdates;

  const SideMenuView(
      {super.key,
      required this.pageSelected,
      required this.argumentMapSelected,
      required this.handleGoTo,
      required this.interfaceVersion,
      required this.applicationIdListInCart,
      required this.searched,
      required this.numberOfUpdates});

  @override
  State<SideMenuView> createState() => _SideMenuViewState();
}

class _SideMenuViewState extends State<SideMenuView> {
  List<MenuItemEntity> stateCategoryMenuItemList = [];
  List<MenuItemEntity> stateBottomMenuItemList = [];

  List<MenuItemEntity> stateCartMenuItemList = [];
  List<MenuItemEntity> stateSearchMenuItemList = [];

  String statePageSelected = '';
  String stateCategoryIdSelected = '';

  int stateNumberOfUpdates = 0;

  ScrollController scrollController = ScrollController();

  late ThemeTextStyle themeTextStyle;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    loadData(true);

    _searchController.text = widget.searched;

    super.initState();
  }

  bool isActive() {
    if (widget.argumentMapSelected
        .containsKey(NavigationEntity.argumentSubPage)) {
      return false;
    }

    return true;
  }

  @override
  void didUpdateWidget(covariant SideMenuView oldWidget) {
    loadData(false);

    super.didUpdateWidget(oldWidget);
  }

  void loadData(bool shouldCheckUpdates) async {
    List<MenuItemEntity> categoryMenuItemList =
        await SideMenuViewModel(handleGoTo: widget.handleGoTo)
            .getCategoryMenuItemEntityList();

    if (widget.pageSelected == NavigationEntity.pageCategory) {
      setState(() {
        statePageSelected = widget.pageSelected;
        stateCategoryIdSelected =
            widget.argumentMapSelected[NavigationEntity.argumentCategoryId]!;
      });
    } else {
      setState(() {
        statePageSelected = widget.pageSelected;
      });
    }

    setState(() {
      stateCategoryMenuItemList = categoryMenuItemList;
    });

    List<MenuItemEntity> cartMenuItemList =
        SideMenuViewModel(handleGoTo: widget.handleGoTo)
            .getCartMenuItemEntyList(widget.applicationIdListInCart);
    setState(() {
      stateCartMenuItemList = cartMenuItemList;
    });

    List<MenuItemEntity> searchMenuItemList =
        SideMenuViewModel(handleGoTo: widget.handleGoTo)
            .getSearchMenuItemEntyList(widget.pageSelected, widget.searched);
    setState(() {
      stateSearchMenuItemList = searchMenuItemList;
    });

    List<MenuItemEntity> bottomMenuItemList =
        await SideMenuViewModel(handleGoTo: widget.handleGoTo)
            .getBottomMenuItemEntityList(shouldCheckUpdates);

    setState(() {
      stateBottomMenuItemList = bottomMenuItemList;
    });
  }

  @override
  Widget build(BuildContext context) {
    themeTextStyle = ThemeTextStyle(context: context);

    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        if (!isActive()) const Icon(Icons.do_not_touch_rounded),
        Card(
            child: Padding(
                padding: const EdgeInsets.all(5),
                child: Row(
                  children: [
                    const Icon(Icons.search),
                    const SizedBox(
                      width: 5,
                    ),
                    Expanded(
                      child: TextField(
                        enabled: isActive(),
                        showCursor: true,
                        autofocus: false,
                        controller: _searchController,
                        style: Theme.of(context).textTheme.titleSmall,
                        decoration: InputDecoration.collapsed(
                          hintText: LocalizationApi().tr('Search...'),
                        ),
                        onChanged: (value) {
                          _searchController.clearComposing();

                          NavigationEntity.goToSearch(
                              handleGoTo: widget.handleGoTo, search: value);
                        },
                      ),
                    ),
                  ],
                ))),
        const SizedBox(
          height: 5,
        ),
        Column(
          children: stateCategoryMenuItemList
              .map((menuItemLoop) => getMenuLine(menuItemLoop))
              .toList(),
        ),
        if (stateSearchMenuItemList.isNotEmpty)
          const SizedBox(
            height: 28,
          ),
        if (stateSearchMenuItemList.isNotEmpty)
          Column(
              children: stateSearchMenuItemList
                  .map((menuItemLoop) => getMenuLine(menuItemLoop))
                  .toList()),
        if (stateCartMenuItemList.isNotEmpty)
          const SizedBox(
            height: 28,
          ),
        if (stateCartMenuItemList.isNotEmpty)
          Column(
              children: stateCartMenuItemList
                  .map((menuItemLoop) => getMenuLine(menuItemLoop))
                  .toList()),
        const SizedBox(
          height: 28,
        ),
        Column(
          children: stateBottomMenuItemList
              .map((menuItemLoop) => getMenuLine(menuItemLoop))
              .toList(),
        ),
      ],
    );
  }

  Widget getMenuLine(MenuItemEntity menuItemLoop) {
    bool isSelected = false;
    if (menuItemLoop.isCategory() &&
        menuItemLoop.pageSelected == statePageSelected &&
        menuItemLoop.categoryIdSelected == stateCategoryIdSelected) {
      isSelected = true;
    } else if (!menuItemLoop.isCategory() &&
        menuItemLoop.pageSelected == statePageSelected) {
      isSelected = true;
    }

    return InkWell(
        borderRadius: BorderRadius.circular(8.0),
        onTap: !isActive()
            ? null
            : () {
                menuItemLoop.action();
              },
        child: Card(
            color: themeTextStyle.getHeadlineBackgroundColor(isSelected),
            elevation: 0,
            margin: const EdgeInsets.all(0),
            child: Row(
              children: [
                menuItemLoop.badge.isNotEmpty
                    ? IconButton(
                        padding: const EdgeInsets.all(0),
                        icon: Badge(
                            label: Padding(
                                padding: const EdgeInsets.all(2),
                                child: Text(menuItemLoop.badge,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: themeTextStyle
                                            .getBadgetTextColor(isSelected)))),
                            backgroundColor: themeTextStyle
                                .getHeadlineBackgroundColor(!isSelected),
                            child: Icon(menuItemLoop.icon,
                                color: themeTextStyle
                                    .getHeadlineTextColor(isSelected))),
                        onPressed: null)
                    : IconButton(
                        padding: const EdgeInsets.all(0),
                        icon: Icon(menuItemLoop.icon,
                            color: themeTextStyle
                                .getHeadlineTextColor(isSelected)),
                        onPressed: null,
                      ),
                const SizedBox(width: 8),
                Text(
                  LocalizationApi().tr(menuItemLoop.label),
                  style: isSelected
                      ? TextStyle(
                          color:
                              themeTextStyle.getHeadlineTextColor(isSelected),
                          backgroundColor: Theme.of(context)
                              .textSelectionTheme
                              .selectionHandleColor)
                      : null,
                ),
              ],
            )));
  }
}
