import 'dart:io';

import 'package:dupot_easy_flatpak/Domain/Entity/db/application_entity.dart';
import 'package:dupot_easy_flatpak/Domain/Entity/user_settings_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/localization_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Entity/navigation_entity.dart';
import 'package:flutter/material.dart';

class DatatableApplicationListComponent extends StatefulWidget {
  final List<ApplicationEntity> applicationEntityList;
  final Function handleGoTo;
  final ScrollController handleScrollController;

  const DatatableApplicationListComponent(
      {super.key,
      required this.applicationEntityList,
      required this.handleGoTo,
      required this.handleScrollController});

  @override
  State<DatatableApplicationListComponent> createState() =>
      _DatatableApplicationListComponentState();
}

class _DatatableApplicationListComponentState
    extends State<DatatableApplicationListComponent> {
  List<ApplicationEntity> stateApplicationEntityList = [];
  bool stateSort = false;
  int stateColumnIndex = 1;
  List<DataRow> stateDataRowList = [];

  @override
  void initState() {
    super.initState();
    setState(() {
      stateApplicationEntityList = widget.applicationEntityList;
    });
    loadList();
  }

  @override
  void didUpdateWidget(covariant DatatableApplicationListComponent oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.applicationEntityList != oldWidget.applicationEntityList) {
      setState(() {
        stateApplicationEntityList = widget.applicationEntityList;
      });
      loadList();
    }
  }

  void loadList() {
    List<DataRow> dataRowList = [];
    for (ApplicationEntity applicationEntityLoop
        in stateApplicationEntityList) {
      dataRowList.add(DataRow(cells: <DataCell>[
        DataCell(
            !applicationEntityLoop.hasAppIcon()
                ? Image.asset('assets/images/no-image.png', height: 50)
                : Image.file(
                    height: 50,
                    File(
                        '${UserSettingsEntity().getApplicationIconsPath()}/${applicationEntityLoop.getAppIcon()}')),
            onTap: () => NavigationEntity.gotToApplicationId(
                handleGoTo: widget.handleGoTo,
                applicationId: applicationEntityLoop.id,
                title: applicationEntityLoop.name)),
        DataCell(Text(applicationEntityLoop.name),
            onTap: () => NavigationEntity.gotToApplicationId(
                handleGoTo: widget.handleGoTo,
                applicationId: applicationEntityLoop.id,
                title: applicationEntityLoop.name)),
        DataCell(Text(applicationEntityLoop.summary),
            onTap: () => NavigationEntity.gotToApplicationId(
                handleGoTo: widget.handleGoTo,
                applicationId: applicationEntityLoop.id,
                title: applicationEntityLoop.name)),
      ]));
    }
    setState(
      () => stateDataRowList = dataRowList,
    );
  }

  void sortBy(columnIndex, ascending) {
    setState(() {
      stateColumnIndex = columnIndex;
      if (columnIndex == 1) {
        stateApplicationEntityList.sort((a, b) => a.name.compareTo(b.name));
      }

      if (ascending) {
        stateApplicationEntityList =
            stateApplicationEntityList.reversed.toList();
      }
    });
    loadList();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        controller: widget.handleScrollController,
        child: DataTable(
            sortAscending: stateSort,
            sortColumnIndex: stateColumnIndex,
            columns: <DataColumn>[
              DataColumn(
                label: Expanded(
                  child: Text(
                    '',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              ),
              DataColumn(
                onSort: (columnIndex, ascending) {
                  setState(() {
                    stateSort = !stateSort;
                  });
                  sortBy(columnIndex, ascending);
                },
                label: Expanded(
                  child: Text(
                    LocalizationApi().tr('Name'),
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              ),
              DataColumn(
                label: Expanded(
                  child: Text(
                    LocalizationApi().tr('Description'),
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              ),
            ],
            rows: stateDataRowList));
  }
}
