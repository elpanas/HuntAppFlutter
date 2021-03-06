import 'dart:io';
import 'package:huntapp/eventslist.dart';
import 'package:huntapp/registration.dart';
import 'package:huntapp/themes.dart';
import 'package:huntapp/globals.dart' as globals;
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:easy_localization/easy_localization.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Code Hunting Game',
      theme: lightThemeData,
      darkTheme: darkThemeData,
      themeMode: ThemeMode.system,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: Scaffold(body: HomePageScreen()),
    );
  }
}

class HomePageScreen extends StatefulWidget {
  @override
  _HomePageStateScreen createState() => _HomePageStateScreen();
}

class _HomePageStateScreen extends State<HomePageScreen> {
  final storage = new FlutterSecureStorage();
  String _pin;
  bool _logged;

  @override
  void initState() {
    _pin = '';
    _logged = false;
    checkPin();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFF212121),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Image(image: AssetImage('assets/images/title.png')),
              ),
              if (_logged)
                FlatButton(
                  minWidth: MediaQuery.of(context).size.width / 1.2,
                  color: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => EventsPage()));
                  },
                  child: Text(
                    'enter',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ).tr(),
                ),
              if (_logged)
                FlatButton(
                  minWidth: MediaQuery.of(context).size.width / 1.2,
                  color: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onPressed: () {
                    makeLogout().then((res) async => {
                          if (res.statusCode == HttpStatus.ok)
                            {
                              await storage.deleteAll(),
                              setState(() {
                                _logged = false;
                              })
                            }
                          else
                            _buildError(context)
                        });
                  },
                  child: Text(
                    'logout',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ).tr(),
                ),
              if (!_logged)
                FlatButton(
                  minWidth: MediaQuery.of(context).size.width / 1.2,
                  color: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onPressed: () {
                    Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => RegistrationPage(true)))
                        .then((result) => {
                              if (result != null)
                                setState(() {
                                  _logged = true;
                                })
                            });
                  },
                  child: Text(
                    'login',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ).tr(),
                ),
              if (!_logged)
                FlatButton(
                  minWidth: MediaQuery.of(context).size.width / 1.2,
                  color: Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onPressed: () {
                    Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => RegistrationPage(false)))
                        .then((result) => {
                              if (result != null)
                                setState(() {
                                  _logged = true;
                                })
                            });
                  },
                  child: Text(
                    'registration',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ).tr(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  ScaffoldFeatureController _buildError(context) {
    return Scaffold.of(context)
        .showSnackBar(SnackBar(content: Text('Something went wrong :(')));
  }

  void checkPin() async {
    await storage.read(key: 'pin').then((value) => {
          if (value != null)
            {
              setState(() {
                _pin = value;
              }),
              checkLogin()
            }
        });
  }

  void checkLogin() async {
    http.get(
      globals.url + 'user/chklogin',
      headers: <String, String>{
        HttpHeaders.authorizationHeader: 'Basic ' + _pin
      },
    ).then((res) => {
          if (res.statusCode == HttpStatus.ok)
            setState(() {
              _logged = true;
            })
        });
  }

  Future makeLogout() async {
    return http.put(
      globals.url + 'user/logout',
      headers: <String, String>{
        HttpHeaders.authorizationHeader: 'Basic ' + _pin
      },
    );
  }
}
