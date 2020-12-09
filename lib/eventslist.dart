import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:huntapp/addevent.dart';
import 'containers/eventcontainer.dart';
import 'gameslist.dart';
import 'globals.dart' as globals;

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
  bool isadmin = false;
  bool showProgress;
  String pin = '';
  String message = '';

  @override
  void initState() {
    this.showProgress = true;
    checkUser();
    super.initState();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Events List')),
      floatingActionButton: (isadmin)
          ? FloatingActionButton(
              child: Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (_) => AddEventPage()));
              })
          : null,
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
          if (showProgress) _buildLoader(),
          Expanded(
            child: ListView.builder(
                itemCount: events.length,
                itemBuilder: (BuildContext context, int index) {
                  return Card(
                    elevation: 2,
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    SingleEventPage(events[index])));
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

  Widget _buildLoader() {
    return Expanded(
      child: SizedBox(
        height: MediaQuery.of(context).size.height / 1.3,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  void checkUser() async {
    this.isadmin = (await storage.read(key: 'is_admin') == 'true');
    await storage
        .read(key: 'pin')
        .then((value) => {this.pin = value, loadEvents()});
  }

  void loadEvents() async {
    http.get(
      globals.url + 'event',
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: 'Basic ' + this.pin
      },
    ).then((res) {
      if (res.statusCode == 200) {
        final resJson = jsonDecode(res.body);
        events = resJson.map<Event>((json) => Event.fromJson(json)).toList();
        setState(() {
          events = events;
          this.showProgress = false;
        });
      } else {
        setState(() {
          message = 'No events';
          this.showProgress = false;
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
}
