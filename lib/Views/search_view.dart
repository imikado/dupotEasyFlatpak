import 'dart:io';

import 'package:dupot_easy_flatpak/Models/Flathub/appstream.dart';
import 'package:dupot_easy_flatpak/Models/Flathub/appstream_factory.dart';
import 'package:flutter/material.dart';

class SearchView extends StatefulWidget {
  String categoryIdSelected;
  late Function handleGoToApplication;
  late String searched;
  SearchView(
      {super.key,
      required this.categoryIdSelected,
      required this.handleGoToApplication,
      required this.searched});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  List<AppStream> stateAppStreamList = [];
  String appPath = '';

  String stateSearch = '';

  String lastCategoryIdSelected = '';

  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    print('loaded ${widget.categoryIdSelected}');
    loadData();
  }

  Future<void> loadData() async {
    stateSearch = widget.searched;

    lastCategoryIdSelected = widget.categoryIdSelected;
    AppStreamFactory appStreamFactory = AppStreamFactory();
    appPath = await appStreamFactory.getPath();

    List<AppStream> appStreamList =
        await appStreamFactory.findListAppStreamBySearch(stateSearch);

    setState(() {
      stateAppStreamList = appStreamList;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (stateSearch != widget.searched) {
      loadData();
    }

    return Scrollbar(
        interactive: false,
        thumbVisibility: true,
        controller: scrollController,
        child: ListView.builder(
            itemCount: stateAppStreamList.length,
            controller: scrollController,
            itemBuilder: (context, index) {
              AppStream appStreamLoop = stateAppStreamList[index];

              String icon = appStreamLoop.icon;
              if (icon.length < 10) {
                return Card(
                  child: Column(
                    children: [
                      ListTile(title: Text(stateAppStreamList[index].id)),
                    ],
                  ),
                );
              } else {
                return InkWell(
                    borderRadius: BorderRadius.circular(12.0),
                    onTap: () {
                      widget.handleGoToApplication(appStreamLoop.id);
                    },
                    child: Card(
                      color: Theme.of(context).cardColor,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Image.file(
                                  File('$appPath/${appStreamLoop.getIcon()}')),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      appStreamLoop.name,
                                      style: TextStyle(
                                          fontSize: 32,
                                          color: Theme.of(context)
                                              .textTheme
                                              .headlineLarge!
                                              .color),
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    Text(
                                      appStreamLoop.summary,
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
            }));
  }
}
