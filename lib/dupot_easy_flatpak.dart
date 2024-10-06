import 'package:dupot_easy_flatpak/Layout/content_with_sidemenu.dart';
import 'package:dupot_easy_flatpak/Layout/content_with_sidemenu_and_back.dart';
import 'package:dupot_easy_flatpak/Layout/content_with_sidemenu_and_search.dart';
import 'package:dupot_easy_flatpak/Localizations/app_localizations_delegate.dart';
import 'package:dupot_easy_flatpak/Models/settings.dart';
import 'package:dupot_easy_flatpak/Process/commands.dart';
import 'package:dupot_easy_flatpak/Process/parameters.dart';
import 'package:dupot_easy_flatpak/Screens/loading.dart';
import 'package:dupot_easy_flatpak/Views/application_view.dart';
import 'package:dupot_easy_flatpak/Views/category_view.dart';
import 'package:dupot_easy_flatpak/Views/home_view.dart';
import 'package:dupot_easy_flatpak/Views/installation_view.dart';
import 'package:dupot_easy_flatpak/Views/installation_with_recipe_view.dart';
import 'package:dupot_easy_flatpak/Views/installedapps_view.dart';
import 'package:dupot_easy_flatpak/Views/search_view.dart';
import 'package:dupot_easy_flatpak/Views/uninstallation_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class DupotEasyFlatpak extends StatefulWidget {
  const DupotEasyFlatpak({super.key});

  @override
  _DupotEasyFlatpakState createState() => _DupotEasyFlatpakState();
}

class _DupotEasyFlatpakState extends State<DupotEasyFlatpak> {
  String stateCategoryIdSelected = '';
  String stateApplicationIdSelected = '';
  String statePageSelected = '';
  String stateSearch = '';
  String stateDefaultSearch = '';
  Locale stateLocale = const Locale.fromSubtags(languageCode: 'en');

  String statePreviousPageSelected = '';
  String statePreviousSearch = '';
  String statePreviousCategoryIdSelected = '';

  bool show404 = false;

  bool stateIsDarkMode = false;

  static const String constPageCategory = 'category';
  static const String constPageApplication = 'application';
  static const String constPageHome = 'home';
  static const String constPageSearch = 'search';
  static const String constPageInstallation = 'installation';
  static const String constPageInstallationWithRecipe =
      'installationWithRecipe';
  static const String constPageUninstallation = 'uninstallation';
  static const String constPageInstalledApps = 'installedApps';

  @override
  void initState() {
    super.initState();

    setState(() {
      stateLocale =
          Locale.fromSubtags(languageCode: Parameters().getLanguageCode());
      stateIsDarkMode = Parameters().getDarkModeEnabled();
    });
  }

  @override
  Widget build(BuildContext context) {
    Settings settingsObj = Settings(context: context);
    settingsObj.load().then((value) {
      Commands(settingsObj);
    });

    ColorScheme lightColorScheme =
        ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 54, 79, 148));

    ThemeData lightTheme = ThemeData(
      brightness: Brightness.light,
      colorScheme: lightColorScheme,
      primaryColorLight: lightColorScheme.primaryContainer,
      primaryColor: lightColorScheme.primary,
      secondaryHeaderColor: lightColorScheme.secondary,
      canvasColor: lightColorScheme.surface,
      textTheme: const TextTheme(
          titleLarge: TextStyle(color: Colors.white),
          headlineLarge: TextStyle(color: Colors.black)),
      cardTheme: CardTheme(color: lightColorScheme.secondary),
      cardColor: lightColorScheme.surfaceBright,
      scaffoldBackgroundColor: lightColorScheme.primaryContainer,
      useMaterial3: true,
    );

    Color darkColor1 = const Color.fromARGB(255, 1, 2, 17);
    Color darkColor2 = const Color.fromARGB(255, 6, 40, 54);
    Color darkColor3 = const Color.fromARGB(255, 5, 6, 43);
    Color darkColor4 = const Color.fromARGB(255, 12, 51, 87);

    Color darkColorWhite = const Color.fromARGB(255, 255, 255, 255);

    const TextStyle darkTextWhite = TextStyle(color: Colors.white);

    ThemeData darkTheme = ThemeData(
      brightness: Brightness.light,
      primaryColorDark: darkColor1,
      primaryColorLight: darkColor4,
      secondaryHeaderColor: darkColor1,
      canvasColor: darkColor1,
      textTheme: const TextTheme(
        titleLarge: darkTextWhite,
        titleMedium: darkTextWhite,
        titleSmall: darkTextWhite,
        headlineLarge: darkTextWhite,
        headlineMedium: darkTextWhite,
        headlineSmall: darkTextWhite,
        labelLarge: darkTextWhite,
        labelMedium: darkTextWhite,
        labelSmall: darkTextWhite,
        bodyLarge: darkTextWhite,
        bodyMedium: darkTextWhite,
        bodySmall: darkTextWhite,
        displayLarge: darkTextWhite,
        displayMedium: darkTextWhite,
        displaySmall: darkTextWhite,
      ),
      textSelectionTheme: TextSelectionThemeData(
          selectionColor: darkColor3, cursorColor: darkColorWhite),
      cardColor: darkColor1,
      scaffoldBackgroundColor: darkColor2,
      useMaterial3: true,
    );

    return MaterialApp(
      locale: stateLocale,
      theme: stateIsDarkMode ? darkTheme : lightTheme,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'EN'),
        Locale('fr', 'FR'),
        Locale('it', 'IT'),
      ],
      home: Navigator(
        pages: [
          if (statePageSelected == '')
            MaterialPage(
              key: const ValueKey('loading'),
              child: Loading(handle: _handleGoToHome),
            )
          else if (statePageSelected == constPageHome)
            MaterialPage(
                key: const ValueKey(constPageHome),
                child: ContentWithSidemenu(
                  content: HomeView(
                    handleGoToApplication: _handleGoToApplication,
                    handleGoToCategory: _handleGoToCategory,
                  ),
                  handleGoToHome: _handleGoToHome,
                  handleGoToCategory: _handleGoToCategory,
                  handleGoToSearch: _handleGoToSearch,
                  handleToggleDarkMode: _handleToggleDarkMode,
                  handleGoToInstalledApps: _handleGoToInstalledApps,
                  handleSetLocale: _handleSetLocale,
                  pageSelected: statePageSelected,
                  categoryIdSelected: stateCategoryIdSelected,
                ))
          else if (statePageSelected == constPageCategory &&
              stateCategoryIdSelected != '')
            MaterialPage(
                key: const ValueKey(constPageCategory),
                child: ContentWithSidemenu(
                  content: CategoryView(
                    categoryIdSelected: stateCategoryIdSelected,
                    handleGoToApplication: _handleGoToApplication,
                  ),
                  handleGoToHome: _handleGoToHome,
                  handleGoToCategory: _handleGoToCategory,
                  handleGoToSearch: _handleGoToSearch,
                  handleToggleDarkMode: _handleToggleDarkMode,
                  handleGoToInstalledApps: _handleGoToInstalledApps,
                  handleSetLocale: _handleSetLocale,
                  pageSelected: statePageSelected,
                  categoryIdSelected: stateCategoryIdSelected,
                ))
          else if (statePageSelected == constPageSearch)
            MaterialPage(
                key: const ValueKey(constPageSearch),
                child: ContentWithSidemenuAndSearch(
                  content: SearchView(
                      categoryIdSelected: stateCategoryIdSelected,
                      handleGoToApplication: _handleGoToApplication,
                      searched: stateSearch),
                  handleGoToHome: _handleGoToHome,
                  handleGoToCategory: _handleGoToCategory,
                  handleGoToSearch: _handleGoToSearch,
                  handleGoToInstalledApps: _handleGoToInstalledApps,
                  handleSetLocale: _handleSetLocale,
                  handleSearch: _handleSearch,
                  pageSelected: statePageSelected,
                  defaultSearch: stateDefaultSearch,
                  categoryIdSelected: stateCategoryIdSelected,
                ))
          else if (statePageSelected == constPageApplication &&
              stateApplicationIdSelected != '')
            MaterialPage(
                key: const ValueKey(constPageApplication),
                child: ContentWithSidemenuAndBack(
                  content: ApplicationView(
                      applicationIdSelected: stateApplicationIdSelected,
                      handleGoToInstallation: _handleGoToInstallation,
                      handleGoToInstallationWithRecipe:
                          _handleGoToInstallationWithRecipe,
                      handleGoToUninstallation: _handleGoToUninstallation),
                  handleGoToHome: _handleGoToHome,
                  handleGoToCategory: _handleGoToCategory,
                  handleGoToSearch: _handleGoToSearch,
                  handleToggleDarkMode: _handleToggleDarkMode,
                  handleGoToInstalledApps: _handleGoToInstalledApps,
                  handleSetLocale: _handleSetLocale,
                  pageSelected: statePageSelected,
                  categoryIdSelected: stateCategoryIdSelected,
                  handleGoBack: _handleGoBack,
                ))
          else if (statePageSelected == constPageInstallation &&
              stateApplicationIdSelected != '')
            MaterialPage(
                key: const ValueKey(constPageApplication),
                child: ContentWithSidemenu(
                  content: InstallationView(
                    applicationIdSelected: stateApplicationIdSelected,
                    handleGoToApplication: _handleGoToApplication,
                  ),
                  handleGoToHome: _handleGoToHome,
                  handleGoToCategory: _handleGoToCategory,
                  handleGoToSearch: _handleGoToSearch,
                  handleToggleDarkMode: _handleToggleDarkMode,
                  handleGoToInstalledApps: _handleGoToInstalledApps,
                  handleSetLocale: _handleSetLocale,
                  pageSelected: statePageSelected,
                  categoryIdSelected: stateCategoryIdSelected,
                ))
          else if (statePageSelected == constPageUninstallation &&
              stateApplicationIdSelected != '')
            MaterialPage(
                key: const ValueKey(constPageApplication),
                child: ContentWithSidemenu(
                  content: UninstallationView(
                    applicationIdSelected: stateApplicationIdSelected,
                    handleGoToApplication: _handleGoToApplication,
                  ),
                  handleGoToHome: _handleGoToHome,
                  handleGoToCategory: _handleGoToCategory,
                  handleGoToSearch: _handleGoToSearch,
                  handleToggleDarkMode: _handleToggleDarkMode,
                  handleGoToInstalledApps: _handleGoToInstalledApps,
                  handleSetLocale: _handleSetLocale,
                  pageSelected: statePageSelected,
                  categoryIdSelected: stateCategoryIdSelected,
                ))
          else if (statePageSelected == constPageInstallationWithRecipe &&
              stateApplicationIdSelected != '')
            MaterialPage(
                key: const ValueKey(constPageApplication),
                child: ContentWithSidemenu(
                  content: InstallationWithRecipeView(
                    applicationIdSelected: stateApplicationIdSelected,
                    handleGoToApplication: _handleGoToApplication,
                  ),
                  handleGoToHome: _handleGoToHome,
                  handleGoToCategory: _handleGoToCategory,
                  handleGoToSearch: _handleGoToSearch,
                  handleToggleDarkMode: _handleToggleDarkMode,
                  handleGoToInstalledApps: _handleGoToInstalledApps,
                  handleSetLocale: _handleSetLocale,
                  pageSelected: statePageSelected,
                  categoryIdSelected: stateCategoryIdSelected,
                ))
          else if (statePageSelected == constPageInstalledApps)
            MaterialPage(
                key: const ValueKey(constPageApplication),
                child: ContentWithSidemenu(
                  content: InstalledAppsView(
                    handleGoToApplication: _handleGoToApplication,
                  ),
                  handleGoToHome: _handleGoToHome,
                  handleGoToCategory: _handleGoToCategory,
                  handleGoToSearch: _handleGoToSearch,
                  handleToggleDarkMode: _handleToggleDarkMode,
                  handleGoToInstalledApps: _handleGoToInstalledApps,
                  handleSetLocale: _handleSetLocale,
                  pageSelected: statePageSelected,
                  categoryIdSelected: stateCategoryIdSelected,
                ))
        ],
        onPopPage: (route, result) => route.didPop(result),
      ),
    );
  }

  void _handleToggleDarkMode() {
    if (stateIsDarkMode) {
      Parameters().setDarModeEnabled(false);
      setState(() {
        stateIsDarkMode = false;
      });
    } else {
      Parameters().setDarModeEnabled(true);
      setState(() {
        stateIsDarkMode = true;
      });
    }
  }

  void _handleGoToCategory(String categoryId) {
    setState(() {
      stateCategoryIdSelected = categoryId;
      statePageSelected = constPageCategory;
    });
  }

  void _handleGoToApplication(String applicationId) {
    setState(() {
      statePreviousPageSelected = statePageSelected;
      statePreviousCategoryIdSelected = stateCategoryIdSelected;
      statePreviousSearch = stateSearch;

      stateApplicationIdSelected = applicationId;
      statePageSelected = constPageApplication;
    });
  }

  void _handleGoToHome() {
    setState(() {
      statePageSelected = constPageHome;
      stateCategoryIdSelected = '';
    });
  }

  void _handleGoToSearch(String newSearch) {
    setState(() {
      stateDefaultSearch = newSearch;
      stateSearch = "";
      statePageSelected = constPageSearch;
      stateCategoryIdSelected = '';
    });
  }

  void _handleGoToInstalledApps() {
    setState(() {
      statePageSelected = constPageInstalledApps;
      stateCategoryIdSelected = '';
      stateApplicationIdSelected = '';
    });
  }

  void _handleSearch(String newSearch) {
    setState(() {
      stateSearch = newSearch;
    });
  }

  void _handleGoToInstallation(String applicationId) {
    setState(() {
      statePageSelected = constPageInstallation;
      stateApplicationIdSelected = applicationId;
    });
  }

  void _handleGoToInstallationWithRecipe(String applicationId) {
    setState(() {
      statePageSelected = constPageInstallationWithRecipe;
      stateApplicationIdSelected = applicationId;
    });
  }

  void _handleGoToUninstallation(String applicationId) {
    setState(() {
      statePageSelected = constPageUninstallation;
      stateApplicationIdSelected = applicationId;
    });
  }

  void _handleSetLocale(String locale) {
    Parameters().setLanguageCode(locale);
    setState(() {
      stateLocale = Locale.fromSubtags(languageCode: locale);
    });
  }

  void _handleGoBack() {
    if (statePreviousPageSelected == constPageCategory) {
      _handleGoToCategory(statePreviousCategoryIdSelected);
    } else if (statePreviousPageSelected == constPageSearch) {
      _handleGoToSearch('');
      setState(() {
        stateSearch = statePreviousSearch;
      });
    } else if (statePreviousPageSelected == constPageInstalledApps) {
      _handleGoToInstalledApps();
    } else if (statePreviousPageSelected == constPageHome) {
      _handleGoToHome();
    } else {
      print('Error: got back not expected');
    }
  }
}
