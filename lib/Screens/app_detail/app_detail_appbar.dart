import 'package:dupot_easy_flatpak/Localizations/app_localizations.dart';
import 'package:flutter/material.dart';
import 'app_detail_arguments.dart';

class AppDetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppDetailAppBar({super.key, required this.args});

  final AppDetailArguments args;

  @override
  Widget build(BuildContext context) {
    const Color navTextColor = Colors.white;

    const TextStyle navTextStyle = TextStyle(color: navTextColor);

    return AppBar(
      leading: IconButton(
        onPressed: () {
          Navigator.popAndPushNamed(context, '/home');
        },
        icon: const Icon(
          Icons.home,
          color: navTextColor,
        ),
      ),
      title: Text(
        "${AppLocalizations.of(context).tr('application')}: ${args.app}",
        style: navTextStyle,
      ),
      backgroundColor: Colors.blueGrey,
      actions: [
        TextButton.icon(
            onPressed: () {
              Navigator.popAndPushNamed(context, '/home');
            },
            icon: const Icon(
              Icons.apps,
              color: navTextColor,
            ),
            label: Text(
              AppLocalizations.of(context).tr('applications'),
              style: navTextStyle,
            )),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
