import 'dart:convert';
import 'dart:io';

import 'package:dupot_easy_flatpak/Domain/Entity/user_settings_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/command_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/localization_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Control/Model/SubView/override_control.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Entity/override_form_control.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SharedComponents/Button/close_subview_button.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SharedComponents/Card/card_output_component.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/Theme/theme_button_style.dart';
import 'package:flutter/material.dart';

class CartInstallAllSubview extends StatefulWidget {
  final Function handleGoToApplicationInstalled;
  final List<String> applicationIdListInCart;
  final Function handleRemoveFromCart;
  final Map<String, List<OverrideFormControl>> overrideSetupListByApplicationId;
  final Function handleSetApplicationLighted;

  //switch menu
  final Function handleDisableSideMenu;
  final Function handleEnableSideMenu;

  const CartInstallAllSubview(
      {super.key,
      required this.handleGoToApplicationInstalled,
      required this.applicationIdListInCart,
      required this.handleRemoveFromCart,
      required this.overrideSetupListByApplicationId,
      required this.handleSetApplicationLighted,
      required this.handleDisableSideMenu,
      required this.handleEnableSideMenu});

  @override
  State<CartInstallAllSubview> createState() =>
      _InstallationWithRecipeViewState();
}

class _InstallationWithRecipeViewState extends State<CartInstallAllSubview> {
  bool stateIsInstalling = false;
  bool stateDisplayInstallButton = true;
  String stateInstallationOutput = '';

  String appPath = '';

  final ScrollController scrollController = ScrollController();

  bool stateIsLoaded = true;

  @override
  void initState() {
    install();
    super.initState();
  }

  Future<void> install() async {
    await widget.handleDisableSideMenu();

    setState(() {
      stateIsInstalling = true;
    });

    OverrideControl overrideControl = OverrideControl();

    CommandApi command = CommandApi();
    String commandBin = 'flatpak';

    List<String> cartApplicationIdList =
        List<String>.from(widget.applicationIdListInCart);

    for (String applicationIdLoop in cartApplicationIdList) {
      await widget.handleSetApplicationLighted(applicationIdLoop);
      List<String> commandArgList = [
        'install',
        '-y',
        'flathub',
        UserSettingsEntity().getInstallationScope(),
        applicationIdLoop
      ];

      Process process = await Process.start(command.getCommand(commandBin),
          command.getFlatpakSpawnArgumentList(commandBin, commandArgList));

      process.stdout.transform(utf8.decoder).listen((data) {
        if (mounted) {
          setState(() {
            stateInstallationOutput = data;
          });
        }
      });

      await process.exitCode;

      if (widget.overrideSetupListByApplicationId
          .containsKey(applicationIdLoop)) {
        await overrideControl.save(applicationIdLoop,
            widget.overrideSetupListByApplicationId[applicationIdLoop]!);
      }

      await CommandApi().loadApplicationInstalledList();

      await widget.handleRemoveFromCart(applicationIdLoop);

      await widget.handleSetApplicationLighted('');
    }

    await widget.handleEnableSideMenu();

    setState(() {
      stateIsInstalling = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      interactive: false,
      thumbVisibility: true,
      controller: scrollController,
      child: ListView(
        controller: scrollController,
        children: [
          Wrap(
            alignment: WrapAlignment.end,
            children: [
              stateIsInstalling
                  ? const LinearProgressIndicator()
                  : CloseSubViewButton(
                      handle: widget.handleGoToApplicationInstalled),
              const SizedBox(width: 20)
            ],
          ),
          CardOutputComponent(outputString: stateInstallationOutput),
          const SizedBox(
            height: 10,
          ),
          if (!stateIsInstalling)
            Center(child: Text(LocalizationApi().tr('installation_finished')))
        ],
      ),
    );
  }

  Widget getInstallButton() {
    if (stateIsInstalling | !stateDisplayInstallButton) {
      return const SizedBox();
    }

    return FilledButton.icon(
      style: ThemeButtonStyle(context: context).getButtonStyle(),
      onPressed: () {
        install();
        setState(() {
          stateDisplayInstallButton = false;
        });
      },
      label: Text(LocalizationApi().tr('install')),
      icon: const Icon(Icons.install_desktop),
    );
  }
}
