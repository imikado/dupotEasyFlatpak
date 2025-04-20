import 'package:dupot_easy_flatpak/Domain/Entity/user_settings_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/command_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Entity/navigation_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Entity/override_form_control.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/Layout/only_content_layout.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/Layout/side_menu_with_content_and_subcontent.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SubView/cart_install_all_subview.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SubView/cart_override_subview.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SubView/export_subview.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SubView/import_subview.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SubView/install_subview.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SubView/install_with_recipe_subview.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SubView/override_subview.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SubView/uninstall_subview.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SubView/update_available_processing_all_subview.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SubView/update_available_processing_subview.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/View/about_view.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/View/application_view.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/View/cart_view.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/View/category_view.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/View/home_view.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/View/installed_applications_view.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/View/loading_view.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/View/moreactions_view.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/View/search_view.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/View/side_menu_view.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/View/updates_availables_view.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/View/user_settings_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:logging/logging.dart';

class Application extends StatefulWidget {
  const Application({super.key});

  @override
  ApplicationState createState() => ApplicationState();
}

class ApplicationState extends State<Application> {
  static final _logger = Logger('ApplicationState');

  String statePage = NavigationEntity.pageLoading;
  Map<String, String> stateArgumentMap = {};
  String stateSearched = '';

  String statePreviousPage = NavigationEntity.pageHome;
  Map<String, String> statePreviousPArgumentMap = {};

  int stateInterfaceVersion = 0;

  List<String> stateCartApplicationIdList = [];
  Map<String, List<OverrideFormControl>>
      stateCartOverrideFormControlListByApplicationId = {};

  String stateApplicationIdLighted = '';

  String version = '';

  bool stateHasPrevious = false;

  final FocusNode _focusNode = FocusNode();

  final alphanumeric = RegExp(r'^[a-zA-Z0-9]{1}$');

  @override
  void initState() {
    processInit();

    super.initState();
  }

  void processInit() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    version = packageInfo.version;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData themData = ThemeData(
      useMaterial3: true,
      primaryColorLight: const Color.fromARGB(221, 59, 59, 59),
      brightness: Brightness.dark,
    );

    bool hasSubContent = false;
    bool isMain = true;
    if (stateArgumentMap.containsKey(NavigationEntity.argumentSubPage)) {
      hasSubContent = true;
      isMain = false;
    }

    return KeyboardListener(
        focusNode: _focusNode,
        autofocus: false,
        onKeyEvent: (event) {
          if (getSubPage() == '' &&
              event is KeyDownEvent &&
              event.logicalKey.keyLabel.toString().length == 1 &&
              alphanumeric.hasMatch(event.logicalKey.keyLabel.toString())) {
            NavigationEntity.goToSearch(
                handleGoTo: goTo,
                search: stateSearched +
                    event.logicalKey.keyLabel.toString().toLowerCase());
          } else if (getSubPage() == '' &&
              event is KeyDownEvent &&
              stateSearched.isNotEmpty &&
              event.logicalKey.keyLabel == "Backspace") {
            NavigationEntity.goToSearch(
                handleGoTo: goTo,
                search: stateSearched.substring(0, stateSearched.length - 1));
          }
        },
        child: MaterialApp(
            theme: UserSettingsEntity().getActiveDarkModeEnabled()
                ? themData
                : ThemeData.light(),
            home: Navigator(
              pages: [
                if (statePage == NavigationEntity.pageLoading)
                  MaterialPage(
                      key: const ValueKey(NavigationEntity.pageLoading),
                      child: OnlyContentLayout(
                          handleGoTo: goTo,
                          content: LoadingView(handle: () {
                            goToPrevious();
                          })))
                else
                  MaterialPage(
                      key: const ValueKey(NavigationEntity.pageHome),
                      child: SideMenuWithContentAndSubContentLayout(
                        menu: getSideMenuView(),
                        content: getContentView(statePage, isMain),
                        subContent: getSubContentView(hasSubContent),
                        hasSubContent: hasSubContent,
                        hasPrevious: stateHasPrevious,
                        handleGoToPrevious: goToPrevious,
                        pageSelected: statePage,
                      ))
              ],
              onDidRemovePage: (page) => true,
            )));
  }

  String getSubPage() {
    if (stateArgumentMap.containsKey(NavigationEntity.argumentSubPage)) {
      return NavigationEntity.extractArgumentSubPage(stateArgumentMap);
    }
    return '';
  }

  Widget getSideMenuView() {
    return SideMenuView(
      interfaceVersion: stateInterfaceVersion,
      pageSelected: statePage,
      argumentMapSelected: stateArgumentMap,
      handleGoTo: goTo,
      applicationIdListInCart: stateCartApplicationIdList,
      searched: stateSearched,
      numberOfUpdates: CommandApi().getNumberOfUpdates(),
    );
  }

  Widget getContentView(String pageToLoad, bool isMain) {
    if (pageToLoad == NavigationEntity.pageHome) {
      return HomeView(handleGoTo: goTo);
    } else if (pageToLoad == NavigationEntity.pageCategory) {
      String newCategoryId =
          NavigationEntity.extractArgumentCategoryId(stateArgumentMap);

      return CategoryView(
        handleGoTo: goTo,
        categoryIdSelected: newCategoryId,
      );
    } else if (pageToLoad == NavigationEntity.pageApplication) {
      String newAppId =
          NavigationEntity.extractArgumentApplicationId(stateArgumentMap);

      return ApplicationView(
        handleGoTo: goTo,
        handleGoToPrevious: goToPrevious,
        handleAddToCart: addToCart,
        handleRemoveFromCart: removeFromCart,
        handleReload: reload,
        applicationIdListInCart: stateCartApplicationIdList,
        applicationIdSelected: newAppId,
        isMain: (!isMain ||
                stateArgumentMap.containsKey(NavigationEntity.argumentSubPage))
            ? false
            : true,
      );
    } else if (pageToLoad == NavigationEntity.pageInstalledApplication) {
      return InstalledApplicationsView(
        handleGoTo: goTo,
      );
    } else if (pageToLoad == NavigationEntity.pageSearch) {
      return SearchView(
        searched: stateSearched,
        handleGoTo: goTo,
      );
    } else if (pageToLoad == NavigationEntity.pageUpdateAvailables) {
      return UpdatesAvailablesView(
        handleGoTo: goTo,
        isMain: isMain,
      );
    } else if (pageToLoad == NavigationEntity.pageUserSettings) {
      return UserSettingsView(
          handleGoTo: goTo,
          handleReload: reload,
          handleReloadLanguage: reloadLanguage);
    } else if (pageToLoad == NavigationEntity.pageMore) {
      return MoreActionsView(
        handleGoTo: goTo,
      );
    } else if (pageToLoad == NavigationEntity.pageAbout) {
      return AboutView(
        version: version,
      );
    } else if (pageToLoad == NavigationEntity.pageCart) {
      String applicationId = '';

      if (stateArgumentMap
          .containsKey(NavigationEntity.argumentApplicationId)) {
        applicationId =
            NavigationEntity.extractArgumentApplicationId(stateArgumentMap);
      } else if (stateApplicationIdLighted.isNotEmpty) {
        applicationId = stateApplicationIdLighted;
      }

      return CartView(
          applicationIdListInCart: stateCartApplicationIdList,
          handleGoTo: goTo,
          handleRemoveFromCart: removeFromCart,
          overrideSetupListByApplicationId:
              stateCartOverrideFormControlListByApplicationId,
          isMain: isMain,
          applicationId: applicationId);
    }

    throw Exception('missing content view for statePage $statePage');
  }

  reloadLanguage() {}

  Widget getSubContentView(bool hasSubContent) {
    if (!hasSubContent) {
      return const SizedBox();
    }

    String subPageToLoad = stateArgumentMap[NavigationEntity.argumentSubPage]!;

    if (subPageToLoad == NavigationEntity.argumentSubPageInstall) {
      String applicationId =
          NavigationEntity.extractArgumentApplicationId(stateArgumentMap);

      removeFromCart(applicationId);

      return InstallSubview(
        applicationId: applicationId,
        handleGoToApplication: () => NavigationEntity.gotToApplicationId(
            handleGoTo: goTo, applicationId: applicationId),
        installScope:
            NavigationEntity.extractArgumentInstallScope(stateArgumentMap),
      );
    } else if (subPageToLoad ==
        NavigationEntity.argumentSubPageInstallWithRecipe) {
      String applicationId =
          NavigationEntity.extractArgumentApplicationId(stateArgumentMap);

      return InstallWithRecipeSubview(
        applicationId: applicationId,
        handleGoToApplication: () => NavigationEntity.gotToApplicationId(
            handleGoTo: goTo, applicationId: applicationId),
        installScope:
            NavigationEntity.extractArgumentInstallScope(stateArgumentMap),
      );
    } else if (subPageToLoad == NavigationEntity.argumentSubPageUninstall) {
      String applicationId =
          NavigationEntity.extractArgumentApplicationId(stateArgumentMap);

      bool willDeleteAppData = false;
      if (stateArgumentMap.containsKey('willDeleteAppData')) {
        willDeleteAppData = true;
      }

      return UninstallSubview(
          applicationId: applicationId,
          handleGoToApplication: () => NavigationEntity.gotToApplicationId(
              handleGoTo: goTo, applicationId: applicationId),
          willDeleteAppData: willDeleteAppData,
          installScope:
              NavigationEntity.extractArgumentInstallScope(stateArgumentMap));
    } else if (subPageToLoad == NavigationEntity.argumentSubPageOverride) {
      String applicationId =
          NavigationEntity.extractArgumentApplicationId(stateArgumentMap);
      return OverrideSubview(
          applicationId: applicationId,
          handleGoToApplication: () => NavigationEntity.gotToApplicationId(
              handleGoTo: goTo, applicationId: applicationId));
    } else if (subPageToLoad ==
        NavigationEntity.argumentSubPageUpdateAvailableProcessing) {
      List<String> applicationIdSelectedList =
          NavigationEntity.extractArgumentApplicationIdSelectedList(
              stateArgumentMap);
      return UpdateAvailableProcessingSubview(
          applicationIdSelectedList: applicationIdSelectedList,
          handleGoTo: goTo);
    } else if (subPageToLoad ==
        NavigationEntity.argumentSubPageUpdateAvailableProcessingAll) {
      return UpdateAvailableProcessingAllSubview(handleGoTo: goTo);
    } else if (subPageToLoad ==
        NavigationEntity.argumentSubPageCartSetupOverride) {
      String applicationId =
          NavigationEntity.extractArgumentApplicationId(stateArgumentMap);

      return CartOverrideSubview(
          applicationId: applicationId,
          handleSaveOverrideSetup: saveCartOverrideSetupForApplicationId,
          overrideSetupList:
              getCartOverrideSetupForApplicationId(applicationId),
          handleGoToCart: () {
            NavigationEntity.goToCart(handleGoTo: goTo);
          });
    } else if (subPageToLoad ==
        NavigationEntity.argumentSubPageCartInstallAll) {
      return CartInstallAllSubview(
          handleGoToApplicationInstalled: () {
            NavigationEntity.goToInstalledApplications(handleGoTo: goTo);
          },
          handleSetApplicationLighted: setApplicationIdLighted,
          applicationIdListInCart: stateCartApplicationIdList,
          handleRemoveFromCart: removeFromCart,
          overrideSetupListByApplicationId:
              stateCartOverrideFormControlListByApplicationId);
    } else if (subPageToLoad == NavigationEntity.argumentSubPageExport) {
      return ExportSubview(
        handleGoToMore: () {
          NavigationEntity.goToMore(handleGoTo: goTo);
        },
      );
    } else if (subPageToLoad == NavigationEntity.argumentSubPageImport) {
      return ImportSubview(
        handleGoToMore: () {
          NavigationEntity.goToMore(handleGoTo: goTo);
        },
        handleAddToCart: addToCart,
      );
    }
    throw Exception(
        'missing content sub view for subPageToLoad $subPageToLoad');
  }

  void setApplicationIdLighted(String applicationId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        stateApplicationIdLighted = applicationId;
      });
    });
  }

  List<OverrideFormControl> getCartOverrideSetupForApplicationId(
      String applicationId) {
    if (stateCartOverrideFormControlListByApplicationId
        .containsKey(applicationId)) {
      return stateCartOverrideFormControlListByApplicationId[applicationId]!;
    }
    return [];
  }

  void saveCartOverrideSetupForApplicationId(
      String applicationId, List<OverrideFormControl> overrideFormControlList) {
    Map<String, List<OverrideFormControl>>
        cartOverrideFormControlListByApplicationId =
        stateCartOverrideFormControlListByApplicationId;

    cartOverrideFormControlListByApplicationId[applicationId] =
        overrideFormControlList;

    setState(() {
      stateCartOverrideFormControlListByApplicationId =
          cartOverrideFormControlListByApplicationId;
    });
  }

  void addToCart(String applicationId) {
    List<String> applicationIdList = stateCartApplicationIdList;
    if (!applicationIdList.contains(applicationId)) {
      applicationIdList.add(applicationId);
    }

    setState(() {
      stateCartApplicationIdList = applicationIdList;
    });
  }

  void removeFromCart(String applicationId) {
    List<String> applicationIdList = stateCartApplicationIdList;
    if (applicationIdList.contains(applicationId)) {
      applicationIdList.remove(applicationId);
    }

    if (stateCartOverrideFormControlListByApplicationId
        .containsKey(applicationId)) {
      stateCartOverrideFormControlListByApplicationId.remove(applicationId);
    }

    setState(() {
      stateCartApplicationIdList = applicationIdList;
    });
  }

  void goToPrevious() {
    goTo(page: statePreviousPage, argumentMap: statePreviousPArgumentMap);
  }

  void reload() {
    setState(() {
      stateInterfaceVersion = (stateInterfaceVersion + 1);
    });
  }

  void goTo({required String page, required Map<String, String> argumentMap}) {
    if (NavigationEntity.hasArgumentSearch(argumentMap)) {
      String newSearch = NavigationEntity.extractArgumentSearch(argumentMap);
      if (newSearch != stateSearched) {
        _logger.info(
            'update search to ${NavigationEntity.extractArgumentSearch(argumentMap)}');
        setState(() {
          stateSearched = NavigationEntity.extractArgumentSearch(argumentMap);
        });
      }
    }

    if (page != NavigationEntity.pageSearch) {
      setState(() {
        stateSearched = '';
      });
    }

    if ([
      NavigationEntity.pageCart,
      NavigationEntity.pageCategory,
      NavigationEntity.pageHome,
      NavigationEntity.pageInstalledApplication,
      NavigationEntity.pageSearch,
    ].contains(page)) {
      setState(() {
        statePreviousPage = page;
        statePreviousPArgumentMap = argumentMap;
        stateHasPrevious = true;
      });
    } else if ([
      NavigationEntity.pageUpdateAvailables,
      NavigationEntity.pageUserSettings,
      NavigationEntity.pageMore,
    ].contains(page)) {
      statePreviousPage = '';
      //statePreviousPArgumentMap = [];
      stateHasPrevious = false;
    }

    setState(() {
      statePage = page;
      stateArgumentMap = argumentMap;
    });
  }
}
