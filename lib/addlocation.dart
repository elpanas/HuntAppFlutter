import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:google_map_location_picker/generated/l10n.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_map_location_picker/generated/l10n.dart'
    as location_picker;
import 'package:google_map_location_picker/google_map_location_picker.dart';
import 'package:huntapp/cluster.dart';
import 'containers/eventcontainer.dart';
import 'containers/gamecontainer.dart';
import 'containers/optionscontainer.dart';
import 'globals.dart' as globals;

class AddLocation extends StatefulWidget {
  final Event event;
  final Game game;
  final int cluster;
  final Opts options;

  AddLocation(this.event, this.game, this.cluster, this.options);

  @override
  _AddLocationState createState() =>
      _AddLocationState(this.event, this.game, this.cluster, this.options);
}

enum LocationType { is_start, is_middle, is_final }

class _AddLocationState extends State<AddLocation> {
  final Event event;
  final Game game;
  final int cluster;
  final Opts options;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController hintController = TextEditingController();
  final storage = new FlutterSecureStorage();
  LocationResult _pickedLocation;
  LocationType _loctype = LocationType.is_middle;
  String pin = '';
  String textError = '';
  bool showRadioStart;
  bool showRadioMiddle;
  bool showRadioFinal;

  _AddLocationState(this.event, this.game, this.cluster, this.options);

  @override
  void initState() {
    this.showRadioStart = false;
    this.showRadioMiddle = false;
    this.showRadioFinal = false;
    checkUser();
    super.initState();
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    nameController.dispose();
    descController.dispose();
    hintController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.orange),
      localizationsDelegates: const [
        location_picker.S.delegate,
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const <Locale>[Locale('en', ''), Locale('it', '')],
      home: Scaffold(
        appBar: AppBar(title: Text('Add New Location')),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.map),
          onPressed: () async {
            Position current = await Geolocator.getLastKnownPosition();
            LocationResult result = await showLocationPicker(
              context,
              'AIzaSyDsYSmcciHNv_6RJy_RzM3hmrcmfYErFkg',
              initialCenter: LatLng(current.latitude, current.longitude),
              myLocationButtonEnabled: true,
              layersButtonEnabled: true,
              desiredAccuracy: LocationAccuracy.best,
            );
            setState(() => _pickedLocation = result);
          },
        ),
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
                      hintText: 'Type the name of the location',
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
                    controller: descController,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      hintText: 'Type a description (Optional)',
                      hintStyle: TextStyle(fontSize: 18),
                    ),
                  ),
                  Container(height: 25),
                  TextFormField(
                    controller: hintController,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      hintText: 'Type an hint (Optional)',
                      hintStyle: TextStyle(fontSize: 18),
                    ),
                  ),
                  Container(height: 25),
                  Column(
                    children: <Widget>[
                      if (showRadioStart)
                        RadioListTile<LocationType>(
                          title: const Text('Start'),
                          value: LocationType.is_start,
                          groupValue: _loctype,
                          onChanged: (LocationType value) {
                            setState(() {
                              _loctype = value;
                            });
                          },
                        ),
                      if (showRadioMiddle)
                        RadioListTile<LocationType>(
                          title: const Text('Middle'),
                          value: LocationType.is_middle,
                          groupValue: _loctype,
                          onChanged: (LocationType value) {
                            setState(() {
                              _loctype = value;
                            });
                          },
                        ),
                      if (showRadioFinal)
                        RadioListTile<LocationType>(
                          title: const Text('Final'),
                          value: LocationType.is_final,
                          groupValue: _loctype,
                          onChanged: (LocationType value) {
                            setState(() {
                              _loctype = value;
                            });
                          },
                        )
                    ],
                  ),
                  Container(child: Text(textError)),
                  Ink(
                    decoration: const ShapeDecoration(
                      color: Colors.orange,
                      shape: CircleBorder(),
                    ),
                    child: IconButton(
                        icon: Icon(Icons.save),
                        color: Colors.white,
                        onPressed: () {
                          if (_formKey.currentState.validate()) {
                            sendData().then((value) {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => ClusterPage(
                                          this.event,
                                          this.game,
                                          this.cluster,
                                          this.options)));
                            });
                          }
                        }),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void checkLocations() {
    if (this.options.locnr == 0)
      setState(() {
        this.showRadioStart = true;
      });
    else if ((this.event.minLoc - this.options.locnr) < 1)
      setState(() {
        this.showRadioMiddle = true;
      });
    else if ((this.event.maxLoc - this.options.locnr) == 1)
      setState(() {
        this.showRadioFinal = true;
      });
    else
      setState(() {
        this.showRadioMiddle = true;
        this.showRadioFinal = true;
      });
  }

  Future sendData() async {
    http
        .post(
      globals.url + 'loc',
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: 'Basic ' + this.pin
      },
      body: jsonEncode(<String, dynamic>{
        'game_id': this.game.gameId,
        'cluster': this.cluster,
        'name': nameController.text,
        'description': descController.text,
        'hint': hintController.text,
        'is_start': (_loctype == LocationType.is_start),
        'is_final': (_loctype == LocationType.is_final),
        'location': {
          'type': "Point",
          'coordinates': [
            _pickedLocation.latLng.latitude,
            _pickedLocation.latLng.longitude
          ]
        }
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

  void checkUser() async {
    await storage.read(key: 'pin').then((value) => {this.pin = value});
  }
}