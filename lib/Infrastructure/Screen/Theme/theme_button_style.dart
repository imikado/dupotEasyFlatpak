import 'package:flutter/material.dart';

class ThemeButtonStyle {
  static const tagColorAccept = 'accept';
  static const tagColorDeny = 'deny';
  static const tagColorDefault = 'default';

  Color colorAccept = Color.fromARGB(255, 20, 107, 7);
  Color colorDeny = Color.fromARGB(255, 129, 21, 7);

  Color darkColorAccept = Color.fromARGB(255, 18, 107, 4);
  Color darkColorDeny = Color.fromARGB(255, 131, 21, 6);

  BuildContext context;

  ThemeButtonStyle({required this.context});

  TextStyle getButtonTextStyle() {
    if (Theme.of(context).brightness == Brightness.dark) {
      return const TextStyle(fontSize: 14, color: Colors.white);
    }

    return const TextStyle(fontSize: 14, color: Colors.white);
  }

  ButtonStyle getSegmentedButtonStyle() {
    return SegmentedButton.styleFrom(
      padding: const EdgeInsets.all(14),
      elevation: 0,
      side: BorderSide(color: Theme.of(context).focusColor, width: 1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      //backgroundColor: Theme.of(context).secondaryHeaderColor,
      //foregroundColor: Theme.of(context).primaryColor,
      iconColor: Theme.of(context).primaryColorDark,
      selectedForegroundColor: Theme.of(context).primaryColor,
      selectedBackgroundColor: Theme.of(context).focusColor,
    );
  }

  ButtonStyle getButtonStyle({String tagColor = tagColorDefault}) {
    return ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(16),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        textStyle: getButtonTextStyle());
  }

  Color getAcceptColorOr(String tagColor, Color defaultColor) {
    if (tagColor == tagColorDefault) {
      return defaultColor;
    } else if (tagColor == tagColorAccept) {
      return colorAccept;
    } else if (tagColor == tagColorDeny) {
      return colorDeny;
    }
    throw Exception('unexpected tagColor');
  }

  Color getDarkAcceptColorOr(String tagColor, Color defaultColor) {
    if (tagColor == tagColorDefault) {
      return defaultColor;
    } else if (tagColor == tagColorAccept) {
      return darkColorAccept;
    } else if (tagColor == tagColorDeny) {
      return darkColorDeny;
    }
    throw Exception('unexpected tagColor');
  }

  ButtonStyle getDialogButtonStyle() {
    return FilledButton.styleFrom(
        padding: const EdgeInsets.all(20),
        textStyle: const TextStyle(fontSize: 14));
  }
}
