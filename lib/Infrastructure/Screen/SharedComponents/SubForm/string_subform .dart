import 'package:flutter/material.dart';

class StringSubform extends StatelessWidget {
  final String value;
  final Function handleUpdateValue;

  TextEditingController textControl = TextEditingController();

  StringSubform(
      {super.key, required this.value, required this.handleUpdateValue}) {
    textControl.text = value;
  }

  @override
  Widget build(BuildContext context) {
    return Column(spacing: 0, children: [
      SizedBox(width: 50),
      TextField(
        controller: textControl,
        onChanged: (String? value) {
          handleUpdateValue(value);
        },
      )
    ]);
  }
}
