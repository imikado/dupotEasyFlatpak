import 'package:dupot_easy_flatpak/Infrastructure/Api/localization_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Entity/navigation_entity.dart';
import 'package:flutter/material.dart';

class NewInterfaceWithDrawerAndAnimation extends StatefulWidget {
  final Widget menu;
  final Widget content;
  final Widget subContent;
  final bool hasSubContent;
  final bool hasPrevious;
  final Function handleGoToPrevious;
  final String pageSelected;
  final String title;
  final Function handleSetSearched;
  final String searched;

  const NewInterfaceWithDrawerAndAnimation({
    super.key,
    required this.menu,
    required this.content,
    required this.subContent,
    required this.hasSubContent,
    required this.hasPrevious,
    required this.handleGoToPrevious,
    required this.pageSelected,
    required this.handleSetSearched,
    required this.searched,
    required this.title,
  });

  @override
  NewInterfaceWithDrawerAndAnimationState createState() =>
      NewInterfaceWithDrawerAndAnimationState();
}

class NewInterfaceWithDrawerAndAnimationState
    extends State<NewInterfaceWithDrawerAndAnimation>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _drawerController;
  bool _isDrawerOpen = false;

  final TextEditingController _searchController = TextEditingController();

  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    _searchController.text = widget.searched;

    _drawerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void didUpdateWidget(covariant NewInterfaceWithDrawerAndAnimation oldWidget) {
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

  @override
  void dispose() {
    _drawerController.dispose();
    super.dispose();
  }

  void _toggleDrawer() {
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
    });

    if (_isDrawerOpen) {
      _drawerController.forward();
    } else {
      _drawerController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(
      padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
      child: Card(
        elevation: 4,
        color: Theme.of(context).cardColor,
        child: widget.content,
      ),
    );

    return Stack(
      children: [
        Scaffold(
            key: _scaffoldKey,
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: Expanded(
                  child: TextField(
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
              )),
              actions: [],
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: _toggleDrawer,
              ),
            ),
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
                              color: Theme.of(context).secondaryHeaderColor,
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
                          padding: const EdgeInsets.all(14),
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
                        child: Container(
                          width: 304,
                          color:
                              Theme.of(context).drawerTheme.backgroundColor ??
                                  Theme.of(context).canvasColor,
                          child: widget.menu,
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
}
