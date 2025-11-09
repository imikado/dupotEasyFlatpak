import 'package:flutter/material.dart';

class ThemeTextStyle {
  BuildContext context;

  ThemeTextStyle({required this.context});

  Color getBadgetTextColor(bool isSelected) {
    if (Theme.of(context).brightness == Brightness.dark) {
      return Colors.white;
    }
    return Colors.black87;
  }

  Color getHeadlineTextColor(bool isSelected) {
    if (Theme.of(context).brightness == Brightness.dark) {
      return Colors.white;
    }
    return Colors.black87;
  }

  Color getHeadlineBackgroundColor(bool isSelected) {
    return isSelected
        ? Theme.of(context).secondaryHeaderColor
        : Colors.transparent;
  }
}
