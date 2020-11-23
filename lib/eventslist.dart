import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:huntapp/addevent.dart';
import 'gameslist.dart';

class Event {
  String eventId, userId, eventName, userName;
  int minLoc, maxLoc, avgLoc;

  Event(this.eventId, this.eventName, this.minLoc, this.maxLoc, this.avgLoc,
      this.userId, this.userName);

  Event.fromJson(Map<String, dynamic> json) {
    this.eventId = json['_id'];
    this.eventName = json['name'];
    this.maxLoc = json['min_locations'];
    this.minLoc = json['max_locations'];
    this.avgLoc = json['min_avg_distance'];
    this.userId = json['organizer']['_id'];
    this.userName = json['organizer']['username'];
  }
}

class EventsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Events List',
      theme: ThemeData(primarySwatch: Colors.orange),
      home: EventsScreen(),
    );
  }
}

class EventsScreen extends StatefulWidget {
  @override
  _EventsScreenState createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final storage = new FlutterSecureStorage();
  final TextEditingController searchController = TextEditingController();
  List<Event> events = List<Event>();
  bool isadmin = true;
  String message = '';

  @override
  void initState() {
    //checkUser();
    loadEvents();
    super.initState();
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Events List')),
      floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () {
            MaterialPageRoute routeAddEventPage =
                MaterialPageRoute(builder: (_) => AddEventPage());
            Navigator.pop(context);
            Navigator.push(context, routeAddEventPage);
          }),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (_) => searchEvents(searchController.text),
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search...',
                hintStyle: TextStyle(fontSize: 14),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Text(message),
          Expanded(
            child: ListView.builder(
                itemCount: events.length,
                itemBuilder: (BuildContext context, int index) {
                  return Card(
                    elevation: 2,
                    child: ListTile(
                      onTap: () {
                        MaterialPageRoute routeEvent = MaterialPageRoute(
                            builder: (_) => SingleEventPage(events[index]));
                        Navigator.push(context, routeEvent);
                      },
                      leading: Icon(Icons.adjust),
                      title: Text(
                        events[index].eventName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      subtitle: Text('Organizer: ' + events[index].userName),
                    ),
                  );
                }),
          )
        ],
      ),
    );
  }

  Future loadEvents() async {
    final url = 'http://192.168.0.3:3000/api/event';
    String pin = await storage.read(key: 'pin');

    http.get(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: 'Basic ' + pin
      },
    ).then((res) {
      if (res.statusCode == 200) {
        final resJson = jsonDecode(res.body);
        events = resJson.map<Event>((json) => Event.fromJson(json)).toList();
        setState(() {
          events = events;
        });
      } else {
        setState(() {
          message = 'No events';
        });
      }
    });
  }

  void searchEvents(search) {
    if (search != '')
      setState(() {
        events = events
            .where((element) => element.eventName.startsWith(search))
            .toList();
      });
    else
      loadEvents();
  }

  void checkUser() async {
    try {
      isadmin = (await storage.read(key: 'is_admin') == 'true');
    } catch (_) {
      // nothing
    }
  }
}
