import 'package:dupot_easy_flatpak/Screens/Shared/menu_item.dart';
import 'package:flutter/material.dart';

class SideMenu extends StatelessWidget {
  const SideMenu(
      {super.key, required this.menuItemList, required this.selected});

  final List<MenuItem> menuItemList;
  final String selected;

  @override
  Widget build(BuildContext context) {
    return Card(
        color: const Color.fromARGB(255, 205, 230, 250),
        margin: EdgeInsets.all(0),
        elevation: 5,
        child: ListView(
          children: menuItemList.map((menuItemLoop) {
            bool isSelected = false;
            if (menuItemLoop.label == selected) {
              isSelected = true;
            }

            return ListTile(
              tileColor: isSelected ? Colors.blueGrey : null,

              // selected: menuItemLoop.label == selected,
              onTap: () {
                menuItemLoop.action();
              },
              title: Text(
                menuItemLoop.label,
                style: isSelected ? TextStyle(color: Colors.white) : null,
              ),
            );
          }).toList(),
        ));

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
