import 'package:dupot_easy_flatpak/Infrastructure/Api/localization_api.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutView extends StatelessWidget {
  final String version;

  const AboutView({super.key, required this.version});

  Widget getLine(
      {required BuildContext context,
      required String title,
      required Widget content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text(
            LocalizationApi().tr(title),
            style: TextStyle(
                color: Theme.of(context).textTheme.headlineLarge!.color),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(25, 0, 0, 0),
          child: content,
        ),
      ],
    );
  }

  Widget getSpace() {
    return const SizedBox(
      height: 10,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        getLine(
            context: context,
            title: 'Author',
            content: const Text(' Michael Bertocchi')),
        getSpace(),
        getLine(
          context: context,
          title: 'Website',
          content: TextButton(
            child: const Text('www.dupot.org'),
            onPressed: () {
              launchUrl(Uri.parse('https://www.dupot.org'));
            },
          ),
        ),
        getLine(
            context: context,
            title: 'License',
            content: const Text('LGPL-2.1')),
        getSpace(),
        getLine(context: context, title: 'Version', content: Text(version)),
        getSpace(),
      ],
    );
  }
}
