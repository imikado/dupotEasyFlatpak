import 'package:dupot_easy_flatpak/Infrastructure/Api/command_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/localization_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Entity/navigation_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/View/new_side_menu_view.dart';
import 'package:flutter/material.dart';

class NewInterfaceWithDrawerAndAnimation extends StatefulWidget {
  final Widget content;
  final Widget subContent;
  final bool hasSubContent;
  final bool hasPrevious;
  final Function handleGoToPrevious;
  final String pageSelected;
  final Function handleSetSearched;
  final String searched;

  final Function handleGoTo;
  final List<String> applicationIdListInCart;

  const NewInterfaceWithDrawerAndAnimation({
    super.key,
    required this.content,
    required this.handleGoTo,
    required this.applicationIdListInCart,
    required this.subContent,
    required this.hasSubContent,
    required this.hasPrevious,
    required this.handleGoToPrevious,
    required this.pageSelected,
    required this.handleSetSearched,
    required this.searched,
  });

  @override
  NewInterfaceWithDrawerAndAnimationState createState() =>
      NewInterfaceWithDrawerAndAnimationState();
}

class NewInterfaceWithDrawerAndAnimationState
    extends State<NewInterfaceWithDrawerAndAnimation>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final AnimationController _drawerController;
  bool _isDrawerOpen = false;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  bool displayMenuSearch = false;

  late AnimationController _controller;
  late CurvedAnimation _myAnimation;

  // Keep one listener to refresh the clear (x) icon
  void _onSearchChanged() {
    if (!mounted) return;
    setState(() {}); // just rebuild to update suffixIcon visibility
  }

  @override
  void initState() {
    super.initState();

    _searchController.text = widget.searched;
    _searchController.addListener(_onSearchChanged);

    _drawerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void didUpdateWidget(covariant NewInterfaceWithDrawerAndAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Sync external searched value to the field (no onChanged fired)
    if (oldWidget.searched != widget.searched &&
        _searchController.text != widget.searched) {
      _searchController.value = TextEditingValue(
        text: widget.searched,
        selection: TextSelection.collapsed(offset: widget.searched.length),
      );
    }
  }

  @override
  void dispose() {
    // Dispose everything that holds native resources or listeners
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _drawerController.dispose();
    super.dispose();
  }

  void _toggleDrawer() {
    if (!mounted) return;
    setState(() => _isDrawerOpen = !_isDrawerOpen);

    // Drive the animation only if we're still mounted
    if (!mounted) return;
    if (_isDrawerOpen) {
      _drawerController.forward();
    } else {
      _drawerController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 1370 || width < 1600 && widget.hasSubContent) {
      displayMenuSearch = false;
      return returnLayoutWithDrawer(context);
    }
    displayMenuSearch = true;
    return returnLayoutFull(context);
  }

  Widget returnLayoutWithDrawer(BuildContext context) {
    Widget content = Padding(
      padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
      child: widget.content,
    );
    return Stack(
      children: [
        Scaffold(
            key: _scaffoldKey,
            appBar: getAppBar(),
            body: SizedBox.expand(
              child: Stack(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      widget.hasSubContent
                          ? Expanded(flex: 2, child: content)
                          : Expanded(child: content),
                      if (widget.hasSubContent)
                        Expanded(
                          flex: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: Card(
                              elevation: 4,
                              //    color: Theme.of(context).secondaryHeaderColor,
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(0, 10, 0, 10),
                                child: widget.subContent,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Floating button overlay
                  if (widget.hasPrevious &&
                      !widget.hasSubContent &&
                      widget.pageSelected == NavigationEntity.pageApplication)
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: ElevatedButton.icon(
                        onPressed: () => widget.handleGoToPrevious(),
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(24),
                          elevation: 6,
                        ),
                        label: const Icon(Icons.arrow_back_rounded),
                      ),
                    ),
                ],
              ),
            )),

        // Custom drawer that stays mounted - OUTSIDE Scaffold to be on top
        AnimatedBuilder(
          animation: _drawerController,
          builder: (context, child) {
            return Visibility(
              visible: _drawerController.value > 0,
              maintainState: true, // Keep state even when not visible
              maintainAnimation: true,
              maintainSize: false,
              child: Stack(
                children: [
                  // Backdrop
                  if (_drawerController.value > 0)
                    GestureDetector(
                      onTap: _toggleDrawer,
                      child: Container(
                        color: Colors.black
                            .withOpacity(0.5 * _drawerController.value),
                      ),
                    ),

                  // Drawer content
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FractionalTranslation(
                      translation: Offset(-1 + _drawerController.value, 0),
                      child: Material(
                        elevation: 16,
                        child: SizedBox(
                          width: 304,
                          child: getMenu(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget getMenu() {
    return NewSideMenuView(
      handleGoTo: widget.handleGoTo,
      applicationIdListInCart: widget.applicationIdListInCart,
      searched: widget.searched,
      numberOfUpdates: CommandApi().getNumberOfUpdates(),
      isActive: true,
      handleSetSearched: widget.handleSetSearched,
      displaySearch: displayMenuSearch,
      handleCloseMenu: _toggleDrawer,
    );
  }

  Widget returnLayoutFull(BuildContext context) {
    Widget content = Padding(
      padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
      child: widget.content,
    );
    return Stack(children: [
      Scaffold(
          key: _scaffoldKey,
          body: SizedBox.expand(
            child: Stack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Material(
                      elevation: 8,
                      child: SizedBox(
                        width: 300,
                        child: getMenu(),
                      ),
                    ),
                    widget.hasSubContent
                        ? Expanded(flex: 3, child: content)
                        : Expanded(flex: 2, child: content),
                    if (widget.hasSubContent)
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: Card(
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                              child: widget.subContent,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                // Floating button overlay
                if (widget.hasPrevious &&
                    !widget.hasSubContent &&
                    widget.pageSelected == NavigationEntity.pageApplication)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: ElevatedButton.icon(
                      onPressed: () => widget.handleGoToPrevious(),
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(24),
                        elevation: 6,
                      ),
                      label: const Icon(Icons.arrow_back_rounded),
                    ),
                  ),
              ],
            ),
          )),
    ]);
  }

  bool hasPreviousButton() {
    if (widget.hasPrevious &&
        !widget.hasSubContent &&
        widget.pageSelected == NavigationEntity.pageApplication) {
      return true;
    }
    return false;
  }

  FloatingActionButton getPreviousButton() {
    return FloatingActionButton(
      onPressed: () => widget.handleGoToPrevious(),
      child: Icon(Icons.arrow_back_ios_new_outlined),
    );
  }

  PreferredSizeWidget? getAppBar() {
    return AppBar(
      automaticallyImplyLeading: true,
      title: TextField(
        focusNode: _searchFocusNode,
        showCursor: true,
        autofocus: true,
        controller: _searchController,
        decoration: InputDecoration(
          hintText: LocalizationApi().tr('Search...'),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close),
                  splashRadius: 16,
                  onPressed: () {
                    // Clear without triggering setState-after-dispose
                    _searchController.clear();
                    widget.handleSetSearched('');
                    // If the widget gets popped by parent, this does nothing harmful
                    if (mounted) _searchFocusNode.requestFocus();
                  },
                )
              : null,
        ),
        onChanged: (value) {
          // Parent might navigate away here; no setState in this widget
          widget.handleSetSearched(value);
        },
      ),
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: _toggleDrawer,
      ),
      actions: const [],
    );
  }
}
