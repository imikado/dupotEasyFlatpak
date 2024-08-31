import 'dart:io';

import 'package:dupot_easy_flatpak/Localizations/app_localizations_delegate.dart';
import 'package:dupot_easy_flatpak/Models/Flathub/appstream_factory.dart';
import 'package:dupot_easy_flatpak/Models/settings.dart';
import 'package:dupot_easy_flatpak/Process/commands.dart';
import 'package:dupot_easy_flatpak/Process/first_installation.dart';
import 'package:dupot_easy_flatpak/Process/flathub_api.dart';
import 'package:dupot_easy_flatpak/Screens/application.dart';
import 'package:dupot_easy_flatpak/Screens/category.dart';
import 'package:dupot_easy_flatpak/Screens/home.dart';
import 'package:dupot_easy_flatpak/Screens/installation.dart';
import 'package:dupot_easy_flatpak/Screens/installation_with_recipe.dart';
import 'package:dupot_easy_flatpak/Screens/loading.dart';
import 'package:dupot_easy_flatpak/Screens/search.dart';
import 'package:dupot_easy_flatpak/Screens/uninstallation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path_provider/path_provider.dart';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;

void main() async {
  bool shouldInstall = false;

  try {
    WidgetsFlutterBinding.ensureInitialized();

    final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    String appDocumentsDirPath = appDocumentsDir.path;

    Directory documentsTargetDirectory =
        Directory(p.join(appDocumentsDirPath, "EasyFlatpak"));

    if (!documentsTargetDirectory.existsSync()) {
      print('missing app directory, install database');
      await documentsTargetDirectory.create();

      shouldInstall = true;
      final bytes = await rootBundle.load('assets/db/flathub_database.db');
      final targetFile =
          File('${documentsTargetDirectory.path}/flathub_database.db');
      await targetFile.writeAsBytes(bytes.buffer.asUint8List());
    } else {
      print('database already installed');
    }

    sqfliteFfiInit();

    databaseFactory = databaseFactoryFfi;

    runApp(DupotEasyFlatpak(shouldInstall: shouldInstall));
  } on Exception catch (e) {
    print('Exception::');
    print(e);
  }
}

class DupotEasyFlatpak extends StatefulWidget {
  final bool shouldInstall;

  const DupotEasyFlatpak({super.key, required this.shouldInstall});

  @override
  _DupotEasyFlatpakState createState() => _DupotEasyFlatpakState();
}

class _DupotEasyFlatpakState extends State<DupotEasyFlatpak> {
  String param = 'test';
  bool isLoaded = false;

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
          colorScheme: ColorScheme.fromSeed(
              seedColor: Color.fromARGB(255, 205, 230, 250)),
          useMaterial3: false,
        ),
        initialRoute: '/loading',
        routes: {
          '/loading': (context) => Loading(),
          '/': (context) => const Home(),
          //'/home': (context) => const AppList(),
          '/category': (context) => Category(),
          '/application': (context) => Application(),
          '/installation': (context) => Installation(),
          '/uninstallation': (context) => Uninstallation(),
          '/installationwithrecipe': (context) => InstallationWithRecipe(),
          '/search': (context) => Search()
        });
  }
}
