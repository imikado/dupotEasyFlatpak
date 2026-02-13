import 'package:dupot_easy_flatpak/Theme/adwaita_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;

// Ported from package:adwaita (unmaintained) for Flutter 3.38+ compatibility.
// Fixes: TabBarTheme→TabBarThemeData, DialogTheme→DialogThemeData,
//        BottomAppBarTheme→BottomAppBarThemeData, MaterialState→WidgetState

class AdwaitaThemeData {
  const AdwaitaThemeData._();

  static final _lightColorScheme = ColorScheme.fromSwatch(
    primarySwatch: AdwaitaColors.primarySwatchColor,
    accentColor: AdwaitaColors.blueAccent,
    cardColor: AdwaitaColors.cardBackground,
    backgroundColor: AdwaitaColors.backgroundColor,
    errorColor: AdwaitaColors.red5,
  );

  static final _darkColorScheme = ColorScheme.fromSwatch(
    primarySwatch: AdwaitaColors.primarySwatchColor,
    accentColor: AdwaitaColors.blueAccent,
    cardColor: AdwaitaColors.darkCardBackground,
    backgroundColor: AdwaitaColors.darkBackgroundColor,
    errorColor: AdwaitaColors.red5,
    brightness: Brightness.dark,
  );

  static ShapeBorder getDialogShape([Color color = Colors.white]) =>
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      );

  static TextTheme getTextTheme([Brightness brightness = Brightness.light]) {
    final color = brightness == Brightness.light ? Colors.black : Colors.white;
    return TextTheme(
      displayLarge: TextStyle(
          fontSize: 26, color: color, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(
          fontSize: 21, color: color, fontWeight: FontWeight.bold),
      displaySmall: TextStyle(
          fontSize: 20, color: color, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(
          fontSize: 17, color: color, fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(
          fontSize: 15, color: color, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(
          fontSize: 13, color: color, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontSize: 15, color: color),
      bodySmall: TextStyle(
          fontSize: 13, color: color, fontWeight: FontWeight.w400),
    );
  }

  static ThemeData light({String? fontFamily}) => ThemeData(
        fontFamily: fontFamily,
        tabBarTheme: TabBarThemeData(labelColor: _lightColorScheme.onSurface),
        brightness: Brightness.light,
        splashFactory: NoSplash.splashFactory,
        primaryColor: _lightColorScheme.primary,
        canvasColor: _lightColorScheme.surface,
        scaffoldBackgroundColor: _lightColorScheme.surface,
        cardColor: _lightColorScheme.surface,
        dividerTheme: DividerThemeData(
          color: _lightColorScheme.onSurface.withValues(alpha: 0.12),
        ),
        dialogBackgroundColor: _lightColorScheme.surface,
        dialogTheme: DialogThemeData(
          backgroundColor: _lightColorScheme.surface,
          shape: getDialogShape(Colors.black),
        ),
        textTheme: getTextTheme(),
        indicatorColor: _lightColorScheme.secondary,
        applyElevationOverlayColor: false,
        buttonTheme: _buttonThemeData,
        elevatedButtonTheme: _getElevatedButtonThemeData(Brightness.light),
        outlinedButtonTheme: _outlinedButtonThemeData,
        textButtonTheme: _textButtonThemeData,
        switchTheme: _switchStyleLight,
        checkboxTheme: _checkStyleLight,
        radioTheme: _radioStyleLight,
        appBarTheme: _appBarLightTheme,
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AdwaitaColors.blueAccent,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: _lightColorScheme.primary,
          unselectedItemColor: AdwaitaColors.dark3,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AdwaitaColors.button,
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            borderSide: BorderSide(color: Colors.transparent),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            borderSide: BorderSide(color: AdwaitaColors.blueAccent),
          ),
        ),
        bottomAppBarTheme:
            BottomAppBarThemeData(color: _lightColorScheme.surface),
        colorScheme: _lightColorScheme.copyWith(
          error: _lightColorScheme.error,
        ),
      );

  static ThemeData dark({String? fontFamily}) => ThemeData(
        fontFamily: fontFamily,
        tabBarTheme: TabBarThemeData(labelColor: _darkColorScheme.onSurface),
        brightness: Brightness.dark,
        splashFactory: NoSplash.splashFactory,
        primaryColor: _darkColorScheme.primary,
        canvasColor: _darkColorScheme.surface,
        scaffoldBackgroundColor: _darkColorScheme.surface,
        cardColor: _darkColorScheme.surface,
        dividerTheme: DividerThemeData(
          color: _darkColorScheme.onSurface.withValues(alpha: 0.12),
        ),
        dialogBackgroundColor: _darkColorScheme.surface,
        dialogTheme: DialogThemeData(
          backgroundColor: _darkColorScheme.surface,
          shape: getDialogShape(),
        ),
        textTheme: getTextTheme(Brightness.dark),
        indicatorColor: _darkColorScheme.secondary,
        applyElevationOverlayColor: true,
        buttonTheme: _buttonThemeData,
        textButtonTheme: _darkTextButtonThemeData,
        elevatedButtonTheme: _getElevatedButtonThemeData(Brightness.dark),
        outlinedButtonTheme: _darkOutlinedButtonThemeData,
        switchTheme: _switchStyleDark,
        checkboxTheme: _checkStyleDark,
        radioTheme: _radioStyleDark,
        primaryColorDark: AdwaitaColors.blueAccent,
        appBarTheme: _appBarDarkTheme,
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AdwaitaColors.blueAccent,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: _darkColorScheme.primary,
          unselectedItemColor: AdwaitaColors.warmGrey.shade300,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AdwaitaColors.darkButton,
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            borderSide: BorderSide(color: Colors.transparent),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            borderSide: BorderSide(color: AdwaitaColors.blueAccent),
          ),
        ),
        bottomAppBarTheme:
            BottomAppBarThemeData(color: _darkColorScheme.surface),
        colorScheme: _darkColorScheme.copyWith(
          error: _darkColorScheme.error,
        ),
      );

  static final _commonButtonStyle = ButtonStyle(
    visualDensity: VisualDensity.standard,
    backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
      if (states.contains(WidgetState.pressed)) {
        return AdwaitaColors.light4;
      }
      return AdwaitaColors.light2;
    }),
  );

  static final _darkCommonButtonStyle = ButtonStyle(
    visualDensity: VisualDensity.standard,
    backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
      if (states.contains(WidgetState.pressed)) {
        return AdwaitaColors.dark5;
      }
      return AdwaitaColors.dark2;
    }),
  );

  static final _buttonThemeData = ButtonThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
  );

  static final _outlinedButtonThemeData = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AdwaitaColors.dark4,
      visualDensity: _commonButtonStyle.visualDensity,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(5)),
      ),
    ),
  );

  static final _darkOutlinedButtonThemeData = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      visualDensity: _commonButtonStyle.visualDensity,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.75)),
      ),
    ),
  );

  static final _textButtonThemeData = TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AdwaitaColors.dark4,
      visualDensity: _commonButtonStyle.visualDensity,
      backgroundColor: AdwaitaColors.button,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        side: BorderSide(color: Colors.transparent),
      ),
    ),
  );

  static final _darkTextButtonThemeData = TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: Colors.white,
      visualDensity: _darkCommonButtonStyle.visualDensity,
      backgroundColor: AdwaitaColors.darkButton,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        side: BorderSide(color: Colors.transparent),
      ),
    ),
  );

  static ElevatedButtonThemeData _getElevatedButtonThemeData(
    Brightness brightness,
  ) {
    if (brightness == Brightness.light) {
      return ElevatedButtonThemeData(style: _commonButtonStyle);
    }
    return ElevatedButtonThemeData(style: _darkCommonButtonStyle);
  }

  static Color _getSwitchThumbColorDark(Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) {
      return AdwaitaColors.dark2;
    } else if (states.contains(WidgetState.selected)) {
      return AdwaitaColors.blueAccent;
    }
    return AdwaitaColors.warmGrey;
  }

  static Color _getSwitchTrackColorDark(Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) {
      return AdwaitaColors.dark2.withAlpha(120);
    } else if (states.contains(WidgetState.selected)) {
      return AdwaitaColors.blueAccent.withAlpha(160);
    }
    return AdwaitaColors.warmGrey.withAlpha(80);
  }

  static final _switchStyleDark = SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith(_getSwitchThumbColorDark),
    trackColor: WidgetStateProperty.resolveWith(_getSwitchTrackColorDark),
  );

  static Color _getSwitchThumbColorLight(Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) {
      return AdwaitaColors.warmGrey.shade200;
    } else if (states.contains(WidgetState.selected)) {
      return AdwaitaColors.blueAccent;
    }
    return Colors.white;
  }

  static Color _getSwitchTrackColorLight(Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) {
      return AdwaitaColors.warmGrey.shade200;
    } else if (states.contains(WidgetState.selected)) {
      return AdwaitaColors.blueAccent.withAlpha(180);
    }
    return AdwaitaColors.warmGrey.shade300;
  }

  static final _switchStyleLight = SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith(_getSwitchThumbColorLight),
    trackColor: WidgetStateProperty.resolveWith(_getSwitchTrackColorLight),
  );

  static Color _getCheckFillColorDark(Set<WidgetState> states) {
    if (!states.contains(WidgetState.disabled)) {
      if (states.contains(WidgetState.selected)) {
        return AdwaitaColors.blueAccent;
      }
      return AdwaitaColors.warmGrey.shade400;
    }
    return AdwaitaColors.warmGrey.withValues(alpha: 0.4);
  }

  static Color _getCheckColorDark(Set<WidgetState> states) {
    if (!states.contains(WidgetState.disabled)) {
      return Colors.white;
    }
    return AdwaitaColors.warmGrey;
  }

  static final _checkStyleDark = CheckboxThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
    fillColor: WidgetStateProperty.resolveWith(_getCheckFillColorDark),
    checkColor: WidgetStateProperty.resolveWith(_getCheckColorDark),
  );

  static Color _getCheckFillColorLight(Set<WidgetState> states) {
    if (!states.contains(WidgetState.disabled)) {
      if (states.contains(WidgetState.selected)) {
        return AdwaitaColors.blueAccent;
      }
      return AdwaitaColors.warmGrey;
    }
    return AdwaitaColors.warmGrey.shade300;
  }

  static Color _getCheckColorLight(Set<WidgetState> states) {
    if (!states.contains(WidgetState.disabled)) {
      return Colors.white;
    }
    return AdwaitaColors.warmGrey;
  }

  static final _checkStyleLight = CheckboxThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
    fillColor: WidgetStateProperty.resolveWith(_getCheckFillColorLight),
    checkColor: WidgetStateProperty.resolveWith(_getCheckColorLight),
  );

  static final _radioStyleDark = RadioThemeData(
    fillColor: WidgetStateProperty.resolveWith(_getCheckFillColorDark),
  );

  static final _radioStyleLight = RadioThemeData(
    fillColor: WidgetStateProperty.resolveWith(_getCheckFillColorLight),
  );

  static final _appBarLightTheme = AppBarTheme(
    elevation: 1,
    titleTextStyle: getTextTheme().headlineSmall,
    systemOverlayStyle: SystemUiOverlayStyle.light,
    backgroundColor: AdwaitaColors.headerBarBackground,
    foregroundColor: AdwaitaColors.headerBarForeground,
    iconTheme: const IconThemeData(color: AdwaitaColors.dark3),
    actionsIconTheme: const IconThemeData(color: AdwaitaColors.dark3),
  );

  static final _appBarDarkTheme = AppBarTheme(
    elevation: 1,
    titleTextStyle: getTextTheme(Brightness.dark).headlineSmall,
    systemOverlayStyle: SystemUiOverlayStyle.dark,
    backgroundColor: AdwaitaColors.darkHeaderBarBackground,
    foregroundColor: AdwaitaColors.darkHeaderBarForeground,
  );
}
