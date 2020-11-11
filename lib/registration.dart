import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:huntapp/events.dart';

class RegistrationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sign Up',
      theme: ThemeData(primarySwatch: Colors.orange),
      home: Scaffold(
        appBar: AppBar(title: Text('Sign Up')),
        body: RegistrationScreen(),
      ),
    );
  }
}

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController pswController = TextEditingController();
  final storage = new FlutterSecureStorage();
  MaterialPageRoute routeEvents =
      MaterialPageRoute(builder: (_) => EventsPage());
  String result = '';
  var _checked = false;

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    nameController.dispose();
    pswController.dispose();
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
                  hintText: 'Type the username',
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
                controller: pswController,
                keyboardType: TextInputType.visiblePassword,
                decoration: InputDecoration(
                  hintText: 'Type your password',
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
              CheckboxListTile(
                title: Text('Check if you are an organizer'),
                value: _checked,
                onChanged: (bool value) {
                  setState(() {
                    _checked = value;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: RaisedButton(
                  child: Text(
                    'Submit',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  color: Colors.orange,
                  onPressed: () {
                    if (_formKey.currentState.validate()) {
                      sendData(nameController.text, pswController.text)
                          .then((value) {
                        Navigator.push(context, routeEvents);
                      });
                    }
                  },
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0)),
                ),
              ),
              Container(child: Text(result)),
            ],
          ),
        ),
      ),
    );
  }

  void storeData(String name, String psw) async {
    // Write value
    await storage.deleteAll();
    await storage.write(
        key: 'pin', value: base64.encode(utf8.encode(name + ':' + psw)));
    await storage.write(key: 'is_admin', value: _checked.toString());
  }

  Future sendData(String name, String psw) async {
    String url = 'http://192.168.0.8:3000/api/user';

    http
        .post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8'
      },
      body: jsonEncode(<String, dynamic>{
        'username': base64.encode(utf8.encode(name)),
        'password': base64.encode(utf8.encode(psw)),
        'is_admin': _checked
      }),
    )
        .then((res) {
      if (res.statusCode == 200) {
        setState(() {
          storeData(name, psw);
          result = '';
        });
      } else
        throw Exception();
    });
    result = 'Request in progress...';
  }
}
