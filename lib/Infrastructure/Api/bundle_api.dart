import 'dart:convert';

import 'package:dupot_easy_flatpak/Domain/Entity/bundle_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/localization_api.dart';
import 'package:flutter/services.dart';

class BundleApi {
  static bool isDebug = true;

  Future<List<BundleEntity>> getBundleEntityList() async {
    String bundlesString = await rootBundle.loadString("assets/bundles.json");
    Map<String, dynamic> rawBundleList =
        Map<String, dynamic>.from(json.decode(bundlesString));

    List<BundleEntity> bundleEntityList = [];

    rawBundleList.forEach((String bundleNameLoop, dynamic objLoop) {
      bundleEntityList.add(BundleEntity(bundleNameLoop, objLoop['icon'],
          List<String>.from(objLoop['applicationList'] as List)));
    });

    return bundleEntityList;
  }
}
