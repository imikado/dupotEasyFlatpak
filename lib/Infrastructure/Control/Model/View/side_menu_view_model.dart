import 'package:dupot_easy_flatpak/Domain/Entity/db/application_entity.dart';
import 'package:dupot_easy_flatpak/Domain/Entity/user_settings_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/command_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/flathub_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Entity/menu_item_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Entity/navigation_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Repository/application_repository.dart';
import 'package:flutter/material.dart';

class SideMenuViewModel {
  Function handleGoTo;

  SideMenuViewModel({required this.handleGoTo});

  Map<String, IconData> iconList = {
    'AudioVideo': Icons.play_circle,
    'Development': Icons.developer_board,
    'Education': Icons.school,
    'Game': Icons.gamepad,
    'Graphics': Icons.draw,
    'Network': Icons.network_check,
    'Office': Icons.document_scanner,
    'Science': Icons.science,
    'System': Icons.system_update_tv,
    'Utility': Icons.build,
  };

  int numberOfNewApplicationFromApi = 0;

  Future<List<MenuItemEntity>> getCategoryMenuItemEntityList() async {
    List<String> categoryIdList =
        await ApplicationRepository().findAllCategoryList();

    List<MenuItemEntity> menuItemList = [];

    menuItemList.add(MenuItemEntity(
        label: 'Home',
        action: () {
          NavigationEntity.goToHome(
            handleGoTo: handleGoTo,
          );
        },
        pageSelected: NavigationEntity.pageHome,
        badge: '',
        categoryIdSelected: '',
        icon: Icons.home));

    for (String categoryIdLoop in categoryIdList) {
      menuItemList.add(MenuItemEntity(
          label: categoryIdLoop,
          action: () {
            NavigationEntity.gotToCategoryId(
              handleGoTo: handleGoTo,
              categoryId: categoryIdLoop,
            );
          },
          pageSelected: 'category',
          badge: '',
          categoryIdSelected: categoryIdLoop,
          icon: iconList[categoryIdLoop]!));
    }

    return menuItemList;
  }

  List<MenuItemEntity> getCartMenuItemEntyList(
      List<String> applicationIdListInCart) {
    List<MenuItemEntity> menuItemList = [];

    int numberOfApplicationInCart = applicationIdListInCart.length;

    if (numberOfApplicationInCart > 0) {
      menuItemList.add(MenuItemEntity(
          label: 'Cart',
          action: () {
            NavigationEntity.goToCart(handleGoTo: handleGoTo);
          },
          pageSelected: NavigationEntity.pageCart,
          categoryIdSelected: '',
          badge: numberOfApplicationInCart.toString(),
          icon: Icons.shopping_cart));
    }

    return menuItemList;
  }

  List<MenuItemEntity> getSearchMenuItemEntyList(
      String pageSelected, String searched, bool displaySearch) {
    List<MenuItemEntity> menuItemList = [];

    if (displaySearch && pageSelected == NavigationEntity.pageSearch) {
      menuItemList.add(MenuItemEntity(
          label: 'Search',
          action: () {
            NavigationEntity.goToSearch(
                handleGoTo: handleGoTo, search: searched);
          },
          pageSelected: NavigationEntity.pageSearch,
          categoryIdSelected: '',
          badge: '',
          icon: Icons.search));
    }

    return menuItemList;
  }

  List<MenuItemEntity> getSearchMenuItemEntyListWithoutPage(
      String searched, bool displaySearch) {
    List<MenuItemEntity> menuItemList = [];

    if (displaySearch) {
      menuItemList.add(MenuItemEntity(
          label: 'Search',
          action: () {
            NavigationEntity.goToSearch(
                handleGoTo: handleGoTo, search: searched);
          },
          pageSelected: NavigationEntity.pageSearch,
          categoryIdSelected: '',
          badge: '',
          icon: Icons.search));
    }

    return menuItemList;
  }

  Future<List<MenuItemEntity>> getMiddleMenuItemEntityList() async {
    List<MenuItemEntity> menuItemList = [];
    menuItemList.add(MenuItemEntity(
        label: 'Bundles',
        action: () {
          NavigationEntity.goToBundles(
            handleGoTo: handleGoTo,
          );
        },
        pageSelected: NavigationEntity.pageBundles,
        badge: '',
        categoryIdSelected: '',
        icon: Icons.add_box));

    return menuItemList;
  }

  Future<List<MenuItemEntity>> getEndMenuItemEntityList() async {
    List<MenuItemEntity> menuItemList = [];

    menuItemList.add(MenuItemEntity(
        label: 'Settings',
        action: () {
          NavigationEntity.goToSettings(
            handleGoTo: handleGoTo,
          );
        },
        pageSelected: NavigationEntity.pageUserSettings,
        badge: '',
        categoryIdSelected: '',
        icon: Icons.settings));

    menuItemList.add(MenuItemEntity(
        label: 'More_actions',
        action: () {
          NavigationEntity.goToMore(
            handleGoTo: handleGoTo,
          );
        },
        pageSelected: NavigationEntity.pageMore,
        badge: '',
        categoryIdSelected: '',
        icon: Icons.import_export));

    menuItemList.add(MenuItemEntity(
        label: 'About',
        action: () {
          NavigationEntity.goToAbout(
            handleGoTo: handleGoTo,
          );
        },
        pageSelected: NavigationEntity.pageAbout,
        categoryIdSelected: '',
        badge: '',
        icon: Icons.help));

    return menuItemList;
  }

  Future<List<MenuItemEntity>> getBottomMenuItemEntityList(
      bool shouldCheckUpdates) async {
    if (shouldCheckUpdates) {
      await CommandApi().checkUpdates();
    }

    List<MenuItemEntity> menuItemList = [];

    menuItemList.add(MenuItemEntity(
        label: 'InstalledApps',
        action: () {
          NavigationEntity.goToInstalledApplications(handleGoTo: handleGoTo);
        },
        pageSelected: NavigationEntity.pageInstalledApplication,
        categoryIdSelected: '',
        badge: await getInstalledAppLabel(),
        icon: Icons.install_desktop));

    if (await shouldDisplayUpdateButton()) {
      menuItemList.add(MenuItemEntity(
          label: 'Updates',
          action: () {
            NavigationEntity.goToUpdatesAvailables(handleGoTo: handleGoTo);
          },
          pageSelected: NavigationEntity.pageUpdateAvailables,
          categoryIdSelected: '',
          badge: getUpdateAvailableLabel(),
          icon: Icons.notifications));
    }

    return menuItemList;
  }

  Future<String> getInstalledAppLabel() async {
    if (UserSettingsEntity().getDisplayApplicationInstalledNumberInSideMenu()) {
      List<String> installedApplicationIdList =
          await CommandApi().getInstalledApplicationList();

      List<ApplicationEntity> applicationEntityList =
          await ApplicationRepository()
              .findListApplicationEntityByIdList(installedApplicationIdList);

      return applicationEntityList.length.toString();
    }
    return '';
  }

  Future<bool> shouldDisplayUpdateButton() async {
    if (CommandApi().getNumberOfUpdates() > 0) {
      return true;
    }

    return false;
  }

  String getUpdateAvailableLabel() {
    return (CommandApi().getNumberOfUpdates()).toString();
  }
}
