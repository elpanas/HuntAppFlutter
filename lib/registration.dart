import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:huntapp/globals.dart' as globals;
import 'package:easy_localization/easy_localization.dart';

class RegistrationPage extends StatefulWidget {
  final login;

  RegistrationPage(this.login);

  @override
  _RegistrationPageState createState() => _RegistrationPageState(login);
}

class _RegistrationPageState extends State<RegistrationPage> {
  final login;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController firstController = TextEditingController();
  final TextEditingController fullController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController pswController = TextEditingController();
  final storage = FlutterSecureStorage();
  var _checked = false;
  String pin = '';
  String _title = tr('login');

  _RegistrationPageState(this.login);

  @override
  void initState() {
    setTitle();
    super.initState();
  }

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
    return Scaffold(
        appBar: AppBar(title: Text(_title)),
        body: Center(
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
                          hintText: tr('hintName'),
                          hintStyle: TextStyle(fontSize: 18),
                        ),
                        validator: (value) {
                          if (value.isEmpty) {
                            return tr('emptyText');
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
                          hintText: tr('hintSurname'),
                          hintStyle: TextStyle(fontSize: 18),
                        ),
                        validator: (value) {
                          if (value.isEmpty) {
                            return tr('emptyText');
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
                        hintText: tr('hintUser'),
                        hintStyle: TextStyle(fontSize: 18),
                      ),
                      validator: (value) {
                        if (value.isEmpty) {
                          return tr('emptyText');
                        }
                        return null;
                      },
                    ),
                    Container(height: 25),
                    TextFormField(
                      controller: pswController,
                      keyboardType: TextInputType.visiblePassword,
                      obscureText: true,
                      decoration: InputDecoration(
                        icon: Icon(Icons.lock),
                        hintText: tr('hintPassword'),
                        hintStyle: TextStyle(fontSize: 18),
                      ),
                      validator: (value) {
                        if (value.trim().isEmpty) {
                          return tr('emptyText');
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
                          'submit',
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ).tr(),
                        color: Colors.orange,
                        onPressed: () {
                          if (_formKey.currentState.validate()) {
                            if (!login) {
                              createUser(
                                      firstController.text,
                                      fullController.text,
                                      nameController.text,
                                      pswController.text)
                                  .then((res) {
                                if (res.statusCode == HttpStatus.ok) {
                                  setVars(res).then(
                                      (_) => Navigator.pop(context, true));
                                }
                              });
                            } else
                              makeLogin(nameController.text, pswController.text)
                                  .then((res) {
                                if (res.statusCode == HttpStatus.ok) {
                                  setVars(res).then(
                                      (_) => Navigator.pop(context, true));
                                } else
                                  _buildError(context);
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
        ));
  }

  ScaffoldFeatureController _buildError(context) {
    return Scaffold.of(context)
        .showSnackBar(SnackBar(content: Text('Something went wrong :(')));
  }

  void setTitle() {
    setState(() {
      if (!this.login) _title = tr('registration');
    });
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
