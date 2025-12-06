import 'package:dupot_easy_flatpak/Infrastructure/Api/localization_api.dart';
import 'package:flutter/material.dart';

class LoadingComponent extends StatelessWidget {
  const LoadingComponent({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(LocalizationApi().tr("loading")),
        SizedBox(width: 8),
        SizedBox(
          width: 18,
          height: 18,
          child: AspectRatio(
            aspectRatio: 1,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
        ),
      ],
    );
  }
}
