import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:huntapp/containers/eventcontainer.dart';
import 'package:huntapp/containers/gamecontainer.dart';
import 'package:huntapp/globals.dart' as globals;
import 'package:country_picker/country_picker.dart';

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
  String _countryInputName = 'No country inserted';
  String _countryInputCode;
  String _pin = '';
  bool sendok = false;
  String textError = '';

  @override
  void initState() {
    checkUser();
    super.initState();
  }

  @override
  void dispose() {
    nameController.dispose();
    playersController.dispose();
    photoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Aggiungi gruppo')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
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
                }, // if you need custome picker use this
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      enabled: false,
                      decoration: InputDecoration(
                        hintText: _countryInputName,
                        hintStyle: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Ink(
                          decoration: const ShapeDecoration(
                            color: Colors.orange,
                            shape: CircleBorder(),
                          ),
                          child: IconButton(
                              icon: Icon(
                                Icons.flag,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                showCountryPicker(
                                  context: context,
                                  showPhoneCode:
                                      false, // optional. Shows phone code before the country name.
                                  onSelect: (Country country) {
                                    setState(() {
                                      _countryInputName =
                                          country.displayNameNoCountryCode;
                                      _countryInputCode = country.countryCode;
                                    });
                                  },
                                );
                              })))
                ],
              ),
              Text(textError),
              FlatButton(
                color: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                onPressed: () {
                  if (_formKey.currentState.validate()) {
                    sendData().then((res) => {
                          if (res.statusCode == HttpStatus.ok)
                            Navigator.pop(context, true)
                          else
                            _buildError(context)
                        });
                  }
                },
                child: Text(
                  'Create a team',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future sendData() {
    return http.post(
      globals.url + 'sgame/',
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: 'Basic ' + _pin
      },
      body: jsonEncode(<String, dynamic>{
        'game_id': game.gameId,
        'group_name': nameController.text,
        'group_nr_players': int.tryParse(playersController.text),
        'group_flag': _countryInputCode,
        'riddle_cat': game.gameRidCategory
      }),
    );
  }

  ScaffoldFeatureController _buildError(context) {
    return Scaffold.of(context)
        .showSnackBar(SnackBar(content: Text('Something went wrong :(')));
  }

  void checkUser() async {
    await storage.read(key: 'pin').then((value) => _pin = value);
  }
}
