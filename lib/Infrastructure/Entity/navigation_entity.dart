class NavigationEntity {
  static const String pageLoading = 'loading';
  static const String pageHome = 'home';
  static const String pageCategory = 'category';
  static const String pageApplication = 'application';
  static const String pageInstalledApplication = 'installedApps';
  static const String pageSearch = 'search';
  static const String pageUpdateAvailables = 'updatesAvailables';
  static const String pageUserSettings = 'userSettings';
  static const String pageMore = 'more';
  static const String pageBundles = 'bundles';

  static const String pageReload = 'reload';
  static const String pageAbout = 'about';
  static const String pageCart = 'cart';

  static const String argumentApplicationId = 'applicationId';
  static const String argumentCategoryId = 'categoryId';
  static const String argumentBundleId = 'bundleId';

  static const String argumentSubPage = 'subPage';

  static const String argumentSubPageInstall = 'application_install';
  static const String argumentSubPageInstallWithRecipe =
      'application_installWithRecipe';
  static const String argumentSubPageUninstall = 'application_uninstall';
  static const String argumentSubPageOverride = 'application_override';
  static const String argumentSubPageUpdateAvailableProcessing =
      'updatesAvailables_processing';
  static const String argumentSubPageUpdateAvailableProcessingAll =
      'updatesAvailables_processingAll';
  static const String argumentSubPageCartInstallAll = 'cart_install_all';
  static const String argumentSubPageCartSetupOverride = 'cart_setup_override';

  static const String argumentSubPageExport = 'more_export';
  static const String argumentSubPageImport = 'more_import';

  static const String argumentSubPageBundleDetail = 'bundle_detail';

  static const String argumentApplicationIdSelectedList =
      'application_id_selected_list';

  static const String argumentSearch = 'search';

  static const String argumentInstallScope = 'installScope';

  static goToCart({required Function handleGoTo}) {
    handleGoTo(page: pageCart, argumentMap: {'': ''});
  }

  static goToBundles({required Function handleGoTo}) {
    handleGoTo(page: pageBundles, argumentMap: {'': ''});
  }

  static goToBundleDetail(
      {required Function handleGoTo, required String bundleId}) {
    handleGoTo(page: pageBundles, argumentMap: {
      argumentSubPage: argumentSubPageBundleDetail,
      argumentBundleId: bundleId
    });
  }

  static goToCartInstallingAll({required Function handleGoTo}) {
    handleGoTo(
        page: pageCart,
        argumentMap: {argumentSubPage: argumentSubPageCartInstallAll});
  }

  static goToCartSetupOverrideForApplicationId(
      {required Function handleGoTo, required String applicationId}) {
    handleGoTo(page: pageCart, argumentMap: {
      argumentSubPage: argumentSubPageCartSetupOverride,
      argumentApplicationId: applicationId
    });
  }

  static goToReload({required Function handleGoTo}) {
    handleGoTo(page: pageLoading, argumentMap: {'': ''});
  }

  static goToHome({required Function handleGoTo}) {
    handleGoTo(page: pageHome, argumentMap: {'': ''});
  }

  static goToSearch({required Function handleGoTo, required String search}) {
    handleGoTo(page: pageSearch, argumentMap: {argumentSearch: search});
  }

  static goToAbout({required Function handleGoTo}) {
    handleGoTo(page: pageAbout, argumentMap: {'': ''});
  }

  static goToUpdatesAvailables({required Function handleGoTo}) {
    handleGoTo(page: pageUpdateAvailables, argumentMap: {'': ''});
  }

  static goToInstalledApplications({required Function handleGoTo}) {
    handleGoTo(page: pageInstalledApplication, argumentMap: {'': ''});
  }

  static goToSettings({required Function handleGoTo}) {
    handleGoTo(page: pageUserSettings, argumentMap: {'': ''});
  }

  static goToMore({required Function handleGoTo}) {
    handleGoTo(page: pageMore, argumentMap: {'': ''});
  }

  static goToMoreExport({required Function handleGoTo}) {
    handleGoTo(
        page: pageMore, argumentMap: {argumentSubPage: argumentSubPageExport});
  }

  static goToMoreImport({required Function handleGoTo}) {
    handleGoTo(
        page: pageMore, argumentMap: {argumentSubPage: argumentSubPageImport});
  }

  static extractArgumentBundleId(Map<String, String> argumentMap) {
    return argumentMap[argumentBundleId];
  }

  static extractArgumentApplicationId(Map<String, String> argumentMap) {
    return argumentMap[argumentApplicationId];
  }

  static extractArgumentCategoryId(Map<String, String> argumentMap) {
    return argumentMap[argumentCategoryId];
  }

  static extractArgumentSubPage(Map<String, String> argumentMap) {
    return argumentMap[argumentSubPage];
  }

  static extractArgumentApplicationIdSelectedList(
      Map<String, String> argumentMap) {
    return argumentMap[argumentApplicationIdSelectedList]!.split(',');
  }

  static hasArgumentSearch(Map<String, String> argumentMap) {
    return argumentMap.containsKey(argumentSearch);
  }

  static hasArgumentBundle(Map<String, String> argumentMap) {
    return argumentMap.containsKey(argumentBundleId);
  }

  static extractArgumentSearch(Map<String, String> argumentMap) {
    return argumentMap[argumentSearch];
  }

  static extractArgumentInstallScope(Map<String, String> argumentMap) {
    return argumentMap[argumentInstallScope];
  }

  static gotToApplicationId(
      {required Function handleGoTo, required String applicationId}) {
    handleGoTo(
        page: pageApplication,
        argumentMap: {argumentApplicationId: applicationId});
  }

  static gotToCategoryId(
      {required Function handleGoTo, required String categoryId}) {
    handleGoTo(
        page: pageCategory, argumentMap: {argumentCategoryId: categoryId});
  }

  static String getFlatpakScope(bool installUserScope) {
    String installScope = '--system';
    if (installUserScope) {
      installScope = '--user';
    }
    return installScope;
  }

  static goToApplicationInstall(
      {required Function handleGoTo,
      required String applicationId,
      required bool installUserScope}) {
    handleGoTo(page: pageApplication, argumentMap: {
      argumentApplicationId: applicationId,
      argumentSubPage: argumentSubPageInstall,
      argumentInstallScope: getFlatpakScope(installUserScope)
    });
  }

  static goToApplicationInstallWithRecipe(
      {required Function handleGoTo,
      required String applicationId,
      required bool installUserScope}) {
    handleGoTo(page: pageApplication, argumentMap: {
      argumentApplicationId: applicationId,
      argumentSubPage: argumentSubPageInstallWithRecipe,
      argumentInstallScope: getFlatpakScope(installUserScope)
    });
  }

  static goToApplicationUninstall(
      {required Function handleGoTo,
      required String applicationId,
      required bool willDeleteAppData,
      required bool installUserScope}) {
    handleGoTo(page: pageApplication, argumentMap: {
      argumentApplicationId: applicationId,
      argumentSubPage: argumentSubPageUninstall,
      if (willDeleteAppData) 'willDeleteAppData': 'yes',
      argumentInstallScope: getFlatpakScope(installUserScope)
    });
  }

  static goToApplicationOverride(
      {required Function handleGoTo, required String applicationId}) {
    handleGoTo(page: pageApplication, argumentMap: {
      argumentApplicationId: applicationId,
      argumentSubPage: argumentSubPageOverride
    });
  }

  static goToUpdatesAvailablesPocessing(
      {required Function handleGoTo,
      required List<String> applicationIdSelectedList}) {
    handleGoTo(page: pageUpdateAvailables, argumentMap: {
      argumentSubPage: argumentSubPageUpdateAvailableProcessing,
      argumentApplicationIdSelectedList: applicationIdSelectedList.join(',')
    });
  }

  static goToUpdatesAvailablesPocessingAll({
    required Function handleGoTo,
  }) {
    handleGoTo(page: pageUpdateAvailables, argumentMap: {
      argumentSubPage: argumentSubPageUpdateAvailableProcessingAll,
    });
  }
}
