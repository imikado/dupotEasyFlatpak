import 'dart:convert';

import 'package:dupot_easy_flatpak/Models/flatpak_app.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FlathubFactory {
  static bool isDebug = true;

  static Future<List<FlatpakApp>> getFlatpakList(context) async {
    List<FlatpakApp> flatpakList = [];

    print('dl en.json');

    var flatpakContent = await http.get(Uri.parse(
        'https://flathub.org/_next/data/df278fbfe8fa52e1f2da8f05383a96c232999a13/en.json'));

    Map<String, dynamic> obj = jsonDecode(flatpakContent.body);
    List<dynamic> trendingList = obj['pageProps']['trending']['hits'];

    for (Map<String, dynamic> itemLoop in trendingList) {
      flatpakList.add(FlatpakApp(
          title: itemLoop['name'],
          sumary: itemLoop['summary'],
          icon: itemLoop['icon']));
    }

    if (isDebug) {
      print(flatpakList);
    }

    return flatpakList;
  }
}
