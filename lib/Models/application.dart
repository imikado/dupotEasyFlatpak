import 'package:dupot_easy_flatpak/Models/permission.dart';

class Application {
  final String title;
  final String description;
  final String flatpak;
  List<Permission> flatpakPermissionToOverrideList = [];

  Application(String this.title, String this.description, String this.flatpak,
      List<Map<String, dynamic>> rawFlatpakPermissionToOverrideList) {
    for (Map<String, dynamic> rawPermissionLoop
        in rawFlatpakPermissionToOverrideList) {
      String value = "none";
      if (rawPermissionLoop.containsKey('value')) {
        value = rawPermissionLoop['value'];
      }

      flatpakPermissionToOverrideList.add(Permission(
          rawPermissionLoop['type'].toString(),
          rawPermissionLoop['label']!,
          value));
    }
  }

  List<Permission> getFlatpakPermissionToOverrideList() {
    return flatpakPermissionToOverrideList;
  }
}
