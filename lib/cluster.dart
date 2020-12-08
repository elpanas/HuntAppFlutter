import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:huntapp/addlocation.dart';
import 'containers/gamecontainer.dart';
import 'containers/locationcontainer.dart';
import 'globals.dart' as globals;

class ClusterPage extends StatefulWidget {
  final Game game;
  final int cluster;
  ClusterPage(this.game, this.cluster);

  @override
  _ClusterPageState createState() => _ClusterPageState(game, cluster);
}

class _ClusterPageState extends State<ClusterPage> {
  final Game game;
  final int cluster;
  _ClusterPageState(this.game, this.cluster);
  final storage = new FlutterSecureStorage();
  List<Location> locations = List<Location>();
  String pin = '';
  bool isadmin = true;
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
      title: 'Cluster nr.:' + cluster.toString(),
      theme: ThemeData(primarySwatch: Colors.orange),
      home: Scaffold(
        appBar: AppBar(title: Text('Cluster nr.:' + cluster.toString())),
        floatingActionButton: (this.showAddButton)
            ? FloatingActionButton(
                child: Icon(Icons.add_location),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              AddLocation(this.game, this.cluster)));
                },
              )
            : null,
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
                        tileColor: (locations[index].locStart ||
                                locations[index].locFinal)
                            ? Colors.blueAccent.shade50
                            : null,
                        onTap: () {
                          /*MaterialPageRoute routeEvent = MaterialPageRoute(
                              builder: (_) =>
                                  SingleEventPage(locations[index]));
                          Navigator.push(context, routeEvent);*/
                        },
                        leading: Icon(Icons.location_on),
                        title: Text(
                          'Location ' + (index + 1).toString(),
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
  void checkLocNr() {
    http.get(
      globals.url + 'checklocnr/' + this.game.gameId,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: 'Basic ' + this.pin
      },
    ).then((res) {
      if (res.statusCode == 200) {
        setState(() {
          this.showAddButton = true;
        });
      }
    });
  }

  void loadLocations() {
    http.get(
      globals.url +
          'loc/game/' +
          game.gameId +
          '/cluster/' +
          cluster.toString(),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: 'Basic ' + this.pin
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
    isadmin = (await storage.read(key: 'is_admin') == 'true');
    await storage
        .read(key: 'pin')
        .then((value) => {this.pin = value, loadLocations(), checkLocNr()});
  }
}
