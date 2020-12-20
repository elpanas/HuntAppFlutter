import 'package:flutter/material.dart';
import 'package:huntapp/containers/matchcontainer.dart';
import 'package:huntapp/match.dart';
import 'containers/eventcontainer.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'globals.dart' as globals;

class MatchesList extends StatefulWidget {
  MatchesList();

  @override
  _MatchesListState createState() => _MatchesListState();
}

class _MatchesListState extends State<MatchesList> {
  _MatchesListState();

  final storage = new FlutterSecureStorage();
  final TextEditingController searchController = TextEditingController();
  List<Match> matches = List<Match>();
  bool isadmin;
  String pin = '';
  String message = '';

  @override
  void initState() {
    this.isadmin = false;
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
        title: Text('Games over'),
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
                itemCount: matches.length,
                itemBuilder: (BuildContext context, int index) {
                  return Card(
                    elevation: 2,
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => MatchPage(matches[index])));
                      },
                      leading: Icon(Icons.gamepad),
                      title: Text(
                        matches[index].gameName,
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
        .then((value) => {this.pin = value, loadMatches()});
  }

  void loadMatches() {
    http.get(
      globals.url + 'sgame/terminated',
      headers: <String, String>{
        HttpHeaders.authorizationHeader: 'Basic ' + this.pin
      },
    ).then((res) {
      if (res.statusCode == HttpStatus.ok) {
        final resJson = jsonDecode(res.body);
        matches = resJson.map<Match>((json) => Match.fromJson(json)).toList();
        setState(() {
          matches = matches;
        });
      } else {
        setState(() {
          message = 'No games over';
        });
      }
    });
  }

  void searchGames(search) {
    if (search != '')
      setState(() {
        matches = matches
            .where((element) => element.gameName.startsWith(search))
            .toList();
      });
    else
      loadMatches();
  }
}
