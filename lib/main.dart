import 'dart:io';

import 'package:dupot_easy_flatpak/dupot_easy_flatpak.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

    runApp(DupotEasyFlatpak());
  } on Exception catch (e) {
    print('Exception::');
    print(e);
  }
}


/*
class DupotEasyFlatpak extends StatefulWidget {
  const DupotEasyFlatpak({super.key});

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
*/