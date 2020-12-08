import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'eventslist.dart';
import 'registration.dart';

class HomePage extends StatelessWidget {
  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hunting Treasure',
      theme: ThemeData(primarySwatch: Colors.orange),
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
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Welcome',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(height: 25),
            //Image.network('https://bit.ly/flutgelato'),
            Container(height: 25),
            FlatButton(
              minWidth: MediaQuery.of(context).size.width / 1.2,
              color: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              onPressed: () {
                nextRoute = (this.pin != '')
                    ? MaterialPageRoute(builder: (_) => EventsPage())
                    : MaterialPageRoute(builder: (_) => RegistrationPage(true));

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
                borderRadius: BorderRadius.circular(5),
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
