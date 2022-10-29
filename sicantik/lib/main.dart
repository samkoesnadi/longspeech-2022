import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:sicantik/internationalization.dart';
import 'package:sicantik/screens/home_screen.dart';
import 'package:sicantik/theme_data.dart';
import 'package:visibility_detector/visibility_detector.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();

  VisibilityDetectorController.instance.updateInterval =
      const Duration(milliseconds: 5);

  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown
  ]).then((_) => runApp(MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness:
          Platform.isAndroid ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarDividerColor: Colors.grey,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));

    return GetMaterialApp(
      theme: themeData,
      translations: Messages(),
      // your translations
      locale: const Locale('en', 'US'),
      enableLog: false,

      /// SET THE ROUTES HERE ///
      home: const HomeScreen(),
    );
  }
}
