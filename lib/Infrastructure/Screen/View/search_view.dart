import 'package:dupot_easy_flatpak/Domain/Entity/db/application_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/localization_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Control/Model/View/search_view_model.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SharedComponents/Content/application_list_content.dart';
import 'package:flutter/material.dart';

class SearchView extends StatefulWidget {
  final Function handleGoTo;
  final String searched;

  const SearchView(
      {super.key, required this.handleGoTo, required this.searched});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  List<ApplicationEntity> stateAppStreamList = [];

  String stateSearch = '';

  String lastCategoryIdSelected = '';

  @override
  void initState() {
    super.initState();

    loadData();
  }

  @override
  void didUpdateWidget(SearchView oldWidget) {
    if (oldWidget.searched != widget.searched) {
      loadData();
    }
    super.didUpdateWidget(oldWidget);
  }

  Future<void> loadData() async {
    List<ApplicationEntity> applicationEntityList = await SearchViewModel()
        .getApplicationEntityListBySearch(widget.searched);
    setState(() {
      stateAppStreamList = applicationEntityList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(
          child: stateAppStreamList.isEmpty
              ? SizedBox(
                  child: Center(
                      child: Text(LocalizationApi()
                          .tr('No_result_corresponding_to_this_research'))),
                )
              : ApplicationListContent(
                  handleGoTo: widget.handleGoTo,
                  applicationEntityList: stateAppStreamList))
    ]);
  }
}
