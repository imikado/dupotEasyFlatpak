import 'dart:convert';
import 'package:path/path.dart' as p;

class AppStream {
  final String id;
  final String name;
  final String summary;
  final String icon;

  List<String> categoryIdList = [];
  String description = '';

  Map<String, dynamic> metadataObj = {};
  Map<String, dynamic> urlObj = {};
  List<Map<String, dynamic>> releaseObjList = [];
  int lastUpdate = 0;

  String developer_name;

  String projectLicense;

  AppStream(
      {required this.id,
      required this.name,
      required this.summary,
      required this.icon,
      required this.categoryIdList,
      required this.description,
      required this.metadataObj,
      required this.urlObj,
      required this.releaseObjList,
      required this.lastUpdate,
      required this.projectLicense,
      required this.developer_name});

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'summary': summary,
      'icon': icon,
      'categoryIdList': jsonEncode(categoryIdList),
      'description': description,
      'metadataObj': jsonEncode(metadataObj),
      'urlObj': jsonEncode(urlObj),
      'releaseObjList': jsonEncode(releaseObjList),
      'lastUpdate': lastUpdate,
      'projectLicense': projectLicense,
      'developer_name': developer_name
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
    print(metadataObj);
    return false;
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

  String getIcon() {
    return p.basename(icon);
  }

  bool lastUpdateIsOlderThan(int days) {
    if ((DateTime.now().millisecondsSinceEpoch - lastUpdate) >
        days * 86400000) {
      return true;
    }
    return false;
  }
}
