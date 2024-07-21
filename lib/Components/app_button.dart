import 'package:dupot_easy_flatpak/Screens/app_detail.dart';
import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  const AppButton({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
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
  }
}
