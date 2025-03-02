import 'package:flutter/material.dart';

class ReloadView extends StatefulWidget {
  final Function handle;

  const ReloadView({super.key, required this.handle});

  @override
  State<StatefulWidget> createState() => _ReloadViewState();
}

class _ReloadViewState extends State<ReloadView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    processInit();
    super.dispose();
  }

  Future<void> processInit() async {
    widget.handle();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}
