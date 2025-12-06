// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'package:intl/intl.dart';

class ApplicationEntity {
  String id;
  late String name;
  late String summary;
  String httpIcon;

  List<String> categoryIdList = [];
  late String description = '';

  Map<String, dynamic> metadataObj = {};
  Map<String, dynamic> urlObj = {};
  List<dynamic> releaseObjList = [];
  int lastUpdate = 0;

  String developer_name;

  String projectLicense;

  List<dynamic> screenshotObjList = [];

  int lastReleaseTimestamp = 0;

  bool isAlreadyInstalled = false;
  bool hasRecipe = false;
  bool isOverrided = false;
  bool hasUpdate = false;

  bool isEmpty = false;

  bool isScopeUser = false;

  static ApplicationEntity generateEmpty() {
    ApplicationEntity appEmpty = ApplicationEntity(
        id: '',
        name: '',
        summary: '',
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
        lastReleaseTimestamp: 0);
    appEmpty.isEmpty = true;
    return appEmpty;
  }

  ApplicationEntity(
      {required this.id,
      required this.name,
      required this.summary,
      required this.httpIcon,
      required this.categoryIdList,
      required this.description,
      required this.metadataObj,
      required this.urlObj,
      required this.releaseObjList,
      required this.lastUpdate,
      required this.projectLicense,
      required this.developer_name,
      required this.screenshotObjList,
      required this.lastReleaseTimestamp});

  String getName() {
    return decodeText(name);
  }

  String getSummary() {
    return decodeText(summary);
  }

  String getDescription() {
    return decodeText(description);
  }

  String decodeText(String text) {
    return utf8.decode(text.codeUnits, allowMalformed: true);
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'summary': summary,
      'icon': httpIcon,
      'categoryIdList': jsonEncode(categoryIdList),
      'description': description,
      'metadataObj': jsonEncode(metadataObj),
      'urlObj': jsonEncode(urlObj),
      'releaseObjList': jsonEncode(releaseObjList),
      'lastUpdate': lastUpdate,
      'projectLicense': projectLicense,
      'developer_name': developer_name,
      'screenshotList': jsonEncode(screenshotObjList),
      'lastReleaseTimestamp': lastReleaseTimestamp
    };
  }

  // Implement toString to make it easier to see information about
  // each dog when using the print statement.
  @override
  String toString() {
    return 'AppStream{id: $id, name: $name, summary: $summary}';
  }

  bool isVerified() {
    if (metadataObj.containsKey('flathub_verified') &&
        metadataObj['flathub_verified']) {
      return true;
    }
    return false;
  }

  String formatMB(int value) {
    double mbValue = value / 1000000;
    if (mbValue < 1) {
      final f = NumberFormat("0.00");
      return f.format(mbValue).replaceAll('.00', '');
    }

    final f = NumberFormat("###.00");
    return f.format(mbValue).replaceAll('.00', '');
  }

  String getDownloadSize() {
    if (metadataObj.containsKey('download_size')) {
      return '${formatMB(metadataObj['download_size'])} MB';
    }
    return '-';
  }

  String getInstalledSize() {
    if (metadataObj.containsKey('installed_size')) {
      return '${formatMB(metadataObj['installed_size'])} MB';
    }
    return '-';
  }

  String getVerifiedLabel() {
    if (metadataObj.containsKey('flathub_verified_label')) {
      return metadataObj['flathub_verified_label'];
    }
    return ' ';
  }

  String getVerifiedUrl() {
    if (metadataObj.containsKey('flathub_verified_url')) {
      return metadataObj['flathub_verified_url'];
    }
    return '';
  }

  List<Map<String, dynamic>> getReleaseObjList() {
    List<Map<String, dynamic>> releaseMapList = [];

    int limit = 0;
    for (dynamic rawReleaseObjLoop in releaseObjList) {
      releaseMapList.add({
        'version': rawReleaseObjLoop['version'],
        'timestamp': rawReleaseObjLoop['timestamp']
      });

      limit++;
      if (limit > 6) break;
    }

    return releaseMapList;
  }

  String getLastVersionId() {
    for (dynamic rawReleaseObjLoop in releaseObjList) {
      return rawReleaseObjLoop['version'];
    }

    return '';
  }

  List<Map<String, String>> getUrlObjList() {
    List<Map<String, String>> urlObjList = [];

    List<String> keyList = [
      'homepage',
      'bugtracker',
      'vcs_browser',
      'contribute'
    ];

    for (String keyLoop in keyList) {
      if (urlObj.containsKey(keyLoop)) {
        urlObjList.add({'key': keyLoop, 'value': urlObj[keyLoop].toString()});
      }
    }

    return urlObjList;
  }

  bool hasAppIcon() {
    return httpIcon.length > 10;
  }

  String getAppIcon() {
    return '${id.toLowerCase()}.png';
  }

  bool lastUpdateIsOlderThan(int days) {
    if ((DateTime.now().millisecondsSinceEpoch - lastUpdate) >
        days * 86400000) {
      return true;
    }
    return false;
  }
}
