import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'globals.dart' as globals;

class RegistrationPage extends StatelessWidget {
  final login;

  RegistrationPage(this.login);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sign Up',
      theme: ThemeData(primarySwatch: Colors.orange),
      home: Scaffold(
        appBar: AppBar(
            title: (() {
          if (!login)
            Text('Registration');
          else
            Text('Login');
        }())),
        body: RegistrationScreen(login),
      ),
    );
  }
}

class RegistrationScreen extends StatefulWidget {
  final login;

  RegistrationScreen(this.login);

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState(login);
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final login;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController firstController = TextEditingController();
  final TextEditingController fullController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController pswController = TextEditingController();
  final storage = FlutterSecureStorage();
  var _checked = false;
  String pin = '';

  _RegistrationScreenState(this.login);

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    firstController.dispose();
    fullController.dispose();
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
              if (!login)
                TextFormField(
                  controller: firstController,
                  keyboardType: TextInputType.name,
                  decoration: InputDecoration(
                    hintText: 'Type your first name',
                    hintStyle: TextStyle(fontSize: 18),
                  ),
                  validator: (value) {
                    if (value.isEmpty) {
                      return 'Please enter some text';
                    }
                    return null;
                  },
                ),
              if (!login)
                TextFormField(
                  controller: fullController,
                  keyboardType: TextInputType.name,
                  decoration: InputDecoration(
                    hintText: 'Type your last name',
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
              if (!login)
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
                      if (!login) {
                        createUser(firstController.text, fullController.text,
                                nameController.text, pswController.text)
                            .then((value) {
                          Navigator.pop(context);
                        });
                      } else
                        checkUser(nameController.text, pswController.text)
                            .then((value) {
                          Navigator.pop(context);
                        });
                    }
                  },
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0)),
                ),
              ),
              //Container(child: Text(result)),
            ],
          ),
        ),
      ),
    );
  }

  Future createUser(String first, String full, String name, String psw) async {
    http
        .post(
      globals.url + 'user',
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8'
      },
      body: jsonEncode(<String, dynamic>{
        'first_name': first,
        'full_name': full,
        'username': base64.encode(utf8.encode(name)),
        'password': base64.encode(utf8.encode(psw)),
        'is_admin': _checked
      }),
    )
        .then((res) async {
      if (res.statusCode == 200) {
        await storage.deleteAll();
        await storage.write(key: 'is_admin', value: _checked.toString());
        await storage.write(key: 'first_name', value: nameController.text);
        await storage.write(
            key: 'pin', value: base64.encode(utf8.encode(name + ':' + psw)));

        setState(() {
          this.pin = base64.encode(utf8.encode(name + ':' + psw));
        });
      }
    });

    //result = 'Request in progress...';
  }

  Future checkUser(String name, String psw) async {
    http.get(
      globals.url + 'user/login',
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: 'Basic ' + pin
      },
    ).then((res) async {
      print(res.statusCode);
      if (res.statusCode == 200) {
        await storage.deleteAll();
        await storage.write(key: 'is_admin', value: _checked.toString());
        await storage.write(
            key: 'pin', value: base64.encode(utf8.encode(name + ':' + psw)));

        setState(() {
          this.pin = base64.encode(utf8.encode(name + ':' + psw));
        });
      }
    });
  }
}
