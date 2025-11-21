import 'package:dupot_easy_flatpak/Domain/Entity/bundle_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/bundle_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/localization_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Entity/navigation_entity.dart';
import 'package:flutter/material.dart';

class BundlesView extends StatefulWidget {
  final Function handleGoTo;
  final bool isMain;
  final String bundleId;

  const BundlesView(
      {super.key,
      required this.handleGoTo,
      required this.isMain,
      required this.bundleId});

  @override
  State<BundlesView> createState() => _BundlesViewState();
}

class _BundlesViewState extends State<BundlesView> {
  List<BundleEntity> stateBundleEntityList = [];

  Map<String, bool> stateCheckboxList = {};

  ScrollController scrollController = ScrollController();

  @override
  void initState() {
    loadData();

    super.initState();
  }

  Future<void> loadData() async {
    List<BundleEntity> bundleEntityList =
        await BundleApi().getBundleEntityList();

    setState(() {
      stateBundleEntityList = bundleEntityList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
        interactive: false,
        thumbVisibility: true,
        controller: scrollController,
        child: Column(children: [
          Expanded(
              child: ListView(
                  controller: scrollController,
                  children: stateBundleEntityList
                      .map((BundleEntity bundleEntity) => getLine(bundleEntity))
                      .toList()))
        ]));
  }

  Widget getLine(BundleEntity bundleEntity) {
    return Card(
        color: widget.bundleId == bundleEntity.name
            ? Theme.of(context).focusColor
            : Theme.of(context).cardColor,
        child: ListTile(
          // enabled: widget.isMain,
          onTap: () => NavigationEntity.goToBundleDetail(
              handleGoTo: widget.handleGoTo, bundleId: bundleEntity.name),
          title: Column(
            children: [
              Row(
                children: [
                  const SizedBox(width: 10),
                  Image.asset(height: 60, bundleEntity.icon),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          LocalizationApi().tr("bundle_${bundleEntity.name}"),
                          style: TextStyle(
                              fontSize: 26,
                              color: Theme.of(context)
                                  .textTheme
                                  .headlineLarge!
                                  .color),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ));
  }
}
