import 'package:dupot_easy_flatpak/Domain/Entity/db/application_entity.dart';
import 'package:dupot_easy_flatpak/Domain/Entity/user_settings_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SharedComponents/Card/card_application_component.dart';
import 'package:flutter/material.dart';

class GridApplicationListComponent extends StatelessWidget {
  final List<ApplicationEntity> applicationEntityList;
  final Function handleGoTo;
  final ScrollController handleScrollController;

  const GridApplicationListComponent(
      {super.key,
      required this.applicationEntityList,
      required this.handleGoTo,
      required this.handleScrollController});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: applicationEntityList.length,
      controller: handleScrollController,
      itemBuilder: (context, index) {
        ApplicationEntity appStreamLoop = applicationEntityList[index];

        String icon = '';
        if (appStreamLoop.hasAppIcon()) {
          icon =
              '${UserSettingsEntity().getApplicationIconsPath()}/${appStreamLoop.getAppIcon()}';
        }

        return SizedBox(
            width: 150,
            height: 120,
            child: CardApplicationComponent(
                id: appStreamLoop.id,
                title: appStreamLoop.getName(),
                sumary: appStreamLoop.getSummary(),
                icon: icon,
                handleGoTo: handleGoTo));
      },
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 180),
    );
  }
}
