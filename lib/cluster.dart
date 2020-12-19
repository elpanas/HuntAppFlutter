import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:huntapp/addlocation.dart';
import 'package:huntapp/containers/eventcontainer.dart';
import 'containers/gamecontainer.dart';
import 'containers/locationcontainer.dart';
import 'containers/optionscontainer.dart';
import 'globals.dart' as globals;

class ClusterPage extends StatefulWidget {
  final Event event;
  final Game game;
  final int cluster;
  final Opts options;
  ClusterPage(this.event, this.game, this.cluster, this.options);

  @override
  _ClusterPageState createState() =>
      _ClusterPageState(event, game, cluster, options);
}

class _ClusterPageState extends State<ClusterPage> {
  final Event event;
  final Game game;
  final int cluster;
  final Opts options;
  _ClusterPageState(this.event, this.game, this.cluster, this.options);
  final storage = new FlutterSecureStorage();
  List<Location> locations = List<Location>();
  String pin = '';
  bool showAddButton = false;
  bool locStartFinalWarn = false;
  String message = '';

  @override
  void initState() {
    checkUser();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cluster ' + cluster.toString(),
      theme:
          ThemeData(primarySwatch: Colors.orange, brightness: Brightness.light),
      darkTheme: ThemeData(
        primarySwatch: Colors.orange,
        primaryColor: Colors.orange,
        brightness: Brightness.dark,
        backgroundColor: const Color(0xFF212121),
        floatingActionButtonTheme:
            FloatingActionButtonThemeData(backgroundColor: Colors.orange),
        dividerColor: Colors.black12,
      ),
      themeMode: ThemeMode.dark,
      home: Scaffold(
        appBar: AppBar(
            title:
                Text('Cluster ' + cluster.toString() + ' of ' + game.gameName)),
        floatingActionButton: (this.showAddButton)
            ? FloatingActionButton(
                child: Icon(Icons.add),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => AddLocation(this.event, this.game,
                              this.cluster, this.options)));
                },
              )
            : null,
        body: Column(
          children: <Widget>[
            if (message != '')
              Expanded(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [Text(message)]),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListView.builder(
                    itemCount: locations.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Card(
                        elevation: 2,
                        child: ListTile(
                          tileColor: (locations[index].locStart ||
                                  locations[index].locFinal)
                              ? Colors.indigo
                              : null,
                          onTap: () {
                            /*MaterialPageRoute routeEvent = MaterialPageRoute(
                                builder: (_) =>
                                    SingleEventPage(locations[index]));
                            Navigator.push(context, routeEvent);*/
                          },
                          leading: Icon(Icons.location_on),
                          title: Text(
                            (locations[index].locFinal)
                                ? 'Final location'
                                : 'Location ' + (index + 1).toString(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      );
                    }),
              ),
            ),
            if (locStartFinalWarn) _buildWarning(),
          ],
        ),
      ),
    );
  }

  Widget _buildWarning() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Text('You have to add Start and/or final locations yet'),
    );
  }

  // check if the max number of locations has been reached
  void checkAddButton() {
    if (!this.options.isfinal || this.options.locnr < this.event.minLoc) {
      setState(() {
        this.showAddButton = true;
      });
    }
  }

  void loadLocations() {
    http.get(
      globals.url + 'loc/game/' + game.gameId,
      headers: <String, String>{
        HttpHeaders.authorizationHeader: 'Basic ' + this.pin
      },
    ).then((res) {
      if (res.statusCode == 200) {
        final resJson = jsonDecode(res.body);
        locations =
            resJson.map<Location>((json) => Location.fromJson(json)).toList();
        setState(() {
          locations = locations
              .where((element) => element.locCluster == cluster)
              .toList();
        });
      } else {
        setState(() {
          message = 'No locations';
        });
      }
    });
  }

  void checkUser() async {
    await storage
        .read(key: 'pin')
        .then((value) => {this.pin = value, loadLocations(), checkAddButton()});
  }
}
