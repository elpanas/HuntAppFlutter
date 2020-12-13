import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'globals.dart' as globals;

class AddRiddle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'New Riddle',
      theme: ThemeData(primarySwatch: Colors.orange),
      home: Scaffold(
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        appBar: AppBar(title: Text('New Riddle')),
        body: AddRiddleScreen(),
      ),
    );
  }
}

class AddRiddleScreen extends StatefulWidget {
  @override
  _AddRiddleScreenState createState() => _AddRiddleScreenState();
}

class _AddRiddleScreenState extends State<AddRiddleScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController catController = TextEditingController();
  final TextEditingController typeController = TextEditingController();
  final TextEditingController paramController = TextEditingController();
  final TextEditingController solController = TextEditingController();
  final TextEditingController imgController = TextEditingController();
  // Create storage
  final storage = new FlutterSecureStorage();
  final picker = ImagePicker();
  String _image;
  String _imgName;
  String pin = '';
  String textError = '';
  final List<String> ridCategories = ['Basic', 'Intermediate', 'Advanced'];
  final List<int> ridTypes = [1, 2, 3];
  String ridCategory = 'Basic';
  int ridType = 1;
  bool _checked = false;
  bool showImgButton;

  @override
  void initState() {
    showImgButton = true;
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
    imgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              DropdownButtonFormField<String>(
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
              Container(height: 10),
              DropdownButtonFormField<int>(
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
                  FocusScope(
                    node: FocusScopeNode(),
                    child: TextFormField(
                      controller: imgController,
                      style: theme.textTheme.subtitle1.copyWith(
                        color: theme.disabledColor,
                      ),
                      decoration: InputDecoration(
                        hintText: _imgName,
                      ),
                    ),
                  ),
                  (showImgButton)
                      ? IconButton(
                          icon: Icon(Icons.image),
                          onPressed: () {
                            getImage();
                          })
                      : IconButton(
                          icon: Icon(Icons.cancel),
                          onPressed: () {
                            setState(() {
                              this.showImgButton = true;
                              _image = null;
                              _imgName = 'Insert an image';
                            });
                          })
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
                      sendData();
                      Navigator.pop(context);
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
    );
  }

  void checkUser() async {
    await storage.read(key: 'pin').then((value) => {this.pin = value});
  }

  Future getImage() async {
    final pickedFile =
        await picker.getImage(source: ImageSource.gallery, imageQuality: 60);

    setState(() {
      this.showImgButton = false;
      if (pickedFile != null) {
        _image = pickedFile.path;
        _imgName = 'Image Inserted';
        print(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  void sendData() async {
    var request =
        http.MultipartRequest('POST', Uri.parse(globals.url + 'riddle/rphoto'));

    request.fields['category'] = catController.text;
    request.fields['type'] = typeController.text;
    request.fields['param'] = paramController.text;
    request.fields['solution'] = solController.text;
    request.fields['image'] = _image;
    request.fields['final'] = (_checked) ? 'true' : 'false';

    request.headers[HttpHeaders.authorizationHeader] = 'Basic ' + this.pin;

    request.files.add(await http.MultipartFile.fromPath('riddle', _image,
        contentType: MediaType('image', 'png')));

    await request.send();
  }
}
