import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:huntapp/home.dart';

Future main() async {
  await DotEnv().load('.env');
  runApp(HomePage());
}
