import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'containers/eventcontainer.dart';
import 'gameslist.dart';
import 'globals.dart' as globals;

class AddGamePage extends StatelessWidget {
  final Event event;
  AddGamePage(this.event);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Add New Game',
      theme: ThemeData(primarySwatch: Colors.orange),
      home: Scaffold(
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
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
  final List<String> gameCategories = ['Basic', 'Intermediate', 'Advanced'];
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
              _buidlFieldName(),
              Container(height: 25),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Riddles Level'),
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
                child: FlatButton(
                  minWidth: MediaQuery.of(context).size.width / 1.2,
                  color: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onPressed: () {
                    if (_formKey.currentState.validate()) {
                      sendData().then((res) => {
                            if (res.statusCode == HttpStatus.ok)
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => SingleEventPage(event)))
                            else
                              _buildError(context)
                          });
                    }
                  },
                  child: Text(
                    'Save Event',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buidlFieldName() {
    return TextFormField(
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
    );
  }

  Future sendData() async {
    String pin = await storage.read(key: 'pin');

    return http.post(
      globals.url + 'game',
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
    );
  }

  ScaffoldFeatureController _buildError(context) {
    return Scaffold.of(context)
        .showSnackBar(SnackBar(content: Text('Something went wrong :(')));
  }
}
