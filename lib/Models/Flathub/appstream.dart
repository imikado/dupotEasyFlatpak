import 'dart:convert';

class AppStream {
  final String id;
  final String name;
  final String summary;
  final String icon;

  final List<String> categoryList;
  final String description;

  AppStream({
    required this.id,
    required this.name,
    required this.summary,
    required this.icon,
    required this.categoryList,
    required this.description,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'summary': summary,
      'icon': icon,
      'categoryList': jsonEncode(categoryList),
      'description': description,
    };
  }

  // Implement toString to make it easier to see information about
  // each dog when using the print statement.
  @override
  String toString() {
    return 'AppStream{id: $id, name: $name, summary: $summary}';
  }
}
