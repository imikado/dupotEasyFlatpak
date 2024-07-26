import 'package:flutter/material.dart';

import '../../Models/application.dart';

class AppDetailContentAlreadyInstalled extends StatelessWidget {
  const AppDetailContentAlreadyInstalled(
      {super.key, required this.application, required this.flatpakInfo});

  final Application application;
  final String flatpakInfo;

  final navTextColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    const TextStyle contentTitleStyle =
        TextStyle(color: Colors.blueGrey, fontSize: 28.0);

    const TextStyle contentValueStyle =
        TextStyle(color: Color.fromARGB(255, 85, 77, 77), fontSize: 20.0);

    const TextStyle strongTextStyle =
        TextStyle(color: Colors.blueGrey, fontSize: 24.0);

    const TextStyle detailContentValueStyle =
        TextStyle(color: Color.fromARGB(255, 85, 77, 77), fontSize: 16.0);

    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      const Text("Application", style: contentTitleStyle),
      Text(application.title, style: contentValueStyle),
      const SizedBox(height: 20),
      const Text("Détails", style: contentTitleStyle),
      RichText(
        overflow: TextOverflow.clip,
        textAlign: TextAlign.center,
        text: TextSpan(
          style: detailContentValueStyle,
          children: <TextSpan>[
            TextSpan(text: flatpakInfo),
          ],
        ),
      ),
      const SizedBox(height: 20),
      const Card(
          child: SizedBox(
        width: 250,
        height: 80,
        child: Center(child: Text('Déjà installée', style: strongTextStyle)),
      ))
    ]);
  }
}
