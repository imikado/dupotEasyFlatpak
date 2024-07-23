class Permission {
  final String type;
  final String label;

  static const constTypeFileSystem = 'filesystem';

  Permission(String this.type, this.label);

  bool isFileSystem() {
    return (type == constTypeFileSystem);
  }

  String getType() {
    return type;
  }

  String getLabel() {
    return label;
  }

  String getFlatpakOverrideType() {
    return '--$type=';
  }
}
