import 'package:flutter/material.dart';

class AppMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppBar(title: const Text('AppBar Demo'), actions: <Widget>[
      IconButton(
        icon: const Icon(Icons.add_alert),
        tooltip: 'Show Snackbar',
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('This is a snackbar')));
        },
      ),
      IconButton(
        icon: const Icon(Icons.navigate_next),
        tooltip: 'Go to the next page',
        onPressed: () {
          Navigator.push(context, MaterialPageRoute<void>(
            builder: (BuildContext context) {
              return Scaffold(
                appBar: AppBar(
                  title: const Text('Next page'),
                ),
                body: const Center(
                  child: Text(
                    'This is the next page',
                    style: TextStyle(fontSize: 24),
                  ),
                ),
              );
            },
          ));
        },
      ),
    ]);
  }
}
