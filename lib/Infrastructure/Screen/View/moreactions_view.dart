import 'package:dupot_easy_flatpak/Infrastructure/Api/localization_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Entity/navigation_entity.dart';
import 'package:flutter/material.dart';

class MoreActionsView extends StatefulWidget {
  final Function handleGoTo;

  const MoreActionsView({super.key, required this.handleGoTo});

  @override
  State<MoreActionsView> createState() => _MoreActionsViewState();
}

class _MoreActionsViewState extends State<MoreActionsView> {
  ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  Widget getLine(Function functionToCall, IconData actionIcon, String label,
      String summary) {
    return InkWell(
        borderRadius: BorderRadius.circular(8.0),
        onTap: () => functionToCall(),
        child: Card(
          color: Theme.of(context).secondaryHeaderColor,
          child: Column(
            children: [
              Row(
                children: [
                  const SizedBox(width: 10),
                  Icon(actionIcon),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                              fontSize: 24,
                              color: Theme.of(context)
                                  .textTheme
                                  .headlineLarge!
                                  .color),
                        ),
                        Text(
                          summary,
                        )
                      ],
                    ),
                  )
                ],
              ),
            ],
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
        interactive: false,
        thumbVisibility: true,
        controller: scrollController,
        child: ListView(controller: scrollController, children: [
          getLine(() {
            return NavigationEntity.goToMoreExport(
                handleGoTo: widget.handleGoTo);
          }, Icons.upload, LocalizationApi().tr('Export'),
              LocalizationApi().tr('Export_installed_apps')),
          getLine(() {
            return NavigationEntity.goToMoreImport(
                handleGoTo: widget.handleGoTo);
          }, Icons.download, LocalizationApi().tr('Import'),
              LocalizationApi().tr('Import_installed_apps_from_json'))
        ]));
  }
}
