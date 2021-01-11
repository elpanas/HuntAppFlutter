import 'package:flutter/material.dart';
import 'package:huntapp/containers/matchcontainer.dart';
import 'package:huntapp/match.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:huntapp/globals.dart' as globals;
import 'package:easy_localization/easy_localization.dart';

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
  String _pin = '';
  bool _showProgress = true;
  bool _showMessage = false;

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
        title: Text('matchesTitle').tr(),
        /*actions: <Widget>[
          Padding(
              padding: EdgeInsets.only(right: 20.0),
              child: GestureDetector(
                  onTap: () {},
                  child: Icon(
                    Icons.edit,
                    size: 26.0,
                  ))),
        ],*/
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (_) => searchGames(searchController.text),
              controller: searchController,
              decoration: InputDecoration(
                hintText: tr('search'),
                hintStyle: TextStyle(fontSize: 14),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          if (_showMessage) _buildMessage(),
          if (_showProgress) _buildLoader(),
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

  Widget _buildMessage() {
    return Expanded(
      child: SizedBox(
        height: MediaQuery.of(context).size.height / 1.3,
        child: Center(
          child: Text('matchesWarn').tr(),
        ),
      ),
    );
  }

  void checkUser() async {
    await storage
        .read(key: 'pin')
        .then((value) => {_pin = value, loadMatches()});
  }

  void loadMatches() {
    http.get(
      globals.url + 'sgame/terminated',
      headers: <String, String>{
        HttpHeaders.authorizationHeader: 'Basic ' + _pin
      },
    ).then((res) {
      if (res.statusCode == HttpStatus.ok) {
        final resJson = jsonDecode(res.body);
        matches = resJson.map<Match>((json) => Match.fromJson(json)).toList();
        setState(() {
          matches = matches;
          _showProgress = false;
        });
      } else {
        setState(() {
          _showMessage = true;
          _showProgress = false;
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
