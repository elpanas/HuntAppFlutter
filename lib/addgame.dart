import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:huntapp/containers/eventcontainer.dart';
import 'globals.dart' as globals;
import 'package:easy_localization/easy_localization.dart';

class AddGamePage extends StatefulWidget {
  final Event event;
  AddGamePage(this.event);

  @override
  _AddGamePageState createState() => _AddGamePageState(event);
}

class _AddGamePageState extends State<AddGamePage> {
  final Event event;
  _AddGamePageState(this.event);

  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final storage = new FlutterSecureStorage();
  final List<String> gameCategories = ['Basic', 'Intermediate', 'Advanced'];
  String gameCategory = 'Basic';
  String textError = '';
  String _pin = '';
  bool _checked = false;

  @override
  void initState() {
    checkUser();
    super.initState();
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('newgame').tr()),
        body: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buidlFieldName(),
                  Container(height: 25),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: tr('ridLevel')),
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
                    title: Text('opengame').tr(),
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
                                  Navigator.pop(context, true)
                                else
                                  _buildError(context)
                              });
                        }
                      },
                      child: Text(
                        'saveGame',
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ).tr(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
  }

  Widget _buidlFieldName() {
    return TextFormField(
      controller: nameController,
      keyboardType: TextInputType.name,
      decoration: InputDecoration(
        hintText: tr('hintGame'),
        hintStyle: TextStyle(fontSize: 18),
      ),
      validator: (value) {
        if (value.isEmpty) {
          return tr('emptyText');
        }
        return null;
      },
    );
  }

  Future sendData() async {
    return http.post(
      globals.url + 'game',
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: 'Basic ' + _pin
      },
      body: jsonEncode(<String, dynamic>{
        'event_id': event.eventId,
        'name': nameController.text,
        'organizer': event.userId,
        'riddle_category': gameCategory,
        'is_open': _checked
      }),
    );
  }

  void checkUser() async {
    await storage.read(key: 'pin').then((value) => _pin = value);
  }

  ScaffoldFeatureController _buildError(context) {
    return Scaffold.of(context)
        .showSnackBar(SnackBar(content: Text('Something went wrong :(')));
  }
}
