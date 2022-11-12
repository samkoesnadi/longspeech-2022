import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sicantik/helpers/image_labeler.dart';
import 'package:sicantik/helpers/notification.dart';
import 'package:sicantik/screens/home_screen.dart';
import 'package:sicantik/theme_data.dart';
import 'package:sicantik/internationalization.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);

  await GetStorage.init();
  await GetStorage.init("notes");
  await GetStorage.init("reminders");
  await initLocalNotification();
  await initializeImageLabeler();

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

    const chosenLocale = Locale('en', 'US');

    return GlobalLoaderOverlay(
        child: GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: themeData,
      translations: Messages(),
      enableLog: false,
      localizationsDelegates: const [
        LocaleNamesLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      locale: chosenLocale,
      fallbackLocale: const Locale('en', 'US'),
      /// SET THE ROUTES HERE ///
      home: const HomeScreen(),
    ));
  }
}
