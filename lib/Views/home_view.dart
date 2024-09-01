import 'package:dupot_easy_flatpak/Models/Flathub/appstream.dart';
import 'package:dupot_easy_flatpak/Models/Flathub/appstream_factory.dart';
import 'package:dupot_easy_flatpak/Screens/Store/block.dart';
import 'package:flutter/material.dart';

class HomeView extends StatefulWidget {
  final Function handleGoToApplication;
  const HomeView({super.key, required this.handleGoToApplication});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  List<List<AppStream>> stateAppStreamListList = [];
  List<String> stateCategoryIdList = [];
  String appPath = '';

  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    loadData();
  }

  Future<void> loadData() async {
    AppStreamFactory appStreamFactory = AppStreamFactory();
    appPath = await appStreamFactory.getPath();

    List<String> categoryIdList = await appStreamFactory.findAllCategoryList();

    List<List<AppStream>> appStreamListList = [];

    for (String categoryIdLoop in categoryIdList) {
      List<AppStream> appStreamList = await appStreamFactory
          .findListAppStreamByCategoryLimited(categoryIdLoop, 8);

      appStreamListList.add(appStreamList);
    }

    setState(() {
      stateAppStreamListList = appStreamListList;
      stateCategoryIdList = categoryIdList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
        interactive: false,
        thumbVisibility: true,
        controller: scrollController,
        child: ListView.builder(
            itemCount: stateCategoryIdList.length,
            controller: scrollController,
            itemBuilder: (context, index) {
              return Block(
                categoryId: stateCategoryIdList[index],
                appStreamList: stateAppStreamListList[index],
                appPath: appPath,
                handleGoToApplication: widget.handleGoToApplication,
              );
            }));
  }
}
