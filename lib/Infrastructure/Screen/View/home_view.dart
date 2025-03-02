import 'package:dupot_easy_flatpak/Domain/Entity/db/application_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Control/Model/View/home_view_model.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SharedComponents/Group/block_app_list_component.dart';
import 'package:flutter/material.dart';

class HomeView extends StatefulWidget {
  final Function handleGoTo;

  const HomeView({super.key, required this.handleGoTo});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  List<List<ApplicationEntity>> stateAppStreamListList = [];
  List<String> stateCategoryIdList = [];
  String appPath = '';

  ScrollController scrollController = ScrollController();

  @override
  void initState() {
    loadData();

    super.initState();
  }

  Future<void> loadData() async {
    HomeViewModel homeViewModel = HomeViewModel();

    List<List<ApplicationEntity>> appStreamListList =
        await homeViewModel.getApplicationEntityList();

    List<String> categoryIdList = await homeViewModel.getCategoryIdList();

    setState(() {
      stateAppStreamListList = appStreamListList;
      stateCategoryIdList = categoryIdList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return stateAppStreamListList.isEmpty
        ? const LinearProgressIndicator()
        : Scrollbar(
            interactive: false,
            thumbVisibility: true,
            controller: scrollController,
            child: ListView.builder(
                itemCount: stateCategoryIdList.length,
                controller: scrollController,
                itemBuilder: (context, index) {
                  return BlockAppListComponent(
                      categoryId: stateCategoryIdList[index],
                      appStreamList: stateAppStreamListList[index],
                      appPath: appPath,
                      handleGoTo: widget.handleGoTo);
                }));
  }
}
