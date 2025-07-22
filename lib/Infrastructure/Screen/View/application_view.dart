import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:dupot_easy_flatpak/Domain/Entity/db/application_entity.dart';
import 'package:dupot_easy_flatpak/Domain/Entity/user_settings_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/localization_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Control/Model/View/application_view_model.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Entity/navigation_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SharedComponents/Button/add_to_cart_button.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SharedComponents/Button/install_button.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SharedComponents/Button/install_with_recipe_button.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SharedComponents/Button/override_button.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SharedComponents/Button/remove_from_cart_button.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SharedComponents/Button/run_button.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SharedComponents/Button/uninstall_button.dart';
import 'package:flutter/material.dart';

import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ApplicationView extends StatefulWidget {
  final String applicationIdSelected;
  final Function handleGoTo;
  final Function handleGoToPrevious;
  final Function handleAddToCart;
  final Function handleRemoveFromCart;
  final Function handleReload;
  final List<String> applicationIdListInCart;
  final bool isMain;

  const ApplicationView(
      {super.key,
      required this.applicationIdSelected,
      required this.handleGoTo,
      required this.handleGoToPrevious,
      required this.handleAddToCart,
      required this.handleRemoveFromCart,
      required this.handleReload,
      required this.applicationIdListInCart,
      required this.isMain});

  void addToCart() {
    handleAddToCart(applicationIdSelected);

    handleReload();
  }

  void removeFromCart() {
    handleRemoveFromCart(applicationIdSelected);

    handleReload();
  }

  void goToInstallation(bool installUserScope) {
    NavigationEntity.goToApplicationInstall(
        handleGoTo: handleGoTo,
        applicationId: applicationIdSelected,
        installUserScope: installUserScope);
  }

  void goToInstallationWithRecipe(bool installUserScope) {
    NavigationEntity.goToApplicationInstallWithRecipe(
        handleGoTo: handleGoTo,
        applicationId: applicationIdSelected,
        installUserScope: installUserScope);
  }

  void goToUninstallation(bool willDeleteAppData, bool installUserScope) {
    NavigationEntity.goToApplicationUninstall(
        handleGoTo: handleGoTo,
        applicationId: applicationIdSelected,
        willDeleteAppData: willDeleteAppData,
        installUserScope: installUserScope);
  }

  void goToOverride() {
    NavigationEntity.goToApplicationOverride(
        handleGoTo: handleGoTo, applicationId: applicationIdSelected);
  }

  @override
  State<ApplicationView> createState() => _ApplicationViewState();
}

class _ApplicationViewState extends State<ApplicationView> {
  ApplicationEntity? stateAppStream;
  bool stateIsAlreadyInstalled = false;
  bool stateHasRecipe = false;

  bool stateIsOverrided = false;

  String applicationIdSelected = '';

  String appPath = '';

  final ScrollController scrollController = ScrollController();

  final ScrollController scrollControllerScreenshot = ScrollController();

  @override
  void initState() {
    loadData();

    super.initState();
  }

  @override
  void didUpdateWidget(ApplicationView oldWidget) {
    if (oldWidget.isMain != widget.isMain) {
      updateAlreadyInstalled();
    }

    super.didUpdateWidget(oldWidget);
  }

  Future<void> updateAlreadyInstalled() async {
    ApplicationEntity appStream = stateAppStream!;
    appStream.isAlreadyInstalled =
        await ApplicationViewModel().checkAlreadyInstalled(appStream.id);

    setState(() {
      stateAppStream = appStream;
    });
  }

  Future<void> loadData() async {
    applicationIdSelected = widget.applicationIdSelected;

    ApplicationEntity appStream = await ApplicationViewModel()
        .getApplicationEntity(applicationIdSelected);

    if (appStream.isEmpty) {
      return widget.handleGoToPrevious();
    }

    setState(() {
      stateAppStream = appStream;
    });
  }

  ButtonStyle getButtonStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        padding: const EdgeInsets.all(16),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        textStyle: const TextStyle(fontSize: 14, color: Colors.white));
  }

  @override
  Widget build(BuildContext context) {
    return stateAppStream == null
        ? const LinearProgressIndicator()
        : Scrollbar(
            interactive: false,
            thumbVisibility: true,
            controller: scrollController,
            child: ListView(
              controller: scrollController,
              children: [
                Row(
                  children: [
                    if (stateAppStream!.hasAppIcon())
                      Padding(
                          padding: const EdgeInsets.all(20),
                          child: Image.file(File(
                              '${UserSettingsEntity().getApplicationIconsPath()}/${stateAppStream!.getAppIcon()}'))),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stateAppStream!.getName(),
                            style: const TextStyle(
                                fontSize: 35, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Text(
                            '${LocalizationApi().tr('By')} ${stateAppStream!.developer_name}',
                            style: const TextStyle(
                                fontStyle: FontStyle.italic, fontSize: 15),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          if (stateAppStream!.projectLicense.isNotEmpty)
                            Text(
                                '${LocalizationApi().tr('License')}: ${stateAppStream!.projectLicense}'),
                          const SizedBox(
                            height: 10,
                          ),
                          if (stateAppStream!.isVerified())
                            TextButton.icon(
                                style: TextButton.styleFrom(
                                    padding: const EdgeInsets.only(
                                        top: 5, bottom: 5, right: 5, left: 0),
                                    alignment: AlignmentDirectional.topStart),
                                icon: const Icon(Icons.verified),
                                onPressed: () {
                                  String verifiedUrl =
                                      stateAppStream!.getVerifiedUrl();
                                  if (verifiedUrl.isNotEmpty) {
                                    launchUrl(Uri.parse(verifiedUrl));
                                  }
                                },
                                label:
                                    Text(stateAppStream!.getVerifiedLabel())),
                        ],
                      ),
                    ),
                    !widget.isMain
                        ? const SizedBox()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              getOverrideButton(
                                  stateAppStream!.isAlreadyInstalled,
                                  stateAppStream!.hasRecipe),
                              const SizedBox(
                                height: 2,
                              ),
                              getAddToCartButton(
                                  stateAppStream!.isAlreadyInstalled),
                              const SizedBox(
                                height: 2,
                              ),
                              getInstallButton(
                                  stateAppStream!.isAlreadyInstalled,
                                  stateAppStream!.hasRecipe),
                              const SizedBox(
                                height: 2,
                              ),
                              getRunButton(stateAppStream!.isAlreadyInstalled),
                              const SizedBox(
                                height: 2,
                              ),
                            ],
                          ),
                    const SizedBox(width: 20)
                  ],
                ),
                if (stateAppStream!.screenshotObjList.isNotEmpty)
                  ListTile(
                    title: Text(LocalizationApi().tr('Screenshots'),
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context)
                                .textTheme
                                .headlineLarge!
                                .color)),
                  ),
                if (stateAppStream!.screenshotObjList.isNotEmpty)
                  Padding(
                      padding: const EdgeInsets.all(20),
                      child: getScreenshotCaroussel(
                          stateAppStream!.screenshotObjList)
                      /*
                       Scrollbar(
                          interactive: false,
                          thumbVisibility: true,
                          controller: scrollControllerScreenshot,
                          child: SingleChildScrollView(
                              controller: scrollControllerScreenshot,
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                  children: stateAppStream!.screenshotObjList
                                      .map((screenshotLoop) {
                                return IconButton(
                                    onPressed: () {
                                      showDialog(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                              buttonPadding:
                                                  const EdgeInsets.all(0),
                                              content: Image.network(
                                                  screenshotLoop['large'])));
                                    },
                                    icon: Image.network(
                                        screenshotLoop['preview']));
                              }).toList())))
                              
                              */
                      ),
                Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stateAppStream!.getSummary(),
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context)
                                  .textTheme
                                  .headlineLarge!
                                  .color),
                        ),
                        const SizedBox(
                          height: 15,
                        ),
                        HtmlWidget(
                          stateAppStream!.getDescription(),
                        ),
                      ],
                    )),
                ListTile(
                    title: Text(
                  LocalizationApi().tr('Infos'),
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.headlineLarge!.color),
                )),
                Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text("${LocalizationApi().tr('Download_Size')}:",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(width: 10),
                            Text(stateAppStream!.getDownloadSize())
                          ],
                        ),
                        Row(
                          children: [
                            Text("${LocalizationApi().tr('Installed_Size')}:",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(width: 10),
                            Text(stateAppStream!.getInstalledSize())
                          ],
                        )
                      ],
                    )),
                ListTile(
                    title: Text(
                  LocalizationApi().tr('Last_releases'),
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.headlineLarge!.color),
                )),
                Padding(
                    padding: const EdgeInsets.only(
                        top: 5, bottom: 5, right: 5, left: 25),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: stateAppStream!
                            .getReleaseObjList()
                            .map((realeaseObjLoop) {
                          if (realeaseObjLoop.containsKey('timestamp') &&
                              realeaseObjLoop['timestamp'] != null) {
                            DateTime dateVersion =
                                DateTime.fromMillisecondsSinceEpoch(
                                    int.parse(realeaseObjLoop['timestamp']) *
                                        1000);

                            return Row(children: [
                              Text(
                                  DateFormat('dd/MM/yyyy').format(dateVersion)),
                              const SizedBox(width: 2),
                              const Text(':'),
                              const SizedBox(width: 10),
                              Text(realeaseObjLoop['version'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold))
                            ]);
                          } else {
                            return Row(children: [
                              Text('N/C'),
                              const SizedBox(width: 2),
                              const Text(':'),
                              const SizedBox(width: 10),
                              Text(realeaseObjLoop['version'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold))
                            ]);
                          }
                        }).toList())),
                ListTile(
                    title: Text(
                  LocalizationApi().tr('Links'),
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.headlineLarge!.color),
                )),
                Padding(
                    padding: const EdgeInsets.only(
                        top: 5, bottom: 5, right: 5, left: 10),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:
                            stateAppStream!.getUrlObjList().map((urlObjLoop) {
                          String url = urlObjLoop['value'].toString();

                          return TextButton.icon(
                            icon: getIcon(urlObjLoop['key'].toString()),
                            onPressed: () {
                              launchUrl(Uri.parse(url));
                            },
                            label: Text(url),
                          );
                        }).toList()))
              ],
            ));
  }

  Widget getScreenshotCaroussel(List<dynamic> screenshotObjList) {
    return CarouselSlider.builder(
      itemCount: screenshotObjList.length,
      options: CarouselOptions(
        autoPlay: false,
        aspectRatio: 2.0,
        enlargeCenterPage: true,
      ),
      itemBuilder: (context, index, realIdx) {
        dynamic screenshotLoop = screenshotObjList[index];

        return Center(
            child: Image.network(screenshotLoop['large'],
                fit: BoxFit.cover, width: 1000));
      },
    );
  }

  Widget getOverrideButton(bool isAlreadyInstalled, bool isOverrided) {
    return isAlreadyInstalled & isOverrided
        ? OverrideButton(
            applicationEntity: stateAppStream!,
            handle: widget.goToOverride,
            isActive: widget.isMain,
            hasError: false,
          )
        : const SizedBox();
  }

  Widget getAddToCartButton(bool isAlreadyInstalled) {
    if (isAlreadyInstalled) {
      return const SizedBox();
    }

    if (widget.applicationIdListInCart.contains(stateAppStream!.id)) {
      return RemoveFromCartButton(
          applicationEntity: stateAppStream!,
          handle: widget.removeFromCart,
          isActive: widget.isMain);
    }
    return AddToCartButton(
        applicationEntity: stateAppStream!,
        handle: widget.addToCart,
        isActive: widget.isMain);
  }

  Widget getInstallButton(bool isAlreadyInstalled, bool hasRecipe) {
    if (isAlreadyInstalled) {
      return UninstallButton(
        applicationEntity: stateAppStream!,
        handle: widget.goToUninstallation,
        isActive: widget.isMain,
        scopeUser: stateAppStream!.isScopeUser,
      );
    }

    if (hasRecipe) {
      return InstallWithRecipeButton(
          applicationEntity: stateAppStream!,
          handle: widget.goToInstallationWithRecipe,
          isActive: widget.isMain);
    } else {
      return InstallButton(
        applicationEntity: stateAppStream!,
        handle: widget.goToInstallation,
        isActive: widget.isMain,
      );
    }
  }

  Widget getRunButton(bool isAlreadyInstalled) {
    return isAlreadyInstalled
        ? RunButton(applicationEntity: stateAppStream!, isActive: widget.isMain)
        : const SizedBox();
  }

  Widget getIcon(String type) {
    if (type == 'homepage') {
      return const Icon(Icons.home);
    } else if (type == 'bugtracker') {
      return const Icon(Icons.bug_report);
    }
    return const Icon(Icons.ac_unit);
  }
}
