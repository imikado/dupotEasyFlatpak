import 'dart:io';
import 'package:yaml/yaml.dart';

Future<void> main() async {
  // Lire pubspec.yaml
  final file = File('pubspec.yaml');
  if (!file.existsSync()) {
    throw Exception('pubspec.yaml introuvable');
  }

  final content = file.readAsStringSync();
  final yaml = loadYaml(content);

  // Récupérer la valeur du champ "version"
  final version = yaml['version'];
  if (version == null) {
    throw Exception('Champ "version" introuvable dans pubspec.yaml');
  }

  // Écrire dans assets/version.txt
  final outFile = File('lib/Domain/Entity/info_entity.dart');
  outFile.createSync(recursive: true);
  outFile.writeAsStringSync(
      "class InfoEntity {\n  String version='${version.toString()}';\n}");
}
