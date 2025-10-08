import 'dart:io';

import 'package:dupot_easy_flatpak/Domain/Entity/bundle_entity.dart';
import 'package:dupot_easy_flatpak/Domain/Entity/db/application_entity.dart';
import 'package:dupot_easy_flatpak/Domain/Entity/user_settings_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/bundle_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/command_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/localization_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Entity/navigation_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Repository/application_repository.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SharedComponents/Button/close_subview_button.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/Theme/theme_button_style.dart';
import 'package:flutter/material.dart';

class BundleSubview extends StatefulWidget {
  final Function handleGoTo;
  final String bundleId;
  final Function handleAddToCart;
  final List<String> applicationIdListInCart;

  const BundleSubview(
      {super.key,
      required this.handleGoTo,
      required this.bundleId,
      required this.handleAddToCart,
      required this.applicationIdListInCart});

  @override
  State<BundleSubview> createState() => _BundleSubviewState();
}

class _BundleSubviewState extends State<BundleSubview> {
  BundleEntity? stateBundleEntity;
  bool stateIsAdding = false;
  Map<String, bool> stateCheckboxList = {};
  List<ApplicationEntity> stateApplicationEntityList = [];

  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    loadData().then((BundleEntity bundleEntity) {
      Map<String, bool> checkboxList = {};

      CommandApi commandApi = CommandApi();

      commandApi
          .getInstalledApplicationList()
          .then((List<String> installedApplicationIdList) {
        for (String applicationId in bundleEntity.applicationList) {
          checkboxList[applicationId] = !installedApplicationIdList
                  .contains(applicationId.toLowerCase()) &&
              !widget.applicationIdListInCart.contains(applicationId);
        }

        ApplicationRepository()
            .findListApplicationEntityByIdList(bundleEntity.applicationList)
            .then((List<ApplicationEntity> applicationEntityList) {
          setState(() {
            stateBundleEntity = bundleEntity;
            stateCheckboxList = checkboxList;
            stateApplicationEntityList = applicationEntityList;
          });
        });
      });
    });
  }

  @override
  void didUpdateWidget(BundleSubview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bundleId != widget.bundleId) {
      loadData();
    }
  }

  Future<BundleEntity> loadData() async {
    List<BundleEntity> bundleEntityList =
        await BundleApi().getBundleEntityList();

    for (BundleEntity bundleEntityLoop in bundleEntityList) {
      if (bundleEntityLoop.name == widget.bundleId) {
        return bundleEntityLoop;
      }
    }

    throw Exception('Unable to find bundleEntity');
  }

  @override
  Widget build(BuildContext context) {
    return stateBundleEntity == null
        ? const LinearProgressIndicator()
        : Scrollbar(
            interactive: false,
            thumbVisibility: true,
            controller: scrollController,
            child: ListView(controller: scrollController, children: [
              Wrap(
                alignment: WrapAlignment.end,
                children: [
                  getAddToCartButton(),
                  const SizedBox(width: 20),
                  stateIsAdding
                      ? const LinearProgressIndicator()
                      : CloseSubViewButton(
                          handle: () => NavigationEntity.goToBundles(
                              handleGoTo: widget.handleGoTo)),
                  const SizedBox(width: 20),
                  Padding(
                      padding: const EdgeInsets.all(20),
                      child: Container(
                          constraints: const BoxConstraints(minHeight: 800),
                          child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: stateBundleEntity!.applicationList
                                      .map((String applicationIdLoop) =>
                                          getLine(applicationIdLoop))
                                      .toList()))))
                ],
              )
            ]));
  }

  bool isEnabledByApplication(String applicationId) {
    return true;
  }

  ApplicationEntity? getApplicationEntity(String id) {
    for (ApplicationEntity appLoop in stateApplicationEntityList) {
      if (appLoop.id.toLowerCase() == id.toLowerCase()) {
        return appLoop;
      }
    }
    return null;
  }

  Widget getLine(String applicationId) {
    ApplicationEntity? applicationEntityFound =
        getApplicationEntity(applicationId);

    return Card(
        color: Theme.of(context).secondaryHeaderColor,
        child: CheckboxListTile(
          visualDensity: VisualDensity(horizontal: 0, vertical: -4),
          onChanged: (bool? value) {
            Map<String, bool> checkboxList = stateCheckboxList;

            checkboxList[applicationId] = value!;

            setState(() {
              stateCheckboxList = checkboxList;
            });
          },
          enabled: isEnabledByApplication(applicationId),
          value: stateCheckboxList[applicationId],
          title: Column(
            spacing: 0,
            children: [
              Row(
                children: [
                  applicationEntityFound == null ||
                          !applicationEntityFound.hasAppIcon()
                      ? Image.asset('assets/images/no-image.png', height: 60)
                      : Image.file(
                          height: 60,
                          File(
                              '${UserSettingsEntity().getApplicationIconsPath()}/${applicationEntityFound.getAppIcon()}')),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      spacing: 0,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          applicationEntityFound != null
                              ? applicationEntityFound.getName()
                              : applicationId,
                          style: TextStyle(
                              fontSize: 20,
                              color: Theme.of(context)
                                  .textTheme
                                  .headlineLarge!
                                  .color),
                        ),
                        Text(
                            applicationEntityFound != null
                                ? applicationEntityFound.getSummary()
                                : '',
                            style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  )
                ],
              ),
            ],
          ),
        ));
  }

  Widget getAddToCartButton() {
    ThemeButtonStyle themeButtonStyle = ThemeButtonStyle(context: context);

    return FilledButton.icon(
      style: ThemeButtonStyle(context: context).getButtonStyle(),
      onPressed: () async {
        setState(() {
          stateIsAdding = true;
        });

        stateCheckboxList.forEach((String applicationIdLoop, bool checked) {
          if (checked) {
            widget.handleAddToCart(applicationIdLoop);
          }
        });

        final snackBar = SnackBar(
          content: Text(LocalizationApi().tr('successfully_saved')),
        );

        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        setState(() {
          stateIsAdding = false;
        });

        NavigationEntity.goToBundles(handleGoTo: widget.handleGoTo);
      },
      label: Text(LocalizationApi().tr('add_to_cart'),
          style: themeButtonStyle.getButtonTextStyle()),
      icon: Icon(Icons.add_shopping_cart,
          color: themeButtonStyle.getButtonTextStyle().color),
    );
  }
}
