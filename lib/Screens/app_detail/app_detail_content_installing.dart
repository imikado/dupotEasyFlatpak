import 'package:flutter/material.dart';

class AppDetailContentInstalling extends StatelessWidget {
  const AppDetailContentInstalling({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const TextStyle contentTitleStyle =
        TextStyle(color: Colors.blueGrey, fontSize: 28.0);

    return const Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text("Installation en cours ...", style: contentTitleStyle),
          SizedBox(height: 20),
          CircularProgressIndicator(
            semanticsLabel: 'Installation...',
          )
        ]);
  }
}
