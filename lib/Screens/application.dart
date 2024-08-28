import 'dart:io';

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
import 'package:flutter/widgets.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

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

  String appPath = '';

  void getData() async {
    appStreamFactory = AppStreamFactory();
    appPath = await appStreamFactory.getPath();

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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              (stateAppStream!.icon.length > 10)
                                  ? Image.file(File(appPath +
                                      '/' +
                                      stateAppStream!.getIcon()))
                                  : SizedBox(),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      stateAppStream!.name,
                                      style: const TextStyle(
                                          fontSize: 35,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    Text(
                                      stateAppStream!.developer_name,
                                      style: const TextStyle(
                                          fontStyle: FontStyle.italic),
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    stateAppStream!.isVerified()
                                        ? TextButton.icon(
                                            style: TextButton.styleFrom(
                                                padding: const EdgeInsets.only(
                                                    top: 5,
                                                    bottom: 5,
                                                    right: 5,
                                                    left: 0),
                                                alignment: AlignmentDirectional
                                                    .topStart),
                                            icon: Icon(Icons.verified),
                                            onPressed: () {},
                                            label: Text(stateAppStream!
                                                .getVerifiedLabel()))
                                        : SizedBox()
                                  ],
                                ),
                              ),
                              stateIsAlreadyInstalled
                                  ? UninstallButton(
                                      buttonStyle: buttonStyle,
                                      dialogButtonStyle: dialogButtonStyle,
                                      stateAppStream: stateAppStream)
                                  : InstallButton(
                                      buttonStyle: buttonStyle,
                                      dialogButtonStyle: dialogButtonStyle,
                                      stateAppStream: stateAppStream)
                            ],
                          ),
                          Padding(
                              padding: EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    stateAppStream!.summary,
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(
                                    height: 15,
                                  ),
                                  HtmlWidget(
                                    stateAppStream!.description,
                                  ),
                                ],
                              )),
                          ListTile(
                              title: Text(
                            'Links',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          )),
                          Padding(
                              padding: EdgeInsets.only(
                                  top: 5, bottom: 5, right: 5, left: 10),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: stateAppStream!
                                      .getUrlObjList()
                                      .map((urlObjLoop) {
                                    return TextButton.icon(
                                      icon:
                                          getIcon(urlObjLoop['key'].toString()),
                                      onPressed: () {},
                                      label:
                                          Text(urlObjLoop['value'].toString()),
                                    );
                                  }).toList()))
                        ],
                      ),
              ))
        ]));
  }

  Widget getIcon(String type) {
    if (type == 'homepage') {
      return Icon(Icons.home);
    } else if (type == 'bugtracker') {
      return Icon(Icons.bug_report);
    }
    return Icon(Icons.ac_unit);
  }
}
