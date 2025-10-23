import 'package:dupot_easy_flatpak/Domain/Entity/user_settings_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Control/Model/View/side_menu_view_model.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Entity/menu_item_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Entity/navigation_entity.dart';
import 'package:flutter/material.dart';
import 'package:libadwaita/libadwaita.dart';
import 'package:libadwaita_window_manager/libadwaita_window_manager.dart';

class NewInterfaceWithDrawerAndAnimation extends StatefulWidget {
  final Widget menu;
  final Widget content;
  final Widget subContent;
  final bool hasSubContent;
  final bool hasPrevious;
  final Function handleGoToPrevious;
  final String pageSelected;
  final String title;

  const NewInterfaceWithDrawerAndAnimation(
      {super.key,
      required this.menu,
      required this.content,
      required this.subContent,
      required this.hasSubContent,
      required this.hasPrevious,
      required this.handleGoToPrevious,
      required this.pageSelected,
      required this.title});

  @override
  NewInterfaceWithDrawerAndAnimationState createState() =>
      NewInterfaceWithDrawerAndAnimationState();
}

class NewInterfaceWithDrawerAndAnimationState
    extends State<NewInterfaceWithDrawerAndAnimation> {
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

    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: true,
          title: Text(widget.title),
          actions: [],
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
        drawer: Drawer(child: widget.menu),
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
        ));
  }
}
