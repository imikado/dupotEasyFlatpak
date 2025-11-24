import 'package:dupot_easy_flatpak/Infrastructure/Api/localization_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Control/Model/View/side_menu_view_model.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Entity/menu_item_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Entity/navigation_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/Theme/theme_text_style.dart';
import 'package:flutter/material.dart';

class NewSideMenuView extends StatefulWidget {
  final Function handleGoTo;
  final List<String> applicationIdListInCart;
  final String searched;
  final int numberOfUpdates;
  final bool isActive;
  final Function handleSetSearched;
  final bool displaySearch;
  final Function handleCloseMenu;

  const NewSideMenuView(
      {super.key,
      required this.handleGoTo,
      required this.applicationIdListInCart,
      required this.searched,
      required this.numberOfUpdates,
      required this.isActive,
      required this.handleSetSearched,
      required this.displaySearch,
      required this.handleCloseMenu});

  @override
  State<NewSideMenuView> createState() => NewSideMenuViewState();
}

class NewSideMenuViewState extends State<NewSideMenuView>
    with AutomaticKeepAliveClientMixin {
  List<MenuItemEntity> stateCategoryMenuItemList = [];
  List<MenuItemEntity> stateBottomMenuItemList = [];

  List<MenuItemEntity> stateCartMenuItemList = [];
  List<MenuItemEntity> stateSearchMenuItemList = [];

  int stateNumberOfUpdates = 0;

  ScrollController scrollController = ScrollController();

  late ThemeTextStyle themeTextStyle;

  final TextEditingController _searchController = TextEditingController();

  final FocusNode _searchFocusNode = FocusNode();

  String stateMenuSelected = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    print('initState');
    loadData(true);

    _searchController.text = widget.searched;

    super.initState();
  }

  bool isActive() {
    return widget.isActive;
  }

  @override
  void didUpdateWidget(covariant NewSideMenuView oldWidget) {
    loadData(false);

    if (oldWidget.searched != widget.searched &&
        _searchController.text != widget.searched) {
      final cursorPosition = _searchController.selection;

      _searchController.text = widget.searched;

      _searchController.selection = TextSelection.fromPosition(
        TextPosition(offset: widget.searched.length),
      );
    }

    super.didUpdateWidget(oldWidget);
  }

  void loadData(bool shouldCheckUpdates) async {
    if (!mounted) {
      return;
    }
    List<MenuItemEntity> categoryMenuItemList =
        await SideMenuViewModel(handleGoTo: widget.handleGoTo)
            .getCategoryMenuItemEntityList();

    List<MenuItemEntity> cartMenuItemList =
        SideMenuViewModel(handleGoTo: widget.handleGoTo)
            .getCartMenuItemEntyList(widget.applicationIdListInCart);

    List<MenuItemEntity> searchMenuItemList =
        SideMenuViewModel(handleGoTo: widget.handleGoTo)
            .getSearchMenuItemEntyListWithoutPage(
                widget.searched, widget.displaySearch);

    List<MenuItemEntity> bottomMenuItemList =
        await SideMenuViewModel(handleGoTo: widget.handleGoTo)
            .getBottomMenuItemEntityList(shouldCheckUpdates);

    if (!mounted) return;
    setState(() {
      stateCategoryMenuItemList = categoryMenuItemList;
      stateCartMenuItemList = cartMenuItemList;
      stateSearchMenuItemList = searchMenuItemList;

      stateBottomMenuItemList = bottomMenuItemList;
    });
  }

  void requestFocus() {
    if (mounted) {
      _searchFocusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    themeTextStyle = ThemeTextStyle(context: context);

    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        if (!isActive()) const Icon(Icons.do_not_touch_rounded),
        if (widget.displaySearch)
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
                          focusNode: _searchFocusNode,
                          showCursor: true,
                          autofocus: true,
                          controller: _searchController,
                          style: Theme.of(context).textTheme.titleSmall,
                          decoration: InputDecoration(
                            hintText: LocalizationApi().tr('Search...'),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 2.0),
                            filled: true,
                            fillColor: Colors.transparent,
                            border: InputBorder
                                .none, // visually similar to .collapsed()

                            isDense: false,
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close),
                                    splashRadius: 16,
                                    onPressed: () {
                                      _searchController.clear();
                                      widget.handleSetSearched('');
                                      _searchFocusNode.requestFocus();
                                      if (mounted) {
                                        setState(() {});
                                      } // Refresh suffixIcon
                                    },
                                  )
                                : null,
                          ),
                          onChanged: (value) {
                            if (mounted) {
                              setState(() {}); // So the suffixIcon refreshes
                            }
                            widget.handleSetSearched(value);
                          },
                        ),
                      ),
                    ],
                  ))),
        const SizedBox(
          height: 5,
        ),
        Column(
          key: const PageStorageKey('SideMenuViewList'),
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
          key: const PageStorageKey('SideMenuViewListBottomMenu'),
          children: stateBottomMenuItemList
              .map((menuItemLoop) => getMenuLine(menuItemLoop))
              .toList(),
        ),
      ],
    );
  }

  Widget getMenuLine(MenuItemEntity menuItemLoop) {
    bool isSelected = false;
    if (menuItemLoop.label == stateMenuSelected) {
      isSelected = true;
    }

    return InkWell(
        borderRadius: BorderRadius.circular(8.0),
        onTap: !isActive()
            ? null
            : () {
                menuItemLoop.action();
                setState(() {
                  stateMenuSelected = menuItemLoop.label;
                });
                if (!widget.displaySearch) {
                  widget.handleCloseMenu();
                }
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
