class ApiCacheEntity {
  // ignore: non_constant_identifier_names
  final String id;
  // ignore: non_constant_identifier_names
  final String content;

  bool empty = false;

  ApiCacheEntity({
    // ignore: non_constant_identifier_names
    required this.id,
    // ignore: non_constant_identifier_names
    required this.content,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'content': content,
    };
  }

  void setEmpty() {
    empty = true;
  }

  bool isEmpty() {
    return empty;
  }

  // Implement toString to make it easier to see information about
  // each dog when using the print statement.
  @override
  String toString() {
    return 'ApiCacheEntity{id: $id, content: $content }';
  }
}
