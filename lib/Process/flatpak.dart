import 'dart:async';
import 'dart:io';

class Flatpak {
  Future<FlatpakApplication> isApplicationAlreadyInstalled(
      String applicationId) async {
    ProcessResult result =
        await Process.run('flatpak', ['info', applicationId]);

    stdout.write(result.stdout);

    var isAlreadyInstalled = false;

    if (result.stdout.toString().length > 2) {
      isAlreadyInstalled = true;
    }

    return FlatpakApplication(isAlreadyInstalled, result.stdout.toString());
  }

  Future<String> installApplicationThenOverrideList(
      String applicationId, List<List<String>> subProcessList) async {
    ProcessResult result =
        await Process.run('flatpak', ['install', '-y', applicationId]);

    stdout.write(result.stdout);
    stderr.write(result.stderr);

    for (List<String> argListLoop in subProcessList) {
      ProcessResult subResult = await Process.run('flatpak', argListLoop);
    }

    return result.stdout.toString();
  }
}

class FlatpakApplication {
  final bool isInstalled;
  final String flatpakOutput;

  FlatpakApplication(this.isInstalled, this.flatpakOutput);
}
