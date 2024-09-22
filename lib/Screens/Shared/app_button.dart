import 'dart:io';

import 'package:flutter/material.dart';

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
    if (icon.length > 10) {
      return InkWell(
          borderRadius: BorderRadius.circular(12.0),
          onTap: () {
            handle(id);
          },
          child: Card(
              color: Theme.of(context).cardColor,
              clipBehavior: Clip.hardEdge,
              child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                ListTile(
                  title: Text(
                    title,
                    style: const TextStyle(fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Expanded(child: Image.file(File(icon)))
              ])));
    }

    return Card(
        color: Theme.of(context).cardColor,
        clipBehavior: Clip.hardEdge,
        child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          ListTile(
            title: Text(title),
          )
        ]));
  }
}
