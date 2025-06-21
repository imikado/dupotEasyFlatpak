import 'package:flutter/material.dart';

class ThemeButtonStyle {
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

  ButtonStyle getButtonStyle() {
    if (Theme.of(context).brightness == Brightness.dark) {
      return ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).canvasColor,
          padding: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          textStyle: getButtonTextStyle());
    }

    return ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).primaryColorDark,
        padding: const EdgeInsets.all(16),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        textStyle: const TextStyle(fontSize: 14, color: Colors.white));
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
