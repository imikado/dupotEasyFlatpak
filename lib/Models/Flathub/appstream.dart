import 'dart:convert';

class AppStream {
  final String id;
  final String name;
  final String summary;
  final String icon;

  List<String> categoryIdList = [];
  String description = '';

  Map<String, dynamic> metadataObj = {};
  Map<String, String> urlObj = {};
  List<Map<String, dynamic>> releaseObjList = [];
  int lastUpdate = 0;

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
      required this.projectLicense});

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
      'projectLicense': projectLicense
    };
  }

  // Implement toString to make it easier to see information about
  // each dog when using the print statement.
  @override
  String toString() {
    return 'AppStream{id: $id, name: $name, summary: $summary}';
  }
}
