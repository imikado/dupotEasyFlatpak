import 'package:dupot_easy_flatpak/Localizations/app_localizations.dart';
import 'package:dupot_easy_flatpak/Models/Flathub/appstream_category.dart';
import 'package:dupot_easy_flatpak/Screens/Shared/app_button.dart';
import 'package:dupot_easy_flatpak/Models/Flathub/appstream.dart';
import 'package:dupot_easy_flatpak/Models/Flathub/appstream_factory.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class Block extends StatelessWidget {
  final String categoryId;
  final List<AppStream> appStreamList;
  final String appPath;
  final Function handleGoToApplication;

  const Block(
      {required this.categoryId,
      required this.appStreamList,
      required this.appPath,
      required this.handleGoToApplication});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Text(
          AppLocalizations.of(context).tr(categoryId),
          style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey),
        ),
        const SizedBox(height: 10),
        Wrap(
            children: appStreamList.map((appStreamLoop) {
          String icon = '';
          if (appStreamLoop.getIcon().length > 3) {
            icon = appPath + '/' + appStreamLoop.getIcon();
          }

          return Container(
              width: 200,
              height: 250,
              child: AppButton(
                  id: appStreamLoop.id,
                  title: appStreamLoop.name,
                  sumary: appStreamLoop.summary,
                  icon: icon,
                  handle: handleGoToApplication));
        }).toList()),
      ],
    );
  }
}
