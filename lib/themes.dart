import 'package:flutter/material.dart';

var lightThemeData = ThemeData(
    primarySwatch: Colors.orange,
    brightness: Brightness.light,
    backgroundColor: Color(0x0FF1A237E),
    dividerColor: Colors.black12);

var darkThemeData = ThemeData(
  primarySwatch: Colors.orange,
  primaryColor: Colors.orange,
  brightness: Brightness.dark,
  backgroundColor: const Color(0xFF212121),
  accentColor: Colors.orangeAccent,
  floatingActionButtonTheme:
      FloatingActionButtonThemeData(backgroundColor: Colors.orange),
  dividerColor: Colors.white70,
);
