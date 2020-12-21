import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:huntapp/eventslist.dart';
import 'package:huntapp/themes.dart';
import 'globals.dart' as globals;

class AddEventPage extends StatefulWidget {
  @override
  _AddEventPageState createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController minlocController = TextEditingController();
  final TextEditingController maxlocController = TextEditingController();
  final TextEditingController avglocController = TextEditingController();
  // Create storage
  final storage = new FlutterSecureStorage();
  bool isadmin;
  bool _nmode = true;
  String pin = '';
  String textError = '';

  @override
  void initState() {
    checkUser();
    super.initState();
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    nameController.dispose();
    minlocController.dispose();
    maxlocController.dispose();
    avglocController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Events List',
      theme: lightThemeData,
      darkTheme: darkThemeData,
      themeMode: (_nmode) ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
          appBar: AppBar(title: Text('New Event')),
          body: SingleChildScrollView(
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
                        hintText: 'Type the name of the event',
                        hintStyle: TextStyle(fontSize: 18),
                      ),
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'Please enter some text';
                        }
                        return null;
                      },
                    ),
                    Container(height: 10),
                    TextFormField(
                      controller: minlocController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Type the minimum nr. of locations',
                        hintStyle: TextStyle(fontSize: 18),
                      ),
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'Please enter some text';
                        }
                        return null;
                      },
                    ),
                    Container(height: 10),
                    TextFormField(
                      controller: maxlocController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Type the maximum nr. of locations',
                        hintStyle: TextStyle(fontSize: 18),
                      ),
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'Please enter some text';
                        }
                        return null;
                      },
                    ),
                    Container(height: 10),
                    TextFormField(
                      controller: avglocController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Type the average distance',
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
                            sendData().then((res) {
                              if (res.statusCode == HttpStatus.ok)
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => EventsPage()));
                              else
                                _buildError(context);
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
          )),
    );
  }

  void checkUser() async {
    await storage.read(key: 'theme').then((value) => setState(() {
          this._nmode = (value == 'dark');
        }));
    this.isadmin = (await storage.read(key: 'is_admin') == 'true');
    await storage.read(key: 'pin').then((value) => {this.pin = value});
  }

  Future sendData() async {
    return http.post(
      globals.url + 'event',
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: 'Basic ' + this.pin
      },
      body: jsonEncode(<String, dynamic>{
        'name': nameController.text,
        'minloc': int.parse(minlocController.text),
        'maxloc': int.parse(maxlocController.text),
        'avgloc': int.parse(avglocController.text)
      }),
    );
  }

  ScaffoldFeatureController _buildError(context) {
    return Scaffold.of(context)
        .showSnackBar(SnackBar(content: Text('Something went wrong :(')));
  }
}
