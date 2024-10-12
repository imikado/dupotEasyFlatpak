import 'dart:async';
import 'dart:io';

import 'package:dupot_easy_flatpak/Models/app_update.dart';
import 'package:dupot_easy_flatpak/Models/settings.dart';

class Commands {
  static const String flatpakCommand = 'flatpak';

  late Settings settingsObj;
  late String updatesAvailableOutput;
  List<AppUpdate> appUpdateAvailableList = [];
  List<String> dbApplicationIdList = [];

  static final Commands _singleton = Commands._internal();

  factory Commands([Settings? settingsObj]) {
    if (settingsObj != null) {
      _singleton.settingsObj = settingsObj;
    }
    return _singleton;
  }

  Commands._internal();

  bool isInsideFlatpak() {
    return settingsObj.useFlatpakSpawn();
  }

  Future<bool> missFlathubInFlatpak() async {
    ProcessResult result = await runProcessSync('flatpak', ['remotes']);
    if (result.stdout.toString().contains('flathub')) {
      return false;
    }
    return true;
  }

  void setDbApplicationIdList(List<String> dbApplicationIdList) {
    this.dbApplicationIdList = dbApplicationIdList;
  }

  int getNumberOfUpdates() {
    return appUpdateAvailableList.length;
  }

  List<AppUpdate> getAppUpdateAvailableList() {
    return appUpdateAvailableList;
  }

  List<String> getAppIdUpdateAvailableList() {
    List<String> appIdList = [];
    for (AppUpdate appUpdateLoop in appUpdateAvailableList) {
      appIdList.add(appUpdateLoop.id.toLowerCase());
    }
    return appIdList;
  }

  Future<String> updateFlatpak(String appId) async {
    ProcessResult result = await runProcess('flatpak', ['update', '-y', appId]);
    return result.stdout.toString();
  }

  Future<void> checkUpdates() async {
    ProcessResult result = await runProcess(
        'flatpak', ['remote-ls', '--updates', '--columns=application,version']);
    updatesAvailableOutput = result.stdout.toString();

    appUpdateAvailableList.clear();

    List<String> lineList = updatesAvailableOutput.split("\n");
    if (lineList.isNotEmpty) {
      //lineList.removeAt(0);
      for (String lineLoop in lineList) {
        if (RegExp(r'\t').hasMatch(lineLoop)) {
          List<String> lineLoopList = lineLoop.split("\t");

          if (dbApplicationIdList
              .contains(lineLoopList[0].toString().toLowerCase())) {
            appUpdateAvailableList
                .add(AppUpdate(lineLoopList[0], lineLoopList[1]));
          } else {
            print('not find ' + lineLoopList[0].toString().toLowerCase());
            print(dbApplicationIdList);
          }
        }
      }
    }
  }

  bool hasUpdateAvailableByAppId(String appId) {
    for (AppUpdate appUpdateAvailableLoop in appUpdateAvailableList) {
      if (appUpdateAvailableLoop.id == appId) {
        return true;
      }
    }
    return false;
  }

  String getAppUpdateVersionByAppId(String appId) {
    for (AppUpdate appUpdateAvailableLoop in appUpdateAvailableList) {
      if (appUpdateAvailableLoop.id == appId) {
        return appUpdateAvailableLoop.version;
      }
    }
    throw new Exception('Cannot find app version available for id: $appId');
  }

  Future<void> setupFlathub() async {
    await runProcessSync('flatpak', [
      'remote-add',
      '--if-not-exists',
      'flathub',
      'https://flathub.org/repo/flathub.flatpakrepo'
    ]);
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

  Future<List<String>> getInstalledApplicationList() async {
    ProcessResult result =
        await runProcessSync(flatpakCommand, ['list', '--columns=application']);

    String outputString = result.stdout;
    List<String> lineList = outputString.split('\n');
    return lineList;
  }

  Future<void> run(String applicationId) async {
    runProcess(flatpakCommand, ['run', applicationId]);
  }
}

class FlatpakApplication {
  final bool isInstalled;
  final String flatpakOutput;

  FlatpakApplication(this.isInstalled, this.flatpakOutput);
}
