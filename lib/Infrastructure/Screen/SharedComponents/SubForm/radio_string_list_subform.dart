import 'package:dupot_easy_flatpak/Infrastructure/Api/localization_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Entity/radio_string_entity.dart';
import 'package:flutter/material.dart';

class RadioStringListSubform extends StatelessWidget {
  final List<RadioStringEntity> radioStringEntityList;
  final String value;
  final Function handleUpdateValue;

  const RadioStringListSubform(
      {super.key,
      required this.radioStringEntityList,
      required this.value,
      required this.handleUpdateValue});

  @override
  Widget build(BuildContext context) {
    return Column(
        spacing: 0,
        children: radioStringEntityList
            .map(
              (RadioStringEntity radioStringEntityLoop) => ListTile(
                visualDensity: VisualDensity(horizontal: 0, vertical: -4),
                titleTextStyle: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.headlineLarge!.color),
                title: Text(radioStringEntityLoop.translate
                    ? LocalizationApi().tr(radioStringEntityLoop.label)
                    : radioStringEntityLoop.label),
                leading: Radio<String>(
                  value: radioStringEntityLoop.value,
                  groupValue: value,
                  onChanged: (String? value) {
                    handleUpdateValue(radioStringEntityLoop.value);
                  },
                ),
              ),
            )
            .toList());
  }
}
