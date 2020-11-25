import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:huntapp/eventslist.dart';
import 'globals.dart' as globals;

class AddEventPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Add New Event',
      theme: ThemeData(primarySwatch: Colors.orange),
      home: Scaffold(
        appBar: AppBar(title: Text('Add New Event')),
        body: AddEventScreen(),
      ),
    );
  }
}

class AddEventScreen extends StatefulWidget {
  @override
  _AddEventScreenState createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController minlocController = TextEditingController();
  final TextEditingController maxlocController = TextEditingController();
  final TextEditingController avglocController = TextEditingController();
  // Create storage
  final storage = new FlutterSecureStorage();
  String textError = '';

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
              Container(height: 25),
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
              Container(height: 25),
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
              Container(height: 25),
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
                child: IconButton(
                    icon: Icon(Icons.save),
                    color: Colors.orange,
                    onPressed: () {
                      if (_formKey.currentState.validate()) {
                        sendData().then((value) {
                          if (value || value == null) {
                            MaterialPageRoute routeEvents =
                                MaterialPageRoute(builder: (_) => EventsPage());
                            Navigator.push(context, routeEvents);
                          }
                        });
                      }
                    }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future sendData() async {
    String pin = await storage.read(key: 'pin');

    http
        .post(
      globals.url + 'event',
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: 'Basic ' + pin
      },
      body: jsonEncode(<String, dynamic>{
        'name': nameController.text,
        'minloc': int.parse(minlocController.text),
        'maxloc': int.parse(maxlocController.text),
        'avgloc': int.parse(avglocController.text)
      }),
    )
        .then((res) {
      if (res.statusCode == 200) {
        setState(() {
          textError = '';
        });
      } else {
        setState(() {
          textError = 'An error has occurred';
        });
      }
    });
    // textError = 'Request in progress...';
  }
}
