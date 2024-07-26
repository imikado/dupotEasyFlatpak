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
        "Application: ${args.app}",
        style: navTextStyle,
      ),
      backgroundColor: Colors.blueGrey,
      actions: [
        TextButton.icon(
            onPressed: () {},
            icon: const Icon(
              Icons.settings,
              color: navTextColor,
            ),
            label: const Text(
              'Settings',
              style: navTextStyle,
            )),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
