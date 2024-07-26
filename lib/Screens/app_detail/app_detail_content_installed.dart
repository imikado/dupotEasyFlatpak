import 'package:flutter/material.dart';

import '../../Models/application.dart';

class AppDetailContentInstalled extends StatelessWidget {
  const AppDetailContentInstalled(
      {super.key, required this.application, required this.flatpakOutput});

  final Application application;
  final String flatpakOutput;

  final navTextColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    const TextStyle contentTitleStyle =
        TextStyle(color: Colors.blueGrey, fontSize: 28.0);

    const TextStyle contentValueStyle =
        TextStyle(color: Color.fromARGB(255, 85, 77, 77), fontSize: 20.0);

    const TextStyle strongTextStyle =
        TextStyle(color: Colors.blueGrey, fontSize: 24.0);

    const TextStyle outputTextStyle =
        TextStyle(color: Colors.blueGrey, fontSize: 14.0);

    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      const Text("Application", style: contentTitleStyle),
      Text(application.title, style: contentValueStyle),
      const SizedBox(height: 20),
      const Text("Description", style: contentTitleStyle),
      Text(application.description, style: contentValueStyle),
      const SizedBox(height: 40),
      const Text(
        'Déjà installée',
        style: strongTextStyle,
      ),
      RichText(
        overflow: TextOverflow.clip,
        text: TextSpan(
          text: 'Output ',
          style: outputTextStyle,
          children: <TextSpan>[
            TextSpan(text: flatpakOutput),
          ],
        ),
      )
    ]);
  }
}
