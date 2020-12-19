import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:huntapp/eventslist.dart';
import 'globals.dart' as globals;

class RegistrationPage extends StatelessWidget {
  final login;

  RegistrationPage(this.login);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sign Up',
      theme: ThemeData(primarySwatch: Colors.orange),
      darkTheme: ThemeData(
        primarySwatch: Colors.orange,
        primaryColor: Colors.orange,
        brightness: Brightness.dark,
        backgroundColor: const Color(0xFF212121),
        accentColor: Colors.orangeAccent,
        floatingActionButtonTheme:
            FloatingActionButtonThemeData(backgroundColor: Colors.orange),
        dividerColor: Colors.black12,
      ),
      themeMode: ThemeMode.dark,
      home: Scaffold(
        appBar: AppBar(title: Text('Sign Up')),
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
    return Center(
      child: SingleChildScrollView(
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
                if (!login) Container(height: 25),
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
                if (!login) Container(height: 25),
                TextFormField(
                  controller: nameController,
                  keyboardType: TextInputType.name,
                  decoration: InputDecoration(
                    icon: Icon(Icons.account_circle),
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
                    icon: Icon(Icons.lock),
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
                              .then((res) {
                            if (res.statusCode == HttpStatus.ok) {
                              setVars(res).then((_) => {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => EventsPage()))
                                  });
                            }
                          });
                        } else
                          makeLogin(nameController.text, pswController.text)
                              .then((res) {
                            if (res.statusCode == HttpStatus.ok) {
                              setVars(res).then((_) => {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => EventsPage()))
                                  });
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
      ),
    );
  }

  Future createUser(String first, String full, String name, String psw) async {
    return http.post(
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
    );
  }

  Future setVars(res) async {
    await storage.deleteAll();
    var admvalue = (!this.login) ? _checked.toString() : res.body.toString();

    await storage.write(key: 'is_admin', value: admvalue);

    await storage.write(key: 'username', value: nameController.text);
    return await storage.write(
        key: 'pin',
        value: base64.encode(
            utf8.encode(nameController.text + ':' + pswController.text)));
  }

  Future makeLogin(String name, String psw) async {
    var pin = base64.encode(utf8.encode(name + ':' + psw));
    return http.put(
      globals.url + 'user/login',
      headers: <String, String>{
        HttpHeaders.authorizationHeader: 'Basic ' + pin
      },
    );
  }
}
