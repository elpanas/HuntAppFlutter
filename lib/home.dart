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
        appBar: AppBar(
          title: Text('Hunting Treasure Home'),
        ),
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(height: 50),
          Text(
            'Welcome',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(height: 50),
          //Image.network('https://bit.ly/flutgelato'),
          Container(height: 50),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RaisedButton(
                color: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                onPressed: () {
                  checkUser().then((value) {
                    if (value) {
                      MaterialPageRoute routeEventsPage =
                          MaterialPageRoute(builder: (_) => EventsPage());
                      Navigator.push(context, routeEventsPage);
                    } else {
                      MaterialPageRoute routeRegPage =
                          MaterialPageRoute(builder: (_) => RegistrationPage());
                      Navigator.push(context, routeRegPage);
                    }
                  });
                },
                child: Text(
                  'Enter',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Future<bool> checkUser() async {
    try {
      String idu = await storage.read(key: 'pin');
      if (idu != null)
        return true;
      else
        return false;
    } catch (_) {
      return false;
    }
  }
}
