import 'package:dupot_easy_flatpak/Screens/app_detail.dart';
import 'package:dupot_easy_flatpak/Screens/app_list.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const DupotEasyFlatpak());
}

class DupotEasyFlatpak extends StatefulWidget {
  const DupotEasyFlatpak({super.key});

  @override
  _DupotEasyFlatpakState createState() => _DupotEasyFlatpakState();
}

class _DupotEasyFlatpakState extends State<DupotEasyFlatpak> {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Easy Flatpak',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: false,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const AppList(),
          '/home': (context) => const AppList(),
          '/app': (context) => const AppDetail(),
        });
  }
}
