import 'package:flutter/material.dart';

class OnlyContentLayout extends StatefulWidget {
  final Widget content;
  final Function handleGoTo;
  final Widget menu;

  const OnlyContentLayout({
    super.key,
    required this.handleGoTo,
    required this.content,
    required this.menu,
  });

  @override
  OnlyContentLayoutState createState() => OnlyContentLayoutState();
}

class OnlyContentLayoutState extends State<OnlyContentLayout> {
  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: widget.content,
    );
  }
}
