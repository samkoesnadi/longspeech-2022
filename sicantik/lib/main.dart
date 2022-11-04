import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:sicantik/helpers/image_labeler.dart';
import 'package:sicantik/helpers/notification.dart';
import 'package:sicantik/internationalization.dart';
import 'package:sicantik/screens/home_screen.dart';
import 'package:sicantik/theme_data.dart';
import 'package:visibility_detector/visibility_detector.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);

  await GetStorage.init();
  await initLocalNotification();
  await initializeImageLabeler();

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
      localizationsDelegates: const [LocaleNamesLocalizationsDelegate()],
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
