import 'dart:convert';
import 'dart:io';
import 'package:dupot_easy_flatpak/Domain/Entity/db/application_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/command_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/localization_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/logger_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Entity/navigation_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Repository/application_repository.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SharedComponents/Button/install_button.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SharedComponents/Button/install_file_button.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SharedComponents/Button/uninstall_button.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SharedComponents/Card/card_output_component.dart';
import 'package:dupot_easy_flatpak/Infrastructure/application.dart';
import 'package:flutter/material.dart';

class InstallFlatpakFileView extends StatefulWidget {
  final Function handleGoTo;
  final String localFlatpakPathToInstall;
  final bool isMain;

  const InstallFlatpakFileView(
      {super.key,
      required this.handleGoTo,
      required this.localFlatpakPathToInstall,
      required this.isMain});

  @override
  State<StatefulWidget> createState() => _InstallFlatpakFileViewState();

  void goToInstallation(bool installUserScope, String applicationId) {
    NavigationEntity.goToFlatpakFileInstall(
        handleGoTo: handleGoTo,
        applicationId: applicationId,
        localApplicationFile: localFlatpakPathToInstall,
        installUserScope: installUserScope);
  }

  void goToUninstallation(
      String applicationId, bool willDeleteAppData, bool installUserScope) {
    NavigationEntity.goToApplicationUninstall(
        handleGoTo: handleGoTo,
        applicationId: applicationId,
        willDeleteAppData: willDeleteAppData,
        installUserScope: installUserScope);
  }
}

class _InstallFlatpakFileViewState extends State<InstallFlatpakFileView> {
  Map<String, Map<String, String>>? metadata;
  String? error;

  String stateAppId = '';
  bool stateIsInstalling = false;
  String stateInstallationOutput = '';

  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    try {
      final data =
          await _extractFlatpakMetadata(widget.localFlatpakPathToInstall);
      if (!mounted) return;

      List<String> applicationInstalledList =
          await CommandApi().getInstalledApplicationList();

      setState(() {
        metadata = data;
        stateAppId = getAppId(data);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    }
  }

  String getAppId(Map<String, Map<String, String>> metadata) {
    for (final s in metadata.entries) {
      for (final kv in s.value.entries) {
        if (['Application.name'].contains('${s.key}.${kv.key}')) {
          return kv.value;
        }
      }
    }
    throw Exception('Unable to find app.id in metadata');
  }

  @override
  Widget build(BuildContext context) {
    return metadata == null
        ? const LinearProgressIndicator()
        : Scrollbar(
            interactive: false,
            thumbVisibility: true,
            controller: scrollController,
            child: ListView(
              controller: scrollController,
              children: [
                Row(
                  children: [
                    Padding(
                        padding: const EdgeInsets.all(20),
                        child: Image.asset('assets/images/no-image.png',
                            height: 50)),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stateAppId,
                            style: const TextStyle(
                                fontSize: 35, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Text(
                            widget.localFlatpakPathToInstall,
                            style: const TextStyle(
                                fontStyle: FontStyle.italic, fontSize: 15),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                        ],
                      ),
                    ),
                    !widget.isMain
                        ? const SizedBox()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const SizedBox(
                                height: 2,
                              ),
                              const SizedBox(
                                height: 2,
                              ),
                              getInstallButton(),
                              const SizedBox(
                                height: 2,
                              ),
                              const SizedBox(
                                height: 2,
                              ),
                            ],
                          ),
                    const SizedBox(width: 20)
                  ],
                ),
                Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(LocalizationApi().tr('installFlatpakWithCaution'))
                      ],
                    )),
                ListTile(
                    title: Text(
                  LocalizationApi().tr('Infos'),
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.headlineLarge!.color),
                )),
                CardOutputComponent(outputString: buildMetaContent(metadata!))
              ],
            ));
  }

  Widget getInstallButton(/*bool isAlreadyInstalled*/) {
    /* if (isAlreadyInstalled) {
      return UninstallButton(
        applicationEntity: stateAppStream!,
        handle: widget.goToUninstallation,
        isActive: widget.isMain,
        scopeUser: stateAppStream!.isScopeUser,
      );
    }*/

    return InstallFileButton(
      appId: widget.localFlatpakPathToInstall,
      handle: widget.goToInstallation,
      isActive: widget.isMain,
    );
  }

  String buildMetaContent(
    Map<String, Map<String, String>> meta,
  ) {
    String content = '';

    for (final s in meta.entries) {
      for (final kv in s.value.entries) {
        // 'Context.filesystems'
        if (['Application.command', 'Build.built-extensions']
            .contains('${s.key}.${kv.key}')) {
          continue;
        }

        content += '${s.key}.${kv.key}: ${kv.value} \n\n';
      }
    }
    return content;
  }
}

Future<Map<String, Map<String, String>>> _extractFlatpakMetadata(
    String path) async {
  final fileObj = File(path);
  if (!await fileObj.exists()) throw Exception('File not found: $path');

  final f = await fileObj.open();
  try {
    // 1) Try known markers
    for (final marker in const ['smetadata', 'metadata']) {
      final parsed = await _scanForMarkerAndParse(f, latin1.encode(marker));
      if (parsed != null && parsed.isNotEmpty) return parsed;
    }

    // 2) Fallback: scan for ASCII “[Application]” header directly
    final appHeader = latin1.encode('[Application]');
    final parsed =
        await _scanForMarkerAndParse(f, appHeader, includeHeader: true);
    if (parsed != null && parsed.isNotEmpty) return parsed;

    throw Exception(
        'No metadata found (tried smetadata, metadata, and [Application] header).');
  } finally {
    await f.close();
  }
}

Future<Map<String, Map<String, String>>?> _scanForMarkerAndParse(
  RandomAccessFile file,
  List<int> markerBytes, {
  bool includeHeader = false,
}) async {
  const chunkSize = 1024 * 1024; // 1 MiB
  final fileLen = await file.length();
  int pos = 0;
  List<int> prevTail = const [];

  while (pos < fileLen) {
    final remaining = fileLen - pos;
    final readLen = remaining < chunkSize ? remaining : chunkSize;
    await file.setPosition(pos);
    final chunk = await file.read(readLen);

    final searchBuf = <int>[...prevTail, ...chunk];
    final idx = _indexOf(searchBuf, markerBytes);
    if (idx != -1) {
      final start = idx + (includeHeader ? 0 : markerBytes.length);
      final fromGlobal = (pos - prevTail.length) + start;

      // Read a safe slice (max 256 KiB) after the marker/header
      final cap = (fromGlobal + 256 * 1024 > fileLen)
          ? (fileLen - fromGlobal)
          : 256 * 1024;
      await file.setPosition(fromGlobal);
      final iniBytes = await file.read(cap);

      final iniText = latin1.decode(iniBytes, allowInvalid: true);
      final sliced = _sliceIniBlock(iniText);
      final parsed = _parseIniString(sliced);
      if (parsed.isNotEmpty) return parsed;
      // else continue scanning further chunks (rare)
    }

    final overlap = (markerBytes.length - 1).clamp(0, searchBuf.length);
    prevTail = searchBuf.sublist(searchBuf.length - overlap);
    pos += readLen;
  }
  return null;
}

int _indexOf(List<int> data, List<int> pattern) {
  if (pattern.isEmpty || data.length < pattern.length) return -1;
  for (int i = 0; i <= data.length - pattern.length; i++) {
    var ok = true;
    for (int j = 0; j < pattern.length; j++) {
      if (data[i + j] != pattern[j]) {
        ok = false;
        break;
      }
    }
    if (ok) return i;
  }
  return -1;
}

String _sliceIniBlock(String text) {
  final lines = const LineSplitter().convert(text);
  final buf = StringBuffer();
  bool started = false;

  bool looksIni(String s) {
    if (s.isEmpty) return true;
    if (s.startsWith('[') && s.endsWith(']')) return true; // [Section]
    final eq = s.indexOf('=');
    return eq > 0 && eq < s.length - 1; // key=value
  }

  for (final raw in lines) {
    final line = raw.trimRight();
    if (!started && line.startsWith('[Application]')) {
      started = true;
      buf.writeln(line);
      continue;
    }
    if (started) {
      if (looksIni(line))
        buf.writeln(line);
      else
        break;
    }
  }

  // If we didn’t see [Application], try a generic INI-looking slice
  if (buf.isEmpty) {
    bool begun = false;
    for (final raw in lines) {
      final line = raw.trimRight();
      final ini = line.isEmpty ||
          (line.startsWith('[') && line.endsWith(']')) ||
          line.contains('=');
      if (!begun && ini) begun = true;
      if (begun) {
        if (ini)
          buf.writeln(line);
        else
          break;
      }
    }
  }

  return buf.toString().trimRight();
}

Map<String, Map<String, String>> _parseIniString(String content) {
  final sections = <String, Map<String, String>>{};
  String current = 'Application';
  sections[current] = {};

  for (final raw in content.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    if (line.startsWith('#') || line.startsWith(';')) continue;

    if (line.startsWith('[') && line.endsWith(']')) {
      current = line.substring(1, line.length - 1).trim();
      sections.putIfAbsent(current, () => {});
      continue;
    }

    final eq = line.indexOf('=');
    if (eq > 0) {
      final k = line.substring(0, eq).trim();
      final v = line.substring(eq + 1).trim();
      if (k.isNotEmpty) {
        sections.putIfAbsent(current, () => {});
        sections[current]![k] = v;
      }
    }
  }

  if (sections['Application']?.isEmpty == true) {
    sections.remove('Application');
  }
  return sections;
}
