import 'dart:io';

import 'package:dupot_easy_flatpak/Domain/Entity/db/application_entity.dart';
import 'package:dupot_easy_flatpak/Domain/Entity/user_settings_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Entity/navigation_entity.dart';
import 'package:flutter/material.dart';

class ListviewApplicationListComponent extends StatelessWidget {
  final List<ApplicationEntity> applicationEntityList;
  final Function handleGoTo;
  final ScrollController handleScrollController;

  const ListviewApplicationListComponent(
      {super.key,
      required this.applicationEntityList,
      required this.handleGoTo,
      required this.handleScrollController});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: applicationEntityList.length,
        controller: handleScrollController,
        itemBuilder: (context, index) {
          ApplicationEntity appStreamLoop = applicationEntityList[index];

          return InkWell(
              borderRadius: BorderRadius.circular(8.0),
              onTap: () {
                NavigationEntity.gotToApplicationId(
                    handleGoTo: handleGoTo,
                    applicationId: appStreamLoop.id,
                    title: appStreamLoop.name);
              },
              child: Card(
                color: Theme.of(context).secondaryHeaderColor,
                child: Column(
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 10),
                        !appStreamLoop.hasAppIcon()
                            ? Image.asset('assets/images/no-image.png',
                                height: 50)
                            : Image.file(
                                height: 50,
                                File(
                                    '${UserSettingsEntity().getApplicationIconsPath()}/${appStreamLoop.getAppIcon()}')),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appStreamLoop.getName(),
                                style: TextStyle(
                                    fontSize: 24,
                                    color: Theme.of(context)
                                        .textTheme
                                        .headlineLarge!
                                        .color),
                              ),
                              Text(
                                appStreamLoop.getSummary(),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ));
        });
  }
}
