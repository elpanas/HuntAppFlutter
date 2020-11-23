import 'package:flutter/material.dart';
import 'package:huntapp/home.dart';
import 'addgame.dart';
import 'eventslist.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Game {
  String gameId, gameName;
  Game(this.gameId, this.gameName);

  Game.fromJson(Map<String, dynamic> json) {
    this.gameId = json['_id'];
    this.gameName = json['name'];
  }
}

class SingleEventPage extends StatefulWidget {
  final Event event;
  SingleEventPage(this.event);

  @override
  _SingleEventPageState createState() => _SingleEventPageState(event);
}

class _SingleEventPageState extends State<SingleEventPage> {
  final Event event;
  _SingleEventPageState(this.event);

  final storage = new FlutterSecureStorage();
  final TextEditingController searchController = TextEditingController();
  List<Game> games = List<Game>();
  bool isadmin = true;
  String message = '';
  MaterialPageRoute routeHome = MaterialPageRoute(builder: (_) => HomePage());

  @override
  void initState() {
    //checkUser();
    loadGames();
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
        title: Text('Games (' + event.eventName + ')'),
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
            MaterialPageRoute routeAddGamePage =
                MaterialPageRoute(builder: (_) => AddGamePage(this.event));
            Navigator.pop(context);
            Navigator.push(context, routeAddGamePage);
          }),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (_) => searchGames(searchController.text),
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
                itemCount: games.length,
                itemBuilder: (BuildContext context, int index) {
                  return Card(
                    elevation: 2,
                    child: ListTile(
                      onTap: () {
                        /*MaterialPageRoute routeGame = MaterialPageRoute(
                            builder: (_) => GamePage(games[index]));
                        Navigator.push(context, routeGame);*/
                      },
                      leading: Icon(Icons.adjust),
                      title: Text(
                        games[index].gameName,
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

  Future loadGames() async {
    final url = 'http://192.168.0.3:3000/api/game/event/' + event.eventId;
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
        games = resJson.map<Game>((json) => Game.fromJson(json)).toList();
        setState(() {
          games = games;
        });
      } else {
        setState(() {
          message = 'No games';
        });
      }
    });
  }

  void searchGames(search) {
    if (search != '')
      setState(() {
        games = games
            .where((element) => element.gameName.startsWith(search))
            .toList();
      });
    else
      loadGames();
  }
}
