import 'package:flutter/material.dart';

class OnlyContentLayout extends StatefulWidget {
  final Widget content;
  final Function handleGoTo;

  const OnlyContentLayout({
    super.key,
    required this.handleGoTo,
    required this.content,
  });

  @override
  OnlyContentLayoutState createState() => OnlyContentLayoutState();
}

class OnlyContentLayoutState extends State<OnlyContentLayout> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.content,
    );
  }
}
