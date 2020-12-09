import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:huntapp/game.dart';
import 'containers/eventcontainer.dart';
import 'containers/gamecontainer.dart';
import 'globals.dart' as globals;

class AddGroup extends StatefulWidget {
  final Event event;
  final Game game;
  AddGroup(this.event, this.game);

  @override
  _AddGroupState createState() => _AddGroupState(event, game);
}

class _AddGroupState extends State<AddGroup> {
  final Event event;
  final Game game;
  _AddGroupState(this.event, this.game);
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController playersController = TextEditingController();
  final TextEditingController photoController = TextEditingController();

  final storage = new FlutterSecureStorage();
  String pin = '';
  bool sendok = false;
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
    nameController.dispose();
    playersController.dispose();
    photoController.dispose();
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
            if (_formKey.currentState.validate()) {
              sendData();
              if (this.sendok) {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => GamePage(this.event, this.game)));
              }
            }
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

  void sendData() {
    http
        .post(
      globals.url + 'sgame/',
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: 'Basic ' + this.pin
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
          this.sendok = true;
          await storage.write(key: 'idsg', value: sessiondata.idsg);
        });
      } else {
        setState(() => textError = 'An error has occurred');
      }
    });
  }

  void checkUser() async {
    await storage.read(key: 'pin').then((value) => {this.pin = value});
  }
}
