class AppLocalizations {
  static final AppLocalizations _singleton = AppLocalizations._internal();

  factory AppLocalizations({String newLanguageCode = ''}) {
    if (newLanguageCode.isNotEmpty) {
      _singleton.languageCode = newLanguageCode;
    }
    return _singleton;
  }

  void setLanguageCode(String newLanguageCode) {
    _singleton.languageCode = newLanguageCode;
  }

  AppLocalizations._internal();

  String languageCode = 'en';

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
      'License': 'License',
      'InstalledApps': 'Installed applications',
      'Run': 'Run',
      'By': 'By',
      'English': 'English',
      'French': 'French',
      'Language': 'Language',
      'Italian': 'Italian',
      'More': 'More...',
      'Updates': 'Updates availables',
      'NoUpdates': 'No updates availables',
      'Update': 'Update',
      'update_finished': 'Update finished'
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
      'save': 'Sauvegarder',
      'close': 'Fermer',
      'Search': 'Chercher',
      'Home': 'Accueil',
      'AudioVideo': 'Audio / Vidéo',
      'Development': 'Dévelopment',
      'Education': 'Education',
      'Game': 'Jeux',
      'Graphics': 'Graphisme',
      'Network': 'Réseau',
      'Office': 'Bureautique',
      'Science': 'Sciences',
      'System': 'Système',
      'Utility': 'Outils',
      'Search...': 'Recherche...',
      'Author': 'Auteur',
      'Website': 'Site',
      'License': 'Licence',
      'InstalledApps': 'Aplications installées',
      'Run': 'Ouvrir',
      'By': 'Par',
      'English': 'Anglais',
      'French': 'Français',
      'Language': 'Langage',
      'Italian': 'Italien',
      'More': 'Plus...',
      'Updates': 'Mises à jour',
      'NoUpdates': 'Aucune mise à jour',
      'Update': 'Mettre à jour',
      'update_finished': 'Mise à jour terminée'
    },
    'it': {
      'loading': 'Caricamento',
      'applications_available': 'Applicazioni disponibili',
      'installation_finished': 'Installazioni completate',
      'installation_successfully': 'Installazione completata con successo',
      'uninstallation_finished': 'Disinstallazione completata',
      'uninstallation_successfully': 'Disinstallazione riuscita',
      'details': 'Dettagli',
      'installation_already_installed': 'Già installato',
      'installing': "Installazione in corso...",
      'cancel': 'Annulla',
      'confirm': 'Conferma',
      'confirmation_title': 'Confermare',
      'do_you_confirm_installation_of': 'Confermi l\'installazione di ',
      'do_you_confirm_uninstallation_of': 'Confermi la disinstallazione di',
      'install': 'Installa',
      'install_with_recipe': 'Installa con ricetta',
      'uninstall': 'Disinstalla',
      'application': 'Applicazione',
      'applications': 'Applicazioni',
      'description': 'Descrizione',
      'output': 'Output',
      'add_new_application': 'Aggiungi nuova applicazione',
      'add': 'Aggiungi',
      'field_should_not_be_empty': 'Il campo deve essere compilato',
      'application_name': 'Nome dell\'applicazione',
      'application_json': 'Ricetta di installazione dell\'applicazione json',
      'processing_form': 'Elaborazione',
      'save': 'Salva',
      'close': 'chiudi',
      'Search': 'Cerca',
      'Home': 'Home',
      'AudioVideo': 'Audio / Video',
      'Development': 'Sviluppo',
      'Education': 'Istruzione',
      'Game': 'Gioco',
      'Graphics': 'Grafica',
      'Network': 'Rete',
      'Office': 'Ufficio',
      'Science': 'Scienza',
      'System': 'Sistema',
      'Utility': 'Utilità',
      'Search...': 'Cerca...',
      'Author': 'Autore',
      'Website': 'Sito Web',
      'License': 'Licenza',
      'InstalledApps': 'Applicazioni installate',
      'Run': 'Avvia',
      'By': 'Di',
      'English': 'Inglese',
      'French': 'Francese',
      'Language': 'Lingua',
      'Italian': 'Italiano',
      'More': 'Altro...',
      'Updates': 'Aggiornamenti',
      'NoUpdates': 'Nessun aggiornamento disponibile',
      'Update': 'Aggiornamento',
      'update_finished': 'Aggiornamento completato'
    }
  };

  static List<String> languages() => _localizedValues.keys.toList();

  String tr(String key) {
    if (!_localizedValues[languageCode]!.containsKey(key)) {
      throw Exception(
          'Missing localization for key: $key in language $languageCode');
    }
    return _localizedValues[languageCode]![key]!;
  }

  String getLanguageCode() {
    return languageCode;
  }
}
