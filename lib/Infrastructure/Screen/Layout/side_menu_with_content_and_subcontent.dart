import 'package:dupot_easy_flatpak/Infrastructure/Entity/navigation_entity.dart';
import 'package:flutter/material.dart';
import 'package:libadwaita/libadwaita.dart';
import 'package:libadwaita_window_manager/libadwaita_window_manager.dart';

class SideMenuWithContentAndSubContentLayout extends StatefulWidget {
  final Widget menu;
  final Widget content;
  final Widget subContent;
  final bool hasSubContent;
  final bool hasPrevious;
  final Function handleGoToPrevious;
  final String pageSelected;
  final Function changeTheme;

  const SideMenuWithContentAndSubContentLayout(
      {super.key,
      required this.menu,
      required this.content,
      required this.subContent,
      required this.hasSubContent,
      required this.hasPrevious,
      required this.handleGoToPrevious,
      required this.pageSelected,
      required this.changeTheme});

  @override
  SideMenuWithContentAndSubContentLayoutState createState() =>
      SideMenuWithContentAndSubContentLayoutState();
}

class SideMenuWithContentAndSubContentLayoutState
    extends State<SideMenuWithContentAndSubContentLayout> {
  @override
  Widget build(BuildContext context) {
    Widget content = Padding(
      padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
      child: Card(
        elevation: 4,
        color: Theme.of(context).cardColor,
        child: widget.content,
      ),
    );

    return AdwScaffold(
      actions: AdwActions().windowManager,
      start: [
        AdwHeaderButton(
          icon: const Icon(Icons.nightlight_round, size: 15),
          onPressed: () => widget.changeTheme(),
        ),
      ],
      body: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.all(5),
                child: SizedBox(
                  width: 270,
                  child: Card(
                    elevation: 4,
                    color: Theme.of(context).primaryColorLight,
                    child: widget.menu,
                  ),
                ),
              ),
              widget.hasSubContent
                  ? SizedBox(width: 500, child: content)
                  : Expanded(child: content),
              if (widget.hasSubContent)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Card(
                      elevation: 4,
                      color: Theme.of(context).secondaryHeaderColor,
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
                  padding: const EdgeInsets.all(14),
                  elevation: 6,
                ),
                label: const Icon(Icons.arrow_back_rounded),
              ),
            ),
        ],
      ),
    );
  }
}

/**
 

 floatingActionButton: widget.hasPrevious &
                !widget.hasSubContent &
                (widget.pageSelected == NavigationEntity.pageApplication)
            ? FloatingActionButton(
                backgroundColor: Theme.of(context).secondaryHeaderColor,
                onPressed: () {
                  widget.handleGoToPrevious();
                },
                child: const Icon(Icons.arrow_back_rounded))
            : null
 */
