import 'dart:io';

import 'package:dupot_easy_flatpak/Localizations/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class NewApp extends StatefulWidget {
  const NewApp({
    super.key,
  });

  @override
  State<StatefulWidget> createState() {
    return _NewApp();
  }
}

class _NewApp extends State<NewApp> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _applicationNameController =
      TextEditingController();
  final TextEditingController _applicationJsonController =
      TextEditingController();

  Future<void> writeApplication(
      String applicationName, String applicationJsonText) async {
    final directory = await getApplicationDocumentsDirectory();

    final subDirectory = Directory('${directory.path}/EasyFlatpak');
    if (await subDirectory.exists() == false) {
      await subDirectory.create(recursive: true);
    }
    final file = File('${directory.path}/EasyFlatpak/$applicationName.json');
    file.writeAsString(applicationJsonText);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.grey[200],
        appBar: AppBar(
          leading: IconButton(
            onPressed: () {
              Navigator.popAndPushNamed(context, '/home');
            },
            icon: const Icon(
              Icons.home,
              color: Colors.white,
            ),
          ),
          title: Text(
            AppLocalizations.of(context).tr("add_new_application"),
            style: const TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: Colors.blueGrey,
        ),
        body: SingleChildScrollView(
          child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25.0),
              child: Form(
                  key: _formKey,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        TextFormField(
                          controller: _applicationNameController,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            hintText: AppLocalizations.of(context)
                                .tr("application_name"),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.of(context)
                                  .tr("field_should_not_be_empty");
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          keyboardType: TextInputType.multiline,
                          minLines: 5, //Normal textInputField will be displayed
                          maxLines: 20,
                          controller: _applicationJsonController,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            hintText: AppLocalizations.of(context)
                                .tr("application_json"),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.of(context)
                                  .tr("field_should_not_be_empty");
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        FilledButton(
                          onPressed: () {
                            // Validate returns true if the form is valid, or false otherwise.
                            if (_formKey.currentState!.validate()) {
                              print(_applicationNameController.text);

                              writeApplication(_applicationNameController.text,
                                  _applicationJsonController.text);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(AppLocalizations.of(context)
                                        .tr("processing_form"))),
                              );
                            }
                          },
                          child: Text(AppLocalizations.of(context).tr("save")),
                        ),
                      ]))),
        ));
  }
}
