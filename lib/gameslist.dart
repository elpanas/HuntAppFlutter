import 'package:flutter/material.dart';
import 'addgame.dart';
import 'containers/eventcontainer.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'game.dart';
import 'containers/gamecontainer.dart';
import 'globals.dart' as globals;

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
  String pin = '';
  String message = '';

  @override
  void initState() {
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
      floatingActionButton: (isadmin)
          ? FloatingActionButton(
              child: Icon(Icons.add),
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => AddGamePage(this.event)));
              })
          : null,
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
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    GamePage(this.event, games[index])));
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

  void checkUser() async {
    await storage
        .read(key: 'pin')
        .then((value) => {this.pin = value, loadGames()});
  }

  void loadGames() {
    http.get(
      globals.url + 'game/event/' + event.eventId,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: 'Basic ' + this.pin
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
