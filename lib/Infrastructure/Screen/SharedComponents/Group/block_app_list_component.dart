import 'package:dupot_easy_flatpak/Domain/Entity/db/application_entity.dart';
import 'package:dupot_easy_flatpak/Domain/Entity/user_settings_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/localization_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Entity/navigation_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SharedComponents/Card/card_application_component.dart';
import 'package:flutter/material.dart';

class BlockAppListComponent extends StatelessWidget {
  final String categoryId;
  final List<ApplicationEntity> appStreamList;
  final String appPath;
  final Function handleGoTo;

  const BlockAppListComponent({
    super.key,
    required this.categoryId,
    required this.appStreamList,
    required this.appPath,
    required this.handleGoTo,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> widgetList = appStreamList.map((appStreamLoop) {
      String icon = '';
      if (appStreamLoop.hasAppIcon()) {
        icon =
            '${UserSettingsEntity().getApplicationIconsPath()}/${appStreamLoop.getAppIcon()}';
      }

      return SizedBox(
          width: 170,
          height: 160,
          child: CardApplicationComponent(
              id: appStreamLoop.id,
              title: appStreamLoop.getName(),
              sumary: appStreamLoop.getSummary(),
              icon: icon,
              handleGoTo: handleGoTo));
    }).toList();

    widgetList.add(SizedBox(
        width: 170,
        height: 160,
        child: IconButton(
          icon: const Icon(Icons.more_horiz_outlined),

          // icon: Icon(Icons.more),
          onPressed: () {
            NavigationEntity.gotToCategoryId(
                handleGoTo: handleGoTo, categoryId: categoryId);
          },
        )));

    return Column(
      children: [
        const SizedBox(height: 20),
        Text(
          LocalizationApi().tr(categoryId),
          style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey),
        ),
        const SizedBox(height: 10),
        Wrap(children: widgetList),
      ],
    );
  }
}
