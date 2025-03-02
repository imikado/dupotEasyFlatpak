import 'package:dupot_easy_flatpak/Infrastructure/Api/localization_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Entity/radio_bool_entity.dart';
import 'package:flutter/material.dart';

class RadioBoolListSubform extends StatelessWidget {
  final List<RadioBoolEntity> radioBoolEntityList;
  final bool radioGroupValue;
  final Function handleUpdateValue;

  const RadioBoolListSubform(
      {super.key,
      required this.radioBoolEntityList,
      required this.radioGroupValue,
      required this.handleUpdateValue});

  @override
  Widget build(BuildContext context) {
    return Column(
        children: radioBoolEntityList
            .map(
              (RadioBoolEntity radioBoolEntityLoop) => ListTile(
                visualDensity: VisualDensity(horizontal: 0, vertical: -4),
                titleTextStyle: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.headlineLarge!.color),
                title: Text(LocalizationApi().tr(radioBoolEntityLoop.label)),
                leading: Radio<bool>(
                  value: radioBoolEntityLoop.value,
                  groupValue: radioGroupValue,
                  onChanged: (bool? value) {
                    handleUpdateValue(value);
                  },
                ),
              ),
            )
            .toList());
  }
}
