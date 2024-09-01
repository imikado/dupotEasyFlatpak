import 'dart:io';

import 'package:dupot_easy_flatpak/Screens/Shared/Arguments/applicationIdArgument.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class AppButton extends StatelessWidget {
  final String id;
  final String title;
  final String sumary;
  final String icon;
  final Function handle;

  const AppButton(
      {super.key,
      required this.id,
      required this.title,
      required this.sumary,
      required this.icon,
      required this.handle});

  @override
  Widget build(BuildContext context) {
    var myText = Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 35,
      ),
    );

    const double margin = 50;

    if (icon.length > 10) {
      return Card(
          clipBehavior: Clip.hardEdge,
          child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
            ListTile(
              onTap: () {
                handle(id);
              },
              title: Text(
                title,
                style: TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(
              height: 5,
            ),
            Image.file(File(icon))
          ]));
    }

    return Card(
        clipBehavior: Clip.hardEdge,
        child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          ListTile(
            title: Text(title),
          )
        ]));

    /*
     return ElevatedButton(
      style: const ButtonStyle(
        backgroundColor: MaterialStatePropertyAll<Color>(Colors.green),
      ),
      child: Text(title),
      onPressed: () {
        Navigator.pushReplacementNamed(context, '/app',
            arguments: AppDetailArguments(title));
        // ...
      },
    );
    */
  }
}
