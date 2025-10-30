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
    if (Theme.of(context).brightness == Brightness.dark) {
      return SegmentedButton.styleFrom(
        padding: const EdgeInsets.all(14),
        elevation: 0,
        side: const BorderSide(color: Colors.transparent, width: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        backgroundColor: Theme.of(context).secondaryHeaderColor,
        selectedForegroundColor: Colors.white, // Selected text color
        selectedBackgroundColor: Theme.of(context).canvasColor,
      );
    }

    return SegmentedButton.styleFrom(
      padding: const EdgeInsets.all(14),
      elevation: 0,
      side: const BorderSide(color: Colors.transparent, width: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      backgroundColor: Theme.of(context).secondaryHeaderColor,
      foregroundColor: Theme.of(context).primaryColor,
      selectedForegroundColor: Colors.white,
      selectedBackgroundColor: Theme.of(context).primaryColorDark,
    );
  }

  ButtonStyle getButtonStyle({String tagColor = tagColorDefault}) {
    if (Theme.of(context).brightness == Brightness.dark) {
      return ElevatedButton.styleFrom(
          backgroundColor: getDarkAcceptColorOr(
              tagColor, Theme.of(context).secondaryHeaderColor),
          padding: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          textStyle: getButtonTextStyle());
    }

    return ElevatedButton.styleFrom(
        backgroundColor:
            getAcceptColorOr(tagColor, Theme.of(context).primaryColorDark),
        padding: const EdgeInsets.all(16),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        textStyle: const TextStyle(fontSize: 14, color: Colors.white));
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
    if (Theme.of(context).brightness == Brightness.dark) {
      return FilledButton.styleFrom(
          backgroundColor: Theme.of(context).cardColor,
          padding: const EdgeInsets.all(20),
          textStyle: const TextStyle(fontSize: 14, color: Colors.black));
    }
    return FilledButton.styleFrom(
        backgroundColor: Theme.of(context).primaryColor,
        padding: const EdgeInsets.all(20),
        textStyle: const TextStyle(fontSize: 14));
  }
}
