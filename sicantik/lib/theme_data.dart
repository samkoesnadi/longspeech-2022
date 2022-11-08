/// Set the theme of the application
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


const String fontName = 'Roboto';

final themeData = ThemeData(
    primarySwatch: Colors.primaries[Random().nextInt(Colors.primaries.length)],
    scaffoldBackgroundColor: const Color.fromRGBO(239, 238, 239, 1.0),
);
