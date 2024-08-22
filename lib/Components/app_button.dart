import 'package:flutter/material.dart';

import '../Screens/app_detail/app_detail_arguments.dart';

class AppButton extends StatelessWidget {
  final String title;
  final String sumary;
  final String icon;

  const AppButton(
      {super.key,
      required this.title,
      required this.sumary,
      required this.icon});

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

    return Card(
        clipBehavior: Clip.hardEdge,
        child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          ListTile(
            leading: Icon(Icons.album),
            title: Text(title),
            subtitle: Text(sumary),
          ),
          Image.network(icon)
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
