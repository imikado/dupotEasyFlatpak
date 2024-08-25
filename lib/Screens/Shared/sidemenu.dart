import 'package:dupot_easy_flatpak/Screens/Shared/menu_item.dart';
import 'package:flutter/material.dart';
import 'package:animated_sidebar/animated_sidebar.dart';

class SideMenu extends StatelessWidget {
  const SideMenu(
      {super.key, required this.menuItemList, required this.selected});

  final List<MenuItem> menuItemList;
  final String selected;

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 200,
        child: Card(
            child: ListView(
          children: menuItemList.map((menuItemLoop) {
            return ListTile(
              selected: menuItemLoop.label == selected,
              onTap: () {
                menuItemLoop.action();
              },
              title: Text(menuItemLoop.label),
            );
          }).toList(),
        )));

/*
    return AnimatedSidebar(
      expanded: MediaQuery.of(context).size.width > 600,
      items: items,
      selectedIndex: 0,
      onItemSelected: (index) => print(index),
      headerIcon: Icons.list,
      headerIconColor: Colors.amberAccent,
      headerText: 'Categories',
    );
    */
  }
}
