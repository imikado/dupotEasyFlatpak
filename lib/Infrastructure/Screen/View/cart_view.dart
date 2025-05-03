import 'dart:io';

import 'package:dupot_easy_flatpak/Domain/Entity/db/application_entity.dart';
import 'package:dupot_easy_flatpak/Domain/Entity/recipe/permission_overrided_entity.dart';
import 'package:dupot_easy_flatpak/Domain/Entity/user_settings_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/localization_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/recipe_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Entity/navigation_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Entity/override_form_control.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Repository/application_repository.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SharedComponents/Button/install_all_button.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SharedComponents/Button/override_button.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SharedComponents/Button/remove_from_cart_button.dart';
import 'package:flutter/material.dart';

class CartView extends StatefulWidget {
  final Function handleGoTo;
  final List<String> applicationIdListInCart;
  final bool isMain;
  final Function handleRemoveFromCart;
  final Map<String, List<OverrideFormControl>> overrideSetupListByApplicationId;
  final Map<String, List<PermissionOverridedEntity>>
      importedPermissionOverridedEntityListByApplicationId;
  final String applicationId;

  const CartView(
      {super.key,
      required this.handleGoTo,
      required this.isMain,
      required this.applicationIdListInCart,
      required this.handleRemoveFromCart,
      required this.overrideSetupListByApplicationId,
      required this.importedPermissionOverridedEntityListByApplicationId,
      required this.applicationId});

  @override
  State<CartView> createState() => _CartViewState();
}

class _CartViewState extends State<CartView> {
  List<ApplicationEntity> stateApplicationEntityList = [];
  List<String> stateApplicationRecipeIdList = [];

  Map<String, bool> stateCheckboxList = {};
  List<String> stateApplicationIdWhichHasRecipeList = [];

  ScrollController scrollController = ScrollController();

  @override
  void initState() {
    loadData();

    super.initState();
  }

  @override
  void didUpdateWidget(CartView oldWidget) {
    loadData();

    super.didUpdateWidget(oldWidget);
  }

  Future<void> loadData() async {
    Map<String, bool> checkboxList = {};

    List<String> distinctApplicationIdList = [];

    List<String> applicationRecipeIdList =
        await RecipeApi().getRecipeApplicationIdList();

    for (String applicationIdLoop in widget.applicationIdListInCart) {
      if (!distinctApplicationIdList.contains(applicationIdLoop)) {
        checkboxList[applicationIdLoop] = false;

        distinctApplicationIdList.add(applicationIdLoop);
      }
    }

    List<ApplicationEntity> applicationEntityList =
        await ApplicationRepository()
            .findListApplicationEntityByIdList(distinctApplicationIdList);

    List<String> applicationIdWhichHasRecipeList = [];
    for (String distinctApplicationIdLoop in distinctApplicationIdList) {
      if (applicationRecipeIdList.contains(distinctApplicationIdLoop)) {
        applicationIdWhichHasRecipeList.add(distinctApplicationIdLoop);
      }
    }

    List<String> applicationEntityIdList = [];
    for (ApplicationEntity applicationEntityLoop in applicationEntityList) {
      applicationEntityIdList.add(applicationEntityLoop.id);
    }

    for (String applicationIdInCartLoop in widget.applicationIdListInCart) {
      if (!applicationEntityIdList.contains(applicationIdInCartLoop)) {
        applicationEntityList.add(ApplicationEntity(
            id: applicationIdInCartLoop,
            name: applicationIdInCartLoop,
            summary: 'n/c',
            httpIcon: '',
            categoryIdList: [],
            description: '',
            metadataObj: {},
            urlObj: {},
            releaseObjList: [],
            lastUpdate: 0,
            projectLicense: '',
            developer_name: '',
            screenshotObjList: [],
            lastReleaseTimestamp: 0));
      }
    }

    setState(() {
      stateCheckboxList = checkboxList;

      stateApplicationEntityList = applicationEntityList;

      stateApplicationRecipeIdList = applicationRecipeIdList;

      stateApplicationIdWhichHasRecipeList = applicationIdWhichHasRecipeList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
        interactive: false,
        thumbVisibility: true,
        controller: scrollController,
        child: Column(children: [
          Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  getInstallAllButton(),
                ],
              )),
          Expanded(
              child: ListView(
                  controller: scrollController,
                  children: stateApplicationEntityList.isEmpty
                      ? [
                          ListTile(
                            title: Text(LocalizationApi().tr('cart_is_empty')),
                          )
                        ]
                      : stateApplicationEntityList
                          .map((ApplicationEntity applicationEntity) =>
                              getLine(applicationEntity))
                          .toList()))
        ]));
  }

  ApplicationEntity? getApplicationEntity(String id) {
    for (ApplicationEntity appLoop in stateApplicationEntityList) {
      if (appLoop.id.toLowerCase() == id.toLowerCase()) {
        return appLoop;
      }
    }
    return null;
  }

  Widget getLine(ApplicationEntity applicationEntity) {
    return Card(
        color: widget.applicationId == applicationEntity.id
            ? Theme.of(context).secondaryHeaderColor
            : Theme.of(context).primaryColorLight,
        child: ListTile(
          title: Column(
            children: [
              Row(
                children: [
                  const SizedBox(width: 10),
                  !applicationEntity.hasAppIcon()
                      ? Image.asset('assets/images/no-image.png', height: 60)
                      : Image.file(
                          height: 60,
                          File(
                              '${UserSettingsEntity().getApplicationIconsPath()}/${applicationEntity.getAppIcon()}')),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          applicationEntity.getName(),
                          style: TextStyle(
                              fontSize: 26,
                              color: Theme.of(context)
                                  .textTheme
                                  .headlineLarge!
                                  .color),
                        ),
                        Text(applicationEntity.getSummary()),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (stateApplicationRecipeIdList
                          .contains(applicationEntity.id))
                        Padding(
                            padding: const EdgeInsets.fromLTRB(0, 0, 0, 5),
                            child: OverrideButton(
                              applicationEntity: applicationEntity,
                              handle: () {
                                NavigationEntity
                                    .goToCartSetupOverrideForApplicationId(
                                        handleGoTo: widget.handleGoTo,
                                        applicationId: applicationEntity.id);
                              },
                              isActive: widget.isMain,
                              hasError: !widget.overrideSetupListByApplicationId
                                  .containsKey(applicationEntity.id),
                            )),
                      RemoveFromCartButton(
                          applicationEntity: applicationEntity,
                          handle: () {
                            widget.handleRemoveFromCart(applicationEntity.id);
                          },
                          isActive: widget.isMain)
                    ],
                  )
                ],
              ),
            ],
          ),
        ));
  }

  Widget getInstallAllButton() {
    if (widget.applicationIdListInCart.isEmpty) {
      return InstallAllButton(
        isActive: false,
        handle: () {},
      );
    }

    for (String applicationIdWithRecipeLoop
        in stateApplicationIdWhichHasRecipeList) {
      if (!widget.overrideSetupListByApplicationId
          .containsKey(applicationIdWithRecipeLoop)) {
        return InstallAllButton(
          isActive: false,
          handle: () {},
        );
      }
    }

    return InstallAllButton(
      isActive: widget.isMain,
      handle: () {
        NavigationEntity.goToCartInstallingAll(
          handleGoTo: widget.handleGoTo,
        );
      },
    );
  }
}
