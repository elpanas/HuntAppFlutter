import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'eventslist.dart';
import 'gameslist.dart';

class AddGamePage extends StatelessWidget {
  final Event event;
  AddGamePage(this.event);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Add New Game',
      theme: ThemeData(primarySwatch: Colors.orange),
      home: Scaffold(
        appBar: AppBar(title: Text('Add New Game')),
        body: AddGameScreen(event),
      ),
    );
  }
}

class AddGameScreen extends StatefulWidget {
  final Event event;
  AddGameScreen(this.event);

  @override
  _AddGameScreenState createState() => _AddGameScreenState(event);
}

class _AddGameScreenState extends State<AddGameScreen> {
  final Event event;
  _AddGameScreenState(this.event);

  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final storage = new FlutterSecureStorage();
  final List<String> gameCategories = [
    'Basic',
    'Intermediate',
    'Advanced'
  ]; // intermediate non va
  String gameCategory = 'Basic';
  String textError = '';
  bool _checked = false;

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                keyboardType: TextInputType.name,
                decoration: InputDecoration(
                  hintText: 'Type the name of the game',
                  hintStyle: TextStyle(fontSize: 18),
                ),
                validator: (value) {
                  if (value.isEmpty) {
                    return 'Please enter some text';
                  }
                  return null;
                },
              ),
              Container(height: 25),
              DropdownButton<String>(
                value: gameCategory,
                items: gameCategories.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String newValue) {
                  setState(() {
                    gameCategory = newValue;
                  });
                },
              ),
              Container(height: 25),
              CheckboxListTile(
                title: Text('Check if you want an open game'),
                value: _checked,
                onChanged: (bool value) {
                  setState(() {
                    _checked = value;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
              Container(height: 25),
              Container(child: Text(textError)),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: RaisedButton(
                  child: Text(
                    'Add New Game',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  color: Colors.orange,
                  onPressed: () {
                    if (_formKey.currentState.validate()) {
                      sendData().then((value) {
                        if (value || value == null) {
                          MaterialPageRoute routeGameList = MaterialPageRoute(
                              builder: (_) => SingleEventPage(event));
                          Navigator.push(context, routeGameList);
                        }
                      });
                    }
                  },
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future sendData() async {
    String url = 'http://192.168.0.3:3000/api/game';
    String pin = await storage.read(key: 'pin');

    http
        .post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: 'Basic ' + pin
      },
      body: jsonEncode(<String, dynamic>{
        'event_id': event.eventId,
        'name': nameController.text,
        'riddle_category': gameCategory,
        'is_open': _checked
      }),
    )
        .then((res) {
      if (res.statusCode == 200) {
        setState(() {
          textError = '';
        });
        return true;
      } else {
        setState(() {
          textError = 'An error has occurred';
        });
        return false;
      }
    });
    // textError = 'Request in progress...';
  }
}
