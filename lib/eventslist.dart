import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:huntapp/addevent.dart';
import 'package:huntapp/addriddle.dart';
import 'package:huntapp/containers/eventcontainer.dart';
import 'package:huntapp/gameslist.dart';
import 'package:huntapp/matcheslist.dart';
import 'package:huntapp/themes.dart';

import 'globals.dart' as globals;

class EventsPage extends StatefulWidget {
  @override
  _EventsPageState createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  final storage = new FlutterSecureStorage();
  final TextEditingController searchController = TextEditingController();
  List<Event> events = List<Event>();
  bool _nmode = true;
  bool isadmin = false;
  bool showProgress;
  String pin = '';
  String message = '';
  String username = '';

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
    return MaterialApp(
      title: 'Events List',
      theme: lightThemeData,
      darkTheme: darkThemeData,
      themeMode: (_nmode) ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        appBar: AppBar(title: Text('Events')),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(
                    color: Colors.orange,
                    image: DecorationImage(
                        fit: BoxFit.fitWidth,
                        image: AssetImage('assets/images/backdraw.png'))),
                child: Stack(children: <Widget>[
                  Positioned(
                      bottom: 12.0,
                      child: Text(this.username,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 24,
                          ))),
                ]),
              ),
              ListTile(
                leading: Icon(Icons.games_rounded),
                title: Text('Games & Certificates'),
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => MatchesList())),
              ),
              (isadmin)
                  ? ListTile(
                      leading: Icon(Icons.now_widgets),
                      title: Text('Add New Riddle'),
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => AddRiddle())))
                  : Container(),
              Divider(
                indent: 18,
                endIndent: 18,
              ),
              SwitchListTile(
                title: const Text('Night Mode'),
                secondary: const Icon(Icons.nights_stay),
                value: _nmode,
                onChanged: (bool value) {
                  setState(() {
                    _nmode = value;
                  });

                  changeTheme(_nmode);
                },
                activeColor: Colors.orange,
              ),
            ],
          ),
        ),
        floatingActionButton: (isadmin)
            ? FloatingActionButton(
                child: Icon(Icons.add),
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => AddEventPage()));
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
                        leading: Icon(Icons.event),
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

  void changeTheme(value) async {
    var darkmode = (value) ? 'dark' : 'light';
    await storage.write(key: 'theme', value: darkmode);
  }

  void checkUser() async {
    await storage.read(key: 'theme').then((value) => setState(() {
          this._nmode = (value == 'dark');
        }));
    this.isadmin = (await storage.read(key: 'is_admin') == 'true');
    this.username = await storage.read(key: 'username');
    await storage
        .read(key: 'pin')
        .then((value) => {this.pin = value, loadEvents()});
  }

  void loadEvents() async {
    try {
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
    } catch (_) {
      setState(() {
        message = 'No events';
        this.showProgress = false;
      });
    }
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
