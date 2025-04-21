class PermissionOverridedEntity {
  final String type;
  final String? value;
  final String? subValueYesNo;

  static const constTypeFileSystem = 'filesystem';
  static const constTypeFileSystemNoPrompt = 'filesystem_noprompt';

  static const constTypeInstallYesNo = 'install_flatpak_yesno';

  PermissionOverridedEntity(this.type, [this.value, this.subValueYesNo]);

  PermissionOverridedEntity.fromJson(Map<String, dynamic> json)
      : type = json['type'] as String,
        value = json['value'] as String,
        subValueYesNo = json['subValueYesNo'];

  bool isFileSystem() {
    return (type == constTypeFileSystem);
  }

  bool isFileSystemNoPrompt() {
    return (type == constTypeFileSystemNoPrompt);
  }

  bool isInstallFlatpakYesNo() {
    return (type == constTypeInstallYesNo);
  }

  String getType() {
    return type;
  }

  String? getValue() {
    return value;
  }

  String? getSubValueYesNo() {
    return subValueYesNo;
  }

  String getFlatpakOverrideType() {
    if (isFileSystemNoPrompt()) {
      return getFlatpakParameter(constTypeFileSystem);
    }

    return getFlatpakParameter(type);
  }

  String getFlatpakParameter(String parameter) {
    return '--$parameter=';
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'value': value,
        'subValueYesNo': subValueYesNo,
      };
}
