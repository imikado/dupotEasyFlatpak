import 'package:dupot_easy_flatpak/Models/permission.dart';

class Recipe {
  String id = '';
  List<Permission> flatpakPermissionToOverrideList = [];

  Recipe(String applicationId,
      List<Map<String, dynamic>> rawFlatpakPermissionToOverrideList) {
    id = applicationId;
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
