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
      'uninstallation_finished': 'Uninstallation finished',
      'uninstallation_successfully': 'Uninstallation successfully',
      'details': 'Details',
      'installation_already_installed': 'Already installed',
      'installing': "Installing ...",
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'confirmation_title': 'Confirmation',
      'do_you_confirm_installation_of': 'Do you confirm installation of ',
      'do_you_confirm_uninstallation_of': 'Do you confirm uninstallation of ',
      'install': 'Install',
      'install_with_recipe': 'Install with recipe',
      'uninstall': 'Uninstall',
      'application': 'Application',
      'applications': 'Applications',
      'description': 'Decription',
      'output': 'Output',
      'add_new_application': 'Add new application',
      'add': 'Add',
      'field_should_not_be_empty': 'Field should be filled',
      'application_name': 'Application\'s name',
      'application_json': 'Application\'s json setup recipie',
      'processing_form': 'Processing',
      'save': 'Save',
      'close': 'close',
      'Search': 'Search',
      'Home': 'Home',
      'AudioVideo': 'Audio / Video',
      'Development': 'Development',
      'Education': 'Education',
      'Game': 'Game',
      'Graphics': 'Graphics',
      'Network': 'Network',
      'Office': 'Office',
      'Science': 'Science',
      'System': 'System',
      'Utility': 'Utility',
      'Search...': 'Search...',
      'Author': 'Author',
      'Website': 'Website',
      'License': 'License'
    },
    'fr': {
      'loading': 'Chargement',
      'applications_available': 'Applications disponibles',
      'installation_finished': 'Installation terminée',
      'installation_successfully': 'Installation avec succès',
      'uninstallation_finished': 'Désinstallation terminée',
      'uninstallation_successfully': 'Désinstallation avec succès',
      'details': 'Détails',
      'installation_already_installed': 'Déjà installée',
      'installing': "Installation en cours ...",
      'cancel': 'Annuler',
      'confirm': 'Confirmer',
      'confirmation_title': 'Confirmation',
      'do_you_confirm_installation_of': 'Confirmez-vous l \'installation de',
      'do_you_confirm_uninstallation_of':
          'Confirmez-vous la désinstallation de',
      'install': 'Installer',
      'install_with_recipe': 'Installer avec recette',
      'uninstall': 'Désinstaller',
      'application': 'Application',
      'applications': 'Applications',
      'description': 'Decription',
      'output': 'Sortie',
      'add_new_application': 'Ajouter une application',
      'add': 'Ajouter',
      'field_should_not_be_empty': 'Le champ doit être rempli',
      'application_name': 'Nom de l\'application',
      'application_json':
          'Json de paramétrage de la recette pour l\'application',
      'processing_form': 'Traitement en cours',
      'save': 'Enregistrer',
      'Search': 'Recherche',
      'Home': 'Accueil',
      'close': 'Fermer',
      'Graphics': 'Graphisme',
      'Network': 'Réseau',
      'Office': 'Bureautique',
      'Science': 'Science',
      'System': 'Système',
      'Utility': 'Outils',
      'Search...': 'Recherche...',
      'Author': 'Auteur',
      'Website': 'Site',
      'License': 'Licence'
    },
  };

  static List<String> languages() => _localizedValues.keys.toList();

  String tr(String key) {
    return _localizedValues[locale.languageCode]![key]!;
  }

  String getLanguageCode() {
    return locale.languageCode;
  }
}
