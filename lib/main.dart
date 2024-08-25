import 'package:dupot_easy_flatpak/Localizations/app_localizations_delegate.dart';
import 'package:dupot_easy_flatpak/Models/Flathub/appstream_factory.dart';
import 'package:dupot_easy_flatpak/Process/flathub_api.dart';
import 'package:dupot_easy_flatpak/Screens/app_detail.dart';
import 'package:dupot_easy_flatpak/Screens/category.dart';
import 'package:dupot_easy_flatpak/Screens/home.dart';
import 'package:dupot_easy_flatpak/Screens/new_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  try {
    sqfliteFfiInit();

    databaseFactory = databaseFactoryFfi;

    final appStreamFactory = AppStreamFactory();
    await appStreamFactory.create();

    FlathubApi flathubApi = FlathubApi(appStreamFactory: appStreamFactory);
    //await flathubApi.load();

    print('end loaded');
  } on Exception catch (e) {
    print('Exception::');
    print(e);
  }

  runApp(const DupotEasyFlatpak());
}

class DupotEasyFlatpak extends StatefulWidget {
  const DupotEasyFlatpak({super.key});

  @override
  _DupotEasyFlatpakState createState() => _DupotEasyFlatpakState();
}

class _DupotEasyFlatpakState extends State<DupotEasyFlatpak> {
  String param = 'test';

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', ''),
          Locale('fr', ''),
        ],
        title: 'Easy Flatpak',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: false,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const Home(),
          //'/home': (context) => const AppList(),
          '/app': (context) => const AppDetail(),
          '/add': (context) => const NewApp(),
          '/category': (context) => Category()
        });
  }
}
