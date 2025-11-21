class InfoEntity {
  late String version = '';

  static final InfoEntity _singleton = InfoEntity._internal();

  factory InfoEntity([String? newVersion]) {
    if (newVersion != null) {
      _singleton.version = newVersion;
    }
    return _singleton;
  }

  String getVersion() {
    return version;
  }

  InfoEntity._internal();
}
