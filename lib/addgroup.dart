import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:huntapp/game.dart';
import 'containers/gamecontainer.dart';
import 'globals.dart' as globals;

class AddGroup extends StatefulWidget {
  final Game game;
  AddGroup(this.game);

  @override
  _AddGroupState createState() => _AddGroupState(game);
}

class _AddGroupState extends State<AddGroup> {
  final Game game;
  _AddGroupState(this.game);
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController playersController = TextEditingController();
  final TextEditingController photoController = TextEditingController();

  final storage = new FlutterSecureStorage();
  bool isadmin = true;
  String textError = '';

  @override
  void initState() {
    //checkUser();
    nameController.dispose();
    playersController.dispose();
    photoController.dispose();
    super.initState();
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Aggiungi gruppo'),
      ),
      floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () {
            sendData().then((value) => {
                  if (_formKey.currentState.validate())
                    {
                      sendData().then((value) {
                        if (value || value == null) {
                          MaterialPageRoute routeEvents = MaterialPageRoute(
                              builder: (_) => GamePage(this.game));
                          Navigator.push(context, routeEvents);
                        }
                      })
                    }
                });
          }),
      body: Column(
        children: <Widget>[
          TextFormField(
            controller: nameController,
            keyboardType: TextInputType.name,
            decoration: InputDecoration(
              hintText: 'Type the name of the group',
              hintStyle: TextStyle(fontSize: 18),
            ),
            validator: (value) {
              if (value.isEmpty) {
                return 'Please enter some text';
              }
              return null;
            },
          ),
          TextFormField(
            controller: playersController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Type the nr of members',
              hintStyle: TextStyle(fontSize: 18),
            ),
            validator: (value) {
              if (value.isEmpty || int.parse(value) <= 0) {
                return 'Please enter a number > 0';
              }
              return null;
            },
          ),
          TextFormField(
            controller: photoController,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              hintText: 'Type the nr of members',
              hintStyle: TextStyle(fontSize: 18),
            ),
          ),
          Text(textError),
        ],
      ),
    );
  }

  Future sendData() async {
    String pin = await storage.read(key: 'pin');

    http
        .post(
      globals.url + 'sgame/',
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: 'Basic ' + pin
      },
      body: jsonEncode(<String, dynamic>{
        'game_id': this.game.gameId,
        'group_name': nameController,
        'group_nr_players': playersController,
        'group_photo_path': photoController
      }),
    )
        .then((res) {
      if (res.statusCode == 200) {
        final sessiondata = jsonDecode(res.body);
        setState(() async {
          textError = '';
          await storage.write(key: 'idsg', value: sessiondata.idsg);
        });
        return true;
      } else {
        setState(() => textError = 'An error has occurred');
        return true;
      }
    });
  }
}
