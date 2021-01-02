import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import 'package:huntapp/globals.dart' as globals;

class AddRiddle extends StatefulWidget {
  @override
  _AddRiddleState createState() => _AddRiddleState();
}

class _AddRiddleState extends State<AddRiddle> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController catController = TextEditingController();
  final TextEditingController typeController = TextEditingController();
  final TextEditingController paramController = TextEditingController();
  final TextEditingController solController = TextEditingController();
  // Create storage
  final storage = new FlutterSecureStorage();
  final picker = ImagePicker();
  String _image;
  String _imgName;
  String _pin = '';
  String textError = '';
  final List<String> ridCategories = ['Basic', 'Intermediate', 'Advanced'];
  final List<int> ridTypes = [1, 2, 3];
  String ridCategory = 'Basic';
  int ridType = 1;
  bool _checked = false;
  bool _showImgButton;

  @override
  void initState() {
    _showImgButton = true;
    _imgName = 'Insert an image';
    checkUser();
    super.initState();
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    catController.dispose();
    typeController.dispose();
    paramController.dispose();
    solController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('New Riddle')),
        body: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Row(children: <Widget>[
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(labelText: 'Level'),
                        value: ridCategory,
                        items: ridCategories.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String newValue) {
                          setState(() {
                            ridCategory = newValue;
                          });
                        },
                      ),
                    ),
                    Container(width: 20),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        decoration: InputDecoration(labelText: 'Type'),
                        value: ridType,
                        items: ridTypes.map((int value) {
                          return DropdownMenuItem<int>(
                            value: value,
                            child: Text(value.toString()),
                          );
                        }).toList(),
                        onChanged: (int newValue) {
                          setState(() {
                            ridType = newValue;
                          });
                        },
                      ),
                    ),
                  ]),
                  Container(height: 10),
                  TextFormField(
                    controller: paramController,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      hintText: 'Type a parameter if needed',
                      hintStyle: TextStyle(fontSize: 18),
                    ),
                  ),
                  Container(height: 10),
                  TextFormField(
                    controller: solController,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      hintText: 'Type the solution',
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
                    title: Text('Check if it is "Final"'),
                    value: _checked,
                    onChanged: (bool value) {
                      setState(() {
                        _checked = value;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  Container(child: Text(textError)),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextFormField(
                          enabled: false,
                          decoration: InputDecoration(
                            hintText: _imgName,
                            hintStyle: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                      (_showImgButton)
                          ? Ink(
                              decoration: const ShapeDecoration(
                                color: Colors.orange,
                                shape: CircleBorder(),
                              ),
                              child: IconButton(
                                  icon: Icon(
                                    Icons.image_search,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    getImage();
                                  }))
                          : IconButton(
                              icon: Icon(Icons.cancel),
                              onPressed: () {
                                setState(() {
                                  _showImgButton = true;
                                  _image = null;
                                  _imgName = 'Insert an image';
                                });
                              }),
                    ],
                  ),
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
                                  Navigator.pop(context)
                                else
                                  _buildError(context)
                              });
                        }
                      },
                      child: Text(
                        'Save Riddle',
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
  }

  void checkUser() async {
    await storage.read(key: 'pin').then((value) => _pin = value);
  }

  Future getImage() async {
    final pickedFile =
        await picker.getImage(source: ImageSource.gallery, imageQuality: 60);

    setState(() {
      if (pickedFile != null) {
        _image = pickedFile.path;
        _imgName = path.basename(_image);
        _showImgButton = false;
      } else {
        print('No image selected.');
      }
    });
  }

  Future sendData() async {
    var request =
        http.MultipartRequest('POST', Uri.parse(globals.url + 'riddle/'));

    request.fields['category'] = catController.text;
    request.fields['type'] = typeController.text;
    request.fields['param'] = paramController.text;
    request.fields['solution'] = solController.text;
    request.fields['image'] = _imgName;
    request.fields['final'] = _checked.toString();

    request.headers[HttpHeaders.authorizationHeader] = 'Basic ' + _pin;

    request.files.add(await http.MultipartFile.fromPath('rphoto', _image,
        contentType: MediaType('image', 'png')));

    return await request.send();
  }

  ScaffoldFeatureController _buildError(context) {
    return Scaffold.of(context)
        .showSnackBar(SnackBar(content: Text('Something went wrong :(')));
  }
}
