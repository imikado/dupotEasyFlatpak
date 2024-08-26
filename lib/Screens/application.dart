import 'package:dupot_easy_flatpak/Process/flatpak.dart';
import 'package:dupot_easy_flatpak/Screens/Shared/Arguments/applicationIdArgument.dart';
import 'package:dupot_easy_flatpak/Screens/Shared/Arguments/categoryIdArgument.dart';
import 'package:dupot_easy_flatpak/Screens/Shared/menu_item.dart';
import 'package:dupot_easy_flatpak/Screens/Shared/sidemenu.dart';
import 'package:dupot_easy_flatpak/Localizations/app_localizations.dart';
import 'package:dupot_easy_flatpak/Models/Flathub/appstream.dart';
import 'package:dupot_easy_flatpak/Models/Flathub/appstream_factory.dart';
import 'package:dupot_easy_flatpak/Screens/Store/install_button.dart';
import 'package:dupot_easy_flatpak/Screens/Store/uninstall_button.dart';
import 'package:flutter/material.dart';

class Application extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _Application();
}

class _Application extends State<Application> {
  late AppStreamFactory appStreamFactory;
  List<String> stateCategoryIdList = [];
  AppStream? stateAppStream;
  List<MenuItem> stateMenuItemList = [];
  final ScrollController scrollController = ScrollController();

  bool stateIsAlreadyInstalled = false;

  String categorySelected = 'aa';
  String applicationId = '';

  bool stateIsLoaded = false;

  void getData() async {
    appStreamFactory = AppStreamFactory();

    List<String> categoryIdList = await appStreamFactory.findAllCategoryList();

    List<MenuItem> menuItemList = [
      MenuItem('Home', () {
        Navigator.popAndPushNamed(context, '/');
      })
    ];

    for (String categoryIdLoop in categoryIdList) {
      menuItemList.add(MenuItem(categoryIdLoop, () {
        Navigator.popAndPushNamed(context, '/category',
            arguments: CategoryIdArgment(categoryIdLoop));
      }));
    }

    AppStream appStream =
        await appStreamFactory.findAppStreamById(applicationId);

    checkAlreadyInstalled(applicationId);

    setState(() {
      stateCategoryIdList = categoryIdList;
      stateAppStream = appStream;
      stateMenuItemList = menuItemList;
      stateIsLoaded = true;
    });
  }

  void checkAlreadyInstalled(String applicationId) {
    Flatpak()
        .isApplicationAlreadyInstalled(applicationId)
        .then((flatpakApplication) {
      setState(() {
        stateIsAlreadyInstalled = flatpakApplication.isInstalled;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!stateIsLoaded) {
      ApplicationIdArgment args =
          ModalRoute.of(context)?.settings.arguments as ApplicationIdArgment;

      applicationId = args.applicationId;

      getData();
    }

    final ButtonStyle buttonStyle = ElevatedButton.styleFrom(
        backgroundColor: Colors.blueGrey,
        padding: const EdgeInsets.all(20),
        textStyle: const TextStyle(fontSize: 14));

    final ButtonStyle dialogButtonStyle = FilledButton.styleFrom(
        backgroundColor: Colors.grey,
        padding: const EdgeInsets.all(20),
        textStyle: const TextStyle(fontSize: 14));

    return Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.grey[200],
        body: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
              width: 240,
              child: SideMenu(
                menuItemList: stateMenuItemList,
                selected: categorySelected,
              )),
          Container(
              width: 950,
              child: Card(
                child: stateAppStream == null
                    ? CircularProgressIndicator()
                    : Column(
                        children: [
                          Row(
                            children: [
                              (stateAppStream!.icon.length > 10)
                                  ? Image.network(stateAppStream!.icon)
                                  : SizedBox(),
                              SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      stateAppStream!.name,
                                      style: TextStyle(fontSize: 30),
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Text(
                                      stateAppStream!.summary,
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    stateIsAlreadyInstalled
                                        ? UninstallButton(
                                            buttonStyle: buttonStyle,
                                            dialogButtonStyle:
                                                dialogButtonStyle,
                                            stateAppStream: stateAppStream)
                                        : InstallButton(
                                            buttonStyle: buttonStyle,
                                            dialogButtonStyle:
                                                dialogButtonStyle,
                                            stateAppStream: stateAppStream)
                                  ],
                                ),
                              )
                            ],
                          ),
                        ],
                      ),
              ))
        ]));
  }
}
