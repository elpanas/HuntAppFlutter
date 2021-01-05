import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_map_location_picker/generated/l10n.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:huntapp/addevent.dart';
import 'package:huntapp/addriddle.dart';
import 'package:huntapp/containers/eventcontainer.dart';
import 'package:huntapp/gameslist.dart';
import 'package:huntapp/matcheslist.dart';
import 'package:huntapp/themes.dart';
import 'package:huntapp/globals.dart' as globals;
import 'package:easy_localization/easy_localization.dart';

class EventsPage extends StatefulWidget {
  @override
  _EventsPageState createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  final storage = new FlutterSecureStorage();
  final TextEditingController searchController = TextEditingController();
  List<Event> events = List<Event>();
  bool _nmode = true;
  bool _isadmin = false;
  bool _showProgress;
  String _pin = '';
  String message = '';
  String _username = '';

  @override
  void initState() {
    _showProgress = true;
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
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        appBar: AppBar(title: Text('eventstitle').tr()),
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
                      child: Text(_username,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 24,
                          ))),
                ]),
              ),
              ListTile(
                leading: Icon(Icons.games_rounded),
                title: Text('gamecert').tr(),
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => MatchesList())),
              ),
              (_isadmin)
                  ? ListTile(
                      leading: Icon(Icons.now_widgets),
                      title: Text('newriddle').tr(),
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => AddRiddle())))
                  : Container(),
              Divider(
                indent: 18,
                endIndent: 18,
              ),
              SwitchListTile(
                title: Text('nightmode').tr(),
                secondary: Icon(Icons.nights_stay),
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
        floatingActionButton: (_isadmin)
            ? FloatingActionButton(
                child: Icon(Icons.add),
                onPressed: () {
                  Navigator.push(context,
                          MaterialPageRoute(builder: (_) => AddEventPage()))
                      .then((result) => {if (result != null) loadEvents()});
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
                  hintText: tr('search'),
                  hintStyle: TextStyle(fontSize: 14),
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Text(message),
            if (_showProgress) _buildLoader(),
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
                                  builder: (_) => GameListPage(events[index])));
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
                        subtitle: Text('organizer')
                            .tr(args: [events[index].userName]),
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
          _nmode = (value == 'dark');
        }));
    await storage.read(key: 'is_admin').then((value) => setState(() {
          _isadmin = (value == 'true');
        }));
    _username = await storage.read(key: 'username');
    await storage
        .read(key: 'pin')
        .then((value) => {_pin = value, loadEvents()});
  }

  void loadEvents() async {
    try {
      Position current = await Geolocator.getLastKnownPosition();
      http.get(
        globals.url +
            'event/lat/' +
            current.latitude.toString() +
            '/long/' +
            current.longitude.toString(),
        headers: <String, String>{
          HttpHeaders.authorizationHeader: 'Basic ' + _pin
        },
      ).then((res) {
        if (res.statusCode == HttpStatus.ok) {
          final resJson = jsonDecode(res.body);
          events = resJson.map<Event>((json) => Event.fromJson(json)).toList();
          setState(() {
            events = events;
            _showProgress = false;
          });
        } else {
          setState(() {
            message = tr('noevents');
            _showProgress = false;
          });
        }
      });
    } catch (_) {
      setState(() {
        message = tr('noevents');
        _showProgress = false;
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
