import 'package:dupot_easy_flatpak/Screens/app_detail.dart';
import 'package:flutter/material.dart';

import '../Screens/app_detail/app_detail_arguments.dart';

class AppButton extends StatelessWidget {
  final String title;

  const AppButton({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    var myText = Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 35,
      ),
    );

    const double margin = 35;

    return Card(
      // clipBehavior is necessary because, without it, the InkWell's animation
      // will extend beyond the rounded edges of the [Card] (see https://github.com/flutter/flutter/issues/109776)
      // This comes with a small performance cost, and you should not set [clipBehavior]
      // unless you need it.
      margin: EdgeInsets.all(15.0),

      clipBehavior: Clip.hardEdge,
      child: InkWell(
        splashColor: Colors.blue.withAlpha(30),
        onTap: () {
          Navigator.pushReplacementNamed(context, '/app',
              arguments: AppDetailArguments(title));
        },
        child: Container(
          padding: const EdgeInsets.only(
              left: margin, bottom: margin, right: margin, top: margin),
          child: myText,
        ),
      ),
    );

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
