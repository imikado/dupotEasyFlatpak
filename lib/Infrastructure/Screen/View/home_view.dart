import 'package:dupot_easy_flatpak/Domain/Entity/db/application_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/localization_api.dart';
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
  List<String> stateCategoryIdList = [];
  String appPath = '';

  ScrollController scrollController = ScrollController();

  List<ApplicationEntity> stateUpdatedAppStreamList = [];
  List<ApplicationEntity> statePopularAppStreamList = [];
  List<ApplicationEntity> stateTrendingAppStreamList = [];

  @override
  void initState() {
    loadData();

    super.initState();
  }

  Future<void> loadData() async {
    HomeViewModel homeViewModel = HomeViewModel();

    List<ApplicationEntity> updatedApplicationList =
        await homeViewModel.getUpdatedApplicationEntityListFromApi();

    List<ApplicationEntity> popularApplicationList =
        await homeViewModel.getPopularApplicationEntityListFromApi();

    List<ApplicationEntity> trendingApplicationList =
        await homeViewModel.getTrendingApplicationEntityListFromApi();

    setState(() {
      stateUpdatedAppStreamList = updatedApplicationList;
      statePopularAppStreamList = popularApplicationList;
      stateTrendingAppStreamList = trendingApplicationList;
    });
  }

  Widget getWait(String title) {
    return Column(children: [
      const SizedBox(height: 12),
      Row(
        children: [
          SizedBox(
            width: 30,
          ),
          Text(
            LocalizationApi().tr(title),
            style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey),
          ),
        ],
      ),
      const SizedBox(height: 10),
      SizedBox(
        width: 100,
        height: 100,
        child: CircularProgressIndicator(),
      )
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
        interactive: false,
        thumbVisibility: true,
        controller: scrollController,
        scrollbarOrientation: ScrollbarOrientation.right,
        child: ListView(controller: scrollController, children: [
          stateTrendingAppStreamList.isEmpty
              ? getWait('home_trending')
              : BlockAppListComponent(
                  categoryId: 'home_trending',
                  appStreamList: stateTrendingAppStreamList,
                  appPath: appPath,
                  handleGoTo: widget.handleGoTo),
          stateUpdatedAppStreamList.isEmpty
              ? getWait('home_updated')
              : BlockAppListComponent(
                  categoryId: 'home_updated',
                  appStreamList: stateUpdatedAppStreamList,
                  appPath: appPath,
                  handleGoTo: widget.handleGoTo),
          statePopularAppStreamList.isEmpty
              ? getWait('home_popular')
              : BlockAppListComponent(
                  categoryId: 'home_popular',
                  appStreamList: statePopularAppStreamList,
                  appPath: appPath,
                  handleGoTo: widget.handleGoTo)
        ]));
  }
}
