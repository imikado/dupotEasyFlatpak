import 'dart:math';

import 'package:dupot_easy_flatpak/Domain/Entity/db/application_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/command_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/localization_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Entity/flatpak_history_entry.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SharedComponents/Button/dialog_cancel_button.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SharedComponents/Button/dialog_confirm_button.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SharedComponents/loading.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/Theme/theme_button_style.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DowngradeButton extends StatefulWidget {
  final ApplicationEntity applicationEntity;
  final bool isActive;
  final Function handle;
  final bool scopeUser;

  const DowngradeButton(
      {super.key,
      required this.applicationEntity,
      required this.handle,
      required this.isActive,
      required this.scopeUser});

  @override
  State<DowngradeButton> createState() => _DowngradeButtonState();
}

class _DowngradeButtonState extends State<DowngradeButton> {
  bool loaded = false;
  List<String> versionList = [];

  List<FlatpakHistoryEntry> stateFlatpakHistoryList = [];

  String? _selectedCommit;

  @override
  void initState() {
    super.initState();
    load();
  }

  void load() async {
    String currentCommit =
        await CommandApi().getCommitForApplication(widget.applicationEntity.id);

    List<FlatpakHistoryEntry> flatpakHistoryList = await CommandApi()
        .getPreviousVersionListByAppId(
            widget.scopeUser, widget.applicationEntity.id);
    if (!mounted) {
      return;
    }
    setState(() {
      stateFlatpakHistoryList = flatpakHistoryList;

      if (stateFlatpakHistoryList.isNotEmpty) {
        _selectedCommit = currentCommit;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ThemeButtonStyle themeButtonStyle = ThemeButtonStyle(context: context);

    if (stateFlatpakHistoryList.isEmpty) return LoadingComponent();

    return FilledButton.icon(
      style: themeButtonStyle.getButtonStyle(
          tagColor: ThemeButtonStyle.tagColorAccept),
      onPressed: !widget.isActive
          ? null
          : () {
              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return StatefulBuilder(
                        builder: (context, StateSetter setState) {
                      return AlertDialog(
                        buttonPadding: const EdgeInsets.all(10),
                        actions: [
                          const DialogCancelButton(),
                          DialogConfirmButton(onPressedFunction: () {
                            widget.handle(_selectedCommit, widget.scopeUser);

                            Navigator.of(context).pop();
                          })
                        ],
                        title: Text(
                            LocalizationApi().tr('downgrade_version_title')),
                        contentPadding: const EdgeInsets.all(20.0),
                        content: SizedBox(
                            //height: 350,
                            child: Column(
                          children: [
                            Row(
                              children: [
                                Text(
                                  '${LocalizationApi().tr('choose_version_to_downgrade')} ${widget.applicationEntity.getName()} ?',
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            SizedBox(
                                height: 500,
                                child: SingleChildScrollView(
                                    child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: stateFlatpakHistoryList
                                      .map(
                                        (FlatpakHistoryEntry
                                                flatpakHistoyLoop) =>
                                            RadioListTile<String>(
                                          value: flatpakHistoyLoop.commit,
                                          groupValue: _selectedCommit,
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedCommit = value;
                                            });
                                          },
                                          dense: true,
                                          title: Text(
                                            formatDate(flatpakHistoyLoop.date),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (flatpakHistoyLoop.subject !=
                                                  null)
                                                Text(flatpakHistoyLoop.subject!
                                                    .toString()),
                                              // show short commit (optional)
                                              Text(
                                                flatpakHistoyLoop.commit
                                                    .substring(
                                                        0,
                                                        min(
                                                            12,
                                                            flatpakHistoyLoop
                                                                .commit
                                                                .length)),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                      .toList(),
                                )))
                          ],
                        )),
                      );
                    });
                  });
            },
      label: Text(LocalizationApi().tr('downgrade'),
          style: themeButtonStyle.getButtonTextStyle()),
      icon: Icon(Icons.install_desktop,
          color: themeButtonStyle.getButtonTextStyle().color),
    );
  }

  String formatDate(String? datetimeString) {
    if (datetimeString == null) {
      return '';
    }

    return DateFormat("dd/MM/yyyy").format(
        DateFormat("yyyy-MM-dd").parse(datetimeString.substring(0, 10)));
  }
}
