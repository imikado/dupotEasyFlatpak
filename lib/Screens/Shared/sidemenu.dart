import 'package:dupot_easy_flatpak/Localizations/app_localizations.dart';
import 'package:dupot_easy_flatpak/Screens/Shared/menu_item.dart';
import 'package:flutter/material.dart';

class SideMenu extends StatelessWidget {
  const SideMenu(
      {super.key,
      required this.menuItemList,
      required this.pageSelected,
      required this.categoryIdSelected});

  final List<MenuItem> menuItemList;
  final String pageSelected;
  final String categoryIdSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(5),
        child: Card(
            color: Theme.of(context).primaryColorLight,
            margin: const EdgeInsets.all(0),
            elevation: 5,
            child: ListView(
              children: menuItemList.map((menuItemLoop) {
                bool isSelected = false;
                if (menuItemLoop.pageSelected == pageSelected &&
                    menuItemLoop.categoryIdSelected == categoryIdSelected) {
                  isSelected = true;
                }

                return ListTile(
                    tileColor:
                        isSelected ? Theme.of(context).primaryColorDark : null,

                    // selected: menuItemLoop.label == selected,
                    onTap: () {
                      menuItemLoop.action();
                    },
                    title: Text(
                      AppLocalizations().tr(menuItemLoop.label),
                      style: isSelected
                          ? TextStyle(
                              backgroundColor: Theme.of(context)
                                  .textSelectionTheme
                                  .selectionHandleColor)
                          : null,
                    ));
              }).toList(),
            )));
  }
}
