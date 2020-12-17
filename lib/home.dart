import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'eventslist.dart';
import 'registration.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Code Hunting Game',
      theme: ThemeData(
          primarySwatch: Colors.orange,
          brightness: Brightness.light,
          backgroundColor: Color(0x0FF1A237E)),
      darkTheme: ThemeData(
        primarySwatch: Colors.orange,
        primaryColor: Colors.indigo,
        brightness: Brightness.dark,
        backgroundColor: const Color(0xFF212121),
        accentColor: Colors.white,
        accentIconTheme: IconThemeData(color: Colors.orange),
        dividerColor: Colors.black12,
      ),
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
  String pin = '';

  @override
  void initState() {
    checkUser();
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
              FlatButton(
                minWidth: MediaQuery.of(context).size.width / 1.2,
                color: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                onPressed: () {
                  nextRoute = (this.pin != '')
                      ? MaterialPageRoute(builder: (_) => EventsPage())
                      : MaterialPageRoute(
                          builder: (_) => RegistrationPage(true));

                  Navigator.push(context, nextRoute);
                },
                child: Text(
                  'Enter',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
              FlatButton(
                minWidth: MediaQuery.of(context).size.width / 1.2,
                color: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                onPressed: () {
                  nextRoute = (this.pin != '')
                      ? MaterialPageRoute(builder: (_) => EventsPage())
                      : MaterialPageRoute(
                          builder: (_) => RegistrationPage(false));

                  Navigator.push(context, nextRoute);
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

  void checkUser() async {
    await storage.read(key: 'pin').then((value) => {
          if (value != null)
            setState(() {
              this.pin = value;
            })
        });
  }
}
