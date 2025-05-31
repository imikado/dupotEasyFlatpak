import 'package:dupot_easy_flatpak/Domain/Entity/db/application_entity.dart';
import 'package:dupot_easy_flatpak/Domain/Entity/user_settings_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/command_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/localization_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Repository/application_repository.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SharedComponents/List/datatable_application_list_component.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SharedComponents/List/grid_application_list_component.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SharedComponents/List/listview_application_list_component.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/Theme/theme_button_style.dart';
import 'package:flutter/material.dart';

class InstalledApplicationsView extends StatefulWidget {
  final Function handleGoTo;
  const InstalledApplicationsView({
    super.key,
    required this.handleGoTo,
  });

  @override
  State<InstalledApplicationsView> createState() =>
      _InstalledApplicationsViewState();
}

class _InstalledApplicationsViewState extends State<InstalledApplicationsView> {
  List<ApplicationEntity> stateAppStreamList = [];

  String stateSearch = '';

  String lastCategoryIdSelected = '';

  final ScrollController scrollController = ScrollController();

  Set<AppDisplay> _segmentedButtonSelection = <AppDisplay>{
    UserSettingsEntity().getDisplayAppsMode()
  };
  @override
  void initState() {
    super.initState();

    loadData();
  }

  Future<void> loadData() async {
    CommandApi commands = CommandApi();

    List<String> installedApplicationIdList =
        await commands.getInstalledApplicationList();

    ApplicationRepository applicationRepository = ApplicationRepository();

    List<ApplicationEntity> applicationEntityList = await applicationRepository
        .findListApplicationEntityByIdList(installedApplicationIdList);

    setState(() {
      stateAppStreamList = applicationEntityList;
    });
  }

  @override
  Widget build(BuildContext context) {
    ThemeButtonStyle themeButtonStyle = ThemeButtonStyle(context: context);

    return Column(
      children: [
        Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(children: [
              Text(
                "${LocalizationApi().tr('Total')} : ${stateAppStreamList.length.toString()}",
                style: const TextStyle(fontSize: 18),
              ),
              const Expanded(child: SizedBox()),
              SegmentedButton<AppDisplay>(
                style: themeButtonStyle.getSegmentedButtonStyle(),

                // ToggleButtons above allows multiple or no selection.
                // Set `multiSelectionEnabled` and `emptySelectionAllowed` to true
                // to match the behavior of ToggleButtons.
                multiSelectionEnabled: false,
                emptySelectionAllowed: false,

                // Hide the selected icon to match the behavior of ToggleButtons.
                showSelectedIcon: true,
                // SegmentedButton uses a Set<T> to track its selection state.
                selected: _segmentedButtonSelection,
                // This callback updates the set of selected segment values.
                onSelectionChanged: (Set<AppDisplay> newSelection) {
                  UserSettingsEntity().setDisplayAppsMode(newSelection.first);
                  setState(() {
                    _segmentedButtonSelection = newSelection;
                  });
                },
                // SegmentedButton uses a List<ButtonSegment<T>> to build its children
                // instead of a List<Widget> like ToggleButtons.
                segments: appDisplayOptions.map<ButtonSegment<AppDisplay>>(
                    ((AppDisplay, IconData) shirt) {
                  return ButtonSegment<AppDisplay>(
                      value: shirt.$1, label: Icon(shirt.$2));
                }).toList(),
              ),
              const SizedBox(
                width: 10,
              )
            ])),
        Expanded(child: getContent())
      ],
    );
  }

  Widget getContent() {
    if (_segmentedButtonSelection.first == AppDisplay.grid) {
      return GridApplicationListComponent(
          applicationEntityList: stateAppStreamList,
          handleGoTo: widget.handleGoTo,
          handleScrollController: scrollController);
    }
    if (_segmentedButtonSelection.first == AppDisplay.list) {
      return ListviewApplicationListComponent(
          applicationEntityList: stateAppStreamList,
          handleGoTo: widget.handleGoTo,
          handleScrollController: scrollController);
    }

    return DatatableApplicationListComponent(
        applicationEntityList: stateAppStreamList,
        handleGoTo: widget.handleGoTo,
        handleScrollController: scrollController);
  }
}
