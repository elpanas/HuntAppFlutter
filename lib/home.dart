import 'dart:io';
import 'package:huntapp/eventslist.dart';
import 'package:huntapp/registration.dart';
import 'package:huntapp/themes.dart';
import 'globals.dart' as globals;
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Code Hunting Game',
      theme: lightThemeData,
      darkTheme: darkThemeData,
      themeMode: ThemeMode.dark,
      home: Scaffold(
        body: HomePageScreen(),
      ),
    );
  }
}

class HomePageScreen extends StatefulWidget {
  @override
  _HomePageStateScreen createState() => _HomePageStateScreen();
}

class _HomePageStateScreen extends State<HomePageScreen> {
  final storage = new FlutterSecureStorage();
  MaterialPageRoute nextRoute;
  String pin;
  bool logged;

  @override
  void initState() {
    pin = '';
    logged = false;
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
              if (this.logged)
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
                    'Enter',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ),
              if (this.logged)
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
                                this.logged = false;
                              })
                            }
                          else
                            _buildError(context)
                        });
                  },
                  child: Text(
                    'Logout',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ),
              if (!this.logged)
                FlatButton(
                  minWidth: MediaQuery.of(context).size.width / 1.2,
                  color: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onPressed: () {
                    nextRoute = (this.logged)
                        ? MaterialPageRoute(builder: (_) => EventsPage())
                        : MaterialPageRoute(
                            builder: (_) => RegistrationPage(true));

                    Navigator.push(context, nextRoute);
                  },
                  child: Text(
                    'Login',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ),
              if (!this.logged)
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
                            builder: (_) => RegistrationPage(false)));
                  },
                  child: Text(
                    'Register',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
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
                this.pin = value;
              }),
              checkLogin()
            }
        });
  }

  void checkLogin() async {
    http.get(
      globals.url + 'user/chklogin',
      headers: <String, String>{
        HttpHeaders.authorizationHeader: 'Basic ' + this.pin
      },
    ).then((res) => {
          if (res.statusCode == HttpStatus.ok)
            setState(() {
              this.logged = true;
            })
        });
  }

  Future makeLogout() async {
    return http.put(
      globals.url + 'user/logout',
      headers: <String, String>{
        HttpHeaders.authorizationHeader: 'Basic ' + this.pin
      },
    );
  }
}
