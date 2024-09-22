class AppStreamCategory {
  final String appstream_id;
  final String category_id;

  AppStreamCategory({
    required this.appstream_id,
    required this.category_id,
  });

  Map<String, Object?> toMap() {
    return {
      'appstream_id': appstream_id,
      'category_id': category_id,
    };
  }

  // Implement toString to make it easier to see information about
  // each dog when using the print statement.
  @override
  String toString() {
    return 'AppStreamCategory{appstream_id: $appstream_id, category_id: $category_id }';
  }
}
