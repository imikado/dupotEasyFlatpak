import 'package:flutter/material.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const _localizedValues = <String, Map<String, String>>{
    'en': {
      'loading': 'Loading',
      'applications_available': 'Applications availables',
      'installation_finished': 'Installation finished',
      'installation_successfully': 'Installation successfully',
      'details': 'Details',
      'installation_already_installed': 'Already installed',
      'installing': "Installing ...",
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'confirmation_title': 'Confirmation',
      'do_you_confirm_installation_of': 'Do you confirm installation of ',
      'install': 'Install',
      'application': 'Application',
      'applications': 'Applications',
      'description': 'Decription',
      'output': 'Output'
    },
    'fr': {
      'loading': 'Chargement',
      'applications_available': 'Applications disponibles',
      'installation_finished': 'Installation terminée',
      'installation_successfully': 'Installation avec succès',
      'details': 'Détails',
      'installation_already_installed': 'Déjà installée',
      'installing': "Installation en cours ...",
      'cancel': 'Annuler',
      'confirm': 'Confirmer',
      'confirmation_title': 'Confirmation',
      'do_you_confirm_installation_of': 'Confirmez-vous l \'installation de',
      'install': 'Installer',
      'application': 'Application',
      'applications': 'Applications',
      'description': 'Decription',
      'output': 'Sortie'
    },
  };

  static List<String> languages() => _localizedValues.keys.toList();

  String tr(String key) {
    return _localizedValues[locale.languageCode]![key]!;
  }
}
