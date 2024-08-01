class Permission {
  final String type;
  final String label;
  final String? value;

  static const constTypeFileSystem = 'filesystem';
  static const constTypeFileSystemNoPrompt = 'filesystem_noprompt';

  Permission(this.type, this.label, [this.value]);

  bool isFileSystem() {
    return (type == constTypeFileSystem);
  }

  bool isFileSystemNoPrompt() {
    return (type == constTypeFileSystemNoPrompt);
  }

  String getType() {
    return type;
  }

  String getLabel() {
    return label;
  }

  String? getValue() {
    return value;
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
}
