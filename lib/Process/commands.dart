import 'dart:async';
import 'dart:io';

import 'package:dupot_easy_flatpak/Models/settings.dart';

class Commands {
  static const String flatpakCommand = 'flatpak';

  late Settings settingsObj;

  Commands({required this.settingsObj});

  bool isInsideFlatpak() {
    return settingsObj.useFlatpakSpawn();
  }

  String getCommand(String command) {
    if (isInsideFlatpak()) {
      return settingsObj.getFlatpakSpawnCommand();
    }
    return command;
  }

  Future<ProcessResult> runProcess(
      String command, List<String> argumentList) async {
    return await Process.run(getCommand(command),
        getFlatpakSpawnArgumentList(command, argumentList));
  }

  Future<ProcessResult> runProcessSync(
      String command, List<String> argumentList) async {
    return Process.runSync(getCommand(command),
        getFlatpakSpawnArgumentList(command, argumentList));
  }

  List<String> getFlatpakSpawnArgumentList(
      String command, List<String> subArgumentList) {
    if (isInsideFlatpak()) {
      List<String> argumentList = [];
      argumentList.add('--host');
      argumentList.add(command);
      argumentList.add('--user');

      for (String subArgumentLoop in subArgumentList) {
        argumentList.add(subArgumentLoop);
      }
      return argumentList;
    }
    return subArgumentList;
  }

  Future<FlatpakApplication> isApplicationAlreadyInstalled(
      String applicationId) async {
    ProcessResult result =
        await runProcess(flatpakCommand, ['info', applicationId]);

    stdout.write(result.stdout);

    var isAlreadyInstalled = false;

    if (result.stdout.toString().length > 2) {
      isAlreadyInstalled = true;
    }

    return FlatpakApplication(isAlreadyInstalled, result.stdout.toString());
  }

  Future<String> installApplicationThenOverrideList(
      String applicationId, List<List<String>> subProcessList) async {
    ProcessResult result = await runProcess(
        flatpakCommand, ['install', '-y', '--system', applicationId]);

    stdout.write(result.stdout);
    stderr.write(result.stderr);

    for (List<String> argListLoop in subProcessList) {
      await runProcess(flatpakCommand, argListLoop);
    }

    return result.stdout.toString();
  }

  Future<String> uninstallApplicationThenOverrideList(
      String applicationId, List<List<String>> subProcessList) async {
    ProcessResult result = await runProcess(
        flatpakCommand, ['uninstall', '-y', '--system', applicationId]);

    stdout.write(result.stdout);
    stderr.write(result.stderr);

    return result.stdout.toString();
  }
}

class FlatpakApplication {
  final bool isInstalled;
  final String flatpakOutput;

  FlatpakApplication(this.isInstalled, this.flatpakOutput);
}
