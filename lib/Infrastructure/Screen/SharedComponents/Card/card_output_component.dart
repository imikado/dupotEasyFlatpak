import 'package:flutter/material.dart';

class CardOutputComponent extends StatelessWidget {
  final String outputString;

  const CardOutputComponent({super.key, required this.outputString});

  @override
  Widget build(BuildContext context) {
    const TextStyle outputTextStyle =
        TextStyle(color: Colors.white, fontSize: 14.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Container(
          constraints: const BoxConstraints(minHeight: 20),
          color: Colors.black54,
          child: Padding(
              padding: const EdgeInsets.all(20),
              child: RichText(
                overflow: TextOverflow.clip,
                text: TextSpan(
                  style: outputTextStyle,
                  children: <TextSpan>[
                    TextSpan(text: outputString),
                  ],
                ),
              ))),
    );
  }
}
