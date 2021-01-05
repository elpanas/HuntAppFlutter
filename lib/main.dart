import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:huntapp/home.dart';

void main() {
  runApp(EasyLocalization(
      supportedLocales: [Locale('en', 'US'), Locale('it', 'IT')],
      path: 'assets/translations', // <-- change patch to your
      fallbackLocale: Locale('en', 'US'),
      child: HomePage()));
}
