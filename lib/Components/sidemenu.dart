import 'package:flutter/material.dart';
import 'package:animated_sidebar/animated_sidebar.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({super.key, required this.items});

  final List<SidebarItem> items;

  @override
  Widget build(BuildContext context) {
    return AnimatedSidebar(
      expanded: MediaQuery.of(context).size.width > 600,
      items: items,
      selectedIndex: 0,
      onItemSelected: (index) => print(index),
      headerIcon: Icons.list,
      headerIconColor: Colors.amberAccent,
      headerText: 'Categories',
    );
  }
}
