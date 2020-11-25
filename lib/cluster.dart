import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:huntapp/addlocation.dart';
import 'gameslist.dart';
import 'globals.dart' as globals;

class Location {
  String locId, locDescription, locImagepath;
  bool locStart, locFinal;

  Location(this.locId, this.locDescription, this.locImagepath, this.locStart,
      this.locFinal);

  Location.fromJson(Map<String, dynamic> json) {
    this.locId = json['_id'];
    this.locDescription = json['description'];
    this.locImagepath = json['image_path'];
    this.locStart = json['is_start'];
    this.locFinal = json['is_final'];
  }
}

class ClusterPage extends StatelessWidget {
  final Game game;
  final int cluster;
  ClusterPage(this.game, this.cluster);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cluster nr.:' + cluster.toString(),
      theme: ThemeData(primarySwatch: Colors.orange),
      home: ClusterScreen(game, cluster),
    );
  }
}

class ClusterScreen extends StatefulWidget {
  final Game game;
  final int cluster;
  ClusterScreen(this.game, this.cluster);

  @override
  _ClusterScreenState createState() => _ClusterScreenState(game, cluster);
}

class _ClusterScreenState extends State<ClusterScreen> {
  final Game game;
  final int cluster;
  _ClusterScreenState(this.game, this.cluster);
  final storage = new FlutterSecureStorage();
  List<Location> locations = List<Location>();
  bool isadmin = true;
  String message = '';

  @override
  void initState() {
    //checkUser();
    loadLocations();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cluster nr.:' + cluster.toString())),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add_location),
        onPressed: () {
          MaterialPageRoute routeLoc = MaterialPageRoute(
              builder: (_) => AddLocation(this.game, this.cluster));
          Navigator.push(context, routeLoc);
        },
      ),
      body: Column(
        children: <Widget>[
          Text(message),
          Expanded(
            child: ListView.builder(
                itemCount: locations.length,
                itemBuilder: (BuildContext context, int index) {
                  return Card(
                    elevation: 2,
                    child: ListTile(
                      onTap: () {
                        /*MaterialPageRoute routeEvent = MaterialPageRoute(
                            builder: (_) =>
                                SingleEventPage(locations[index].locId));
                        Navigator.push(context, routeEvent);*/
                      },
                      leading: Icon(Icons.location_on),
                      title: Text(
                        locations[index].locDescription,
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
        ],
      ),
    );
  }

  Future loadLocations() async {
    String pin = await storage.read(key: 'pin');

    http.get(
      globals.url +
          'loc/game/' +
          game.gameId +
          '/cluster/' +
          cluster.toString(),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: 'Basic ' + pin
      },
    ).then((res) {
      if (res.statusCode == 200) {
        final resJson = jsonDecode(res.body);
        locations =
            resJson.map<Location>((json) => Location.fromJson(json)).toList();
        setState(() {
          locations = locations;
        });
      } else {
        setState(() {
          message = 'No locations';
        });
      }
    });
  }

  void checkUser() async {
    try {
      isadmin = (await storage.read(key: 'is_admin') == 'true');
    } catch (_) {
      // nothing
    }
  }
}
