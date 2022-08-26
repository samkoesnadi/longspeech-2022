/// Set the theme of the application
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


const String fontName = 'Roboto';

final theme_data = ThemeData(
    primarySwatch: Colors.blue,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color.fromRGBO(239, 238, 239, 1.0),
    primaryTextTheme: GoogleFonts.getTextTheme('Lato'),
    textTheme: GoogleFonts.getTextTheme('Lato'),
);
