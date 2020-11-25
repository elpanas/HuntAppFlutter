import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'cluster.dart';
import 'gameslist.dart';
import 'globals.dart' as globals;

class Cluster {
  int clusterNr;
  Cluster(this.clusterNr);

  Cluster.fromJson(Map<String, dynamic> json) {
    this.clusterNr = json['cluster'];
  }
}

class GamePage extends StatefulWidget {
  final Game game;
  GamePage(this.game);

  @override
  _GamePageState createState() => _GamePageState(game);
}

class _GamePageState extends State<GamePage> {
  final Game game;
  _GamePageState(this.game);

  final storage = new FlutterSecureStorage();
  final TextEditingController searchController = TextEditingController();
  List<Cluster> clusters = List<Cluster>();
  bool isadmin = true;
  String message = '';

  @override
  void initState() {
    //checkUser();
    loadClusters();
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
      appBar: AppBar(
        title: Text(game.gameName),
        actions: <Widget>[
          Padding(
              padding: EdgeInsets.only(right: 20.0),
              child: GestureDetector(
                  onTap: () {},
                  child: Icon(
                    Icons.edit,
                    size: 26.0,
                  ))),
        ],
      ),
      floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () {
            MaterialPageRoute routeAddCluster = MaterialPageRoute(
                builder: (_) => ClusterPage(this.game, clusters.length + 1));
            Navigator.push(context, routeAddCluster);
          }),
      body: Column(
        children: <Widget>[
          // qui le info del game e il pulsante inizia
          Text(message),
          Expanded(
            child: ListView.builder(
                itemCount: clusters.length,
                itemBuilder: (BuildContext context, int index) {
                  return Card(
                    elevation: 2,
                    child: ListTile(
                      onTap: () {
                        MaterialPageRoute routeCluster = MaterialPageRoute(
                            builder: (_) =>
                                ClusterPage(game, clusters[index].clusterNr));
                        Navigator.push(context, routeCluster);
                      },
                      leading: Icon(Icons.adjust),
                      title: Text(
                        'Cluster nr.: ' + clusters[index].clusterNr.toString(),
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

  Future loadClusters() async {
    String pin = await storage.read(key: 'pin');

    http.get(
      globals.url + 'loc/game/' + game.gameId,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: 'Basic ' + pin
      },
    ).then((res) {
      if (res.statusCode == 200) {
        final resJson = jsonDecode(res.body);
        clusters =
            resJson.map<Cluster>((json) => Cluster.fromJson(json)).toList();
        setState(() {
          clusters = clusters;
        });
      } else {
        setState(() {
          message = 'No clusters';
        });
      }
    });
  }
}
