import 'package:flutter/material.dart';
//import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:huntapp/addevent.dart';

/*
class Event {
  String name;
  int min_locations;
  int max_locations;
  int min_avg_distance;
}
*/

class EventsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Events List',
      theme: ThemeData(primarySwatch: Colors.orange),
      home: Scaffold(
        appBar: AppBar(title: Text('Events Lists')),
        floatingActionButton: FloatingActionButton(
            child: Icon(Icons.add),
            onPressed: () {
              MaterialPageRoute routeAddEventPage =
                  MaterialPageRoute(builder: (_) => AddEventPage());
              Navigator.push(context, routeAddEventPage);
            }),
        body: EventsScreen(),
      ),
    );
  }
}

class EventsScreen extends StatefulWidget {
  @override
  _EventsScreenState createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final storage = new FlutterSecureStorage();
  bool isadmin = false;

  @override
  void initState() {
    checkUser();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text('Ciao'),
    );
  }

  void checkUser() async {
    try {
      isadmin = (await storage.read(key: 'is_admin') == 'true');
    } catch (_) {
      // nothing
    }
  }
}
