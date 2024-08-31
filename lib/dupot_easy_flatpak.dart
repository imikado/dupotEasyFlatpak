import 'package:dupot_easy_flatpak/Layout/content_with_sidemenu.dart';
import 'package:dupot_easy_flatpak/Localizations/app_localizations_delegate.dart';
import 'package:dupot_easy_flatpak/Screens/loading.dart';
import 'package:dupot_easy_flatpak/Views/category_view.dart';
import 'package:dupot_easy_flatpak/Views/home_view.dart';
import 'package:dupot_easy_flatpak/Views/search_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class DupotEasyFlatpak extends StatefulWidget {
  const DupotEasyFlatpak({super.key});

  @override
  _DupotEasyFlatpakState createState() => _DupotEasyFlatpakState();
}

class _DupotEasyFlatpakState extends State<DupotEasyFlatpak> {
  String stateCategoryIdSelected = '';
  String? stateApplicationIdSelected;
  String statePageSelected = '';
  bool show404 = false;

  static const String constPageCategory = 'category';
  static const String constPageApplication = 'application';
  static const String constPageHome = 'home';
  static const String constPageSearch = 'search';

  static const String constPageInstallation = 'installation';
  static const String constPageInstallationWithRecipe =
      'installationWithRecipe';
  static const String constPageUninstallation = 'uninstallation';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 205, 230, 250)),
        useMaterial3: false,
      ),
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('fr', ''),
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
                  content: const HomeView(),
                  handleGoToHome: _handleGoToHome,
                  handleGoToCategory: _handleGoToCategory,
                  handleGoToSearch: _handleGoToSearch,
                  pageSelected: statePageSelected,
                  categoryIdSelected: stateCategoryIdSelected,
                ))
          else if (statePageSelected == constPageCategory)
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
                  pageSelected: statePageSelected,
                  categoryIdSelected: stateCategoryIdSelected,
                ))
          else if (statePageSelected == constPageSearch)
            MaterialPage(
                key: const ValueKey(constPageSearch),
                child: ContentWithSidemenu(
                  content: SearchView(
                    categoryIdSelected: stateCategoryIdSelected,
                    handleGoToApplication: _handleGoToApplication,
                  ),
                  handleGoToHome: _handleGoToHome,
                  handleGoToCategory: _handleGoToCategory,
                  handleGoToSearch: _handleGoToSearch,
                  pageSelected: statePageSelected,
                  categoryIdSelected: stateCategoryIdSelected,
                ))
        ],
        onPopPage: (route, result) => route.didPop(result),
      ),
    );
  }

  void _handleGoToCategory(String categoryId) {
    setState(() {
      stateCategoryIdSelected = categoryId;
      statePageSelected = constPageCategory;
    });
  }

  void _handleGoToApplication(String applicationId) {
    setState(() {
      stateApplicationIdSelected = applicationId;
      statePageSelected = constPageApplication;
    });
  }

  void _handleGoToHome() {
    setState(() {
      statePageSelected = constPageHome;
    });
  }

  void _handleGoToSearch() {
    setState(() {
      statePageSelected = constPageSearch;
    });
  }
}
