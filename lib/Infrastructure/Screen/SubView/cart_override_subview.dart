import 'package:dupot_easy_flatpak/Domain/Entity/db/application_entity.dart';
import 'package:dupot_easy_flatpak/Domain/Entity/recipe/permission_entity.dart';
import 'package:dupot_easy_flatpak/Domain/Entity/recipe/permission_overrided_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/localization_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Control/Model/SubView/override_control.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Entity/override_form_control.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Repository/application_repository.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/SharedComponents/Button/close_subview_button.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Screen/Theme/theme_button_style.dart';
import 'package:flutter/material.dart';
import 'package:ini/ini.dart';

class CartOverrideSubview extends StatefulWidget {
  final String applicationId;
  final Function handleGoToCart;
  final Function handleSaveOverrideSetup;
  final List<OverrideFormControl> overrideSetupList;
  final List<PermissionOverridedEntity> importedPermissionOverridedList;

  const CartOverrideSubview(
      {super.key,
      required this.applicationId,
      required this.handleGoToCart,
      required this.handleSaveOverrideSetup,
      required this.overrideSetupList,
      required this.importedPermissionOverridedList});

  @override
  State<CartOverrideSubview> createState() => _CartOverrideSubviewState();
}

class _CartOverrideSubviewState extends State<CartOverrideSubview> {
  ApplicationEntity? stateApplicationEntity;
  bool stateIsLoaded = true;
  String stateInstallationOutput = '';

  bool stateIsInstalling = false;

  String applicationId = '';

  late PermissionEntity statePermission = PermissionEntity('', 'label');
  Config stateOverrideConfig = Config();

  String appPath = '';

  final ScrollController scrollController = ScrollController();

  List<OverrideFormControl> stateOverrideFormControlList = [];

  late OverrideControl overrideControl;

  @override
  void initState() {
    super.initState();
  }

  Future<void> loadData() async {
    applicationId = widget.applicationId;
    ApplicationRepository appStreamFactory = ApplicationRepository();

    ApplicationEntity appStream =
        await appStreamFactory.findApplicationEntityById(applicationId);

    await loadApplicationRecipeOverride(applicationId);

    setState(() {
      stateApplicationEntity = appStream;
    });
  }

  Future<void> loadApplicationRecipeOverride(String applicationId) async {
    overrideControl = OverrideControl();

    List<OverrideFormControl> overrideFormControlList = [];
    if (widget.overrideSetupList.isNotEmpty) {
      overrideFormControlList = widget.overrideSetupList;
    } else if (widget.importedPermissionOverridedList.isNotEmpty) {
      overrideFormControlList =
          await overrideControl.getOverrideControlWithImportedConfigList(
              applicationId, widget.importedPermissionOverridedList);
    } else {
      overrideFormControlList = await overrideControl
          .getOverrideControlWithoutConfigList(applicationId);
    }
    setState(() {
      stateOverrideFormControlList = overrideFormControlList;
      stateIsLoaded = false;
    });
  }

  @override
  @mustCallSuper
  void didChangeDependencies() {
    loadData();
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return stateApplicationEntity == null
        ? const LinearProgressIndicator()
        : Scrollbar(
            interactive: false,
            thumbVisibility: true,
            controller: scrollController,
            child: ListView(
              controller: scrollController,
              children: [
                Wrap(
                  alignment: WrapAlignment.end,
                  children: [
                    getSaveButton(),
                    const SizedBox(width: 20),
                    stateIsInstalling
                        ? const LinearProgressIndicator()
                        : CloseSubViewButton(handle: widget.handleGoToCart),
                    const SizedBox(width: 20)
                  ],
                ),
                Padding(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 800),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: stateOverrideFormControlList.map(
                                (OverrideFormControl
                                    stateOverrideFormControlLoop) {
                              if (stateOverrideFormControlLoop
                                  .isTypeFileSystem()) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(stateOverrideFormControlLoop.label,
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold)),
                                    TextField(
                                      controller: stateOverrideFormControlLoop
                                          .textEditingController,
                                    )
                                  ],
                                );
                              } else if (stateOverrideFormControlLoop
                                  .isTypeEnv()) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(stateOverrideFormControlLoop.label,
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold)),
                                    Row(
                                      children: [
                                        Switch(
                                          value: stateOverrideFormControlLoop
                                              .boolValue,
                                          onChanged: (bool value) {
                                            stateOverrideFormControlLoop
                                                .boolValue = value;

                                            List<OverrideFormControl>
                                                tmpOverrideFormControlList =
                                                stateOverrideFormControlList;

                                            setState(() {
                                              stateOverrideFormControlList =
                                                  tmpOverrideFormControlList;
                                            });
                                          },
                                        ),
                                        Text(LocalizationApi().tr('Yes'))
                                      ],
                                    )
                                  ],
                                );
                              }

                              return const SizedBox();
                            }).toList()),
                      ),
                    )),
              ],
            ),
          );
  }

  Widget getSaveButton() {
    ThemeButtonStyle themeButtonStyle = ThemeButtonStyle(context: context);

    return FilledButton.icon(
      style: ThemeButtonStyle(context: context).getButtonStyle(),
      onPressed: () async {
        setState(() {
          stateIsInstalling = true;
        });

        //MIKA
        widget.handleSaveOverrideSetup(
            widget.applicationId, stateOverrideFormControlList);
        //await overrideControl.save(
        //    widget.applicationId, stateOverrideFormControlList);

        final snackBar = SnackBar(
          content: Text(LocalizationApi().tr('successfully_saved')),
        );

        ScaffoldMessenger.of(context).showSnackBar(snackBar);

        setState(() {
          stateIsInstalling = false;
        });
      },
      label: Text(LocalizationApi().tr('save'),
          style: themeButtonStyle.getButtonTextStyle()),
      icon:
          Icon(Icons.save, color: themeButtonStyle.getButtonTextStyle().color),
    );
  }
}
