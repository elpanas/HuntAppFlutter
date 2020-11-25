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
import 'gameslist.dart';
import 'globals.dart' as globals;

class AddLocation extends StatefulWidget {
  final Game game;
  final int cluster;

  AddLocation(this.game, this.cluster);

  @override
  _AddLocationState createState() => _AddLocationState(this.game, this.cluster);
}

enum LocationType { is_start, is_middle, is_final }

class _AddLocationState extends State<AddLocation> {
  final Game game;
  final int cluster;
  LocationResult _pickedLocation;
  String apiKey = Key("MAP_API_KEY").toString();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController hintController = TextEditingController();
  // Create storage
  final storage = new FlutterSecureStorage();
  LocationType _loctype = LocationType.is_middle;
  String textError = '';

  _AddLocationState(this.game, this.cluster);

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
      supportedLocales: const <Locale>[
        Locale('en', ''),
        Locale('ar', ''),
        Locale('pt', ''),
        Locale('tr', ''),
        Locale('es', ''),
        Locale('it', ''),
        Locale('ru', ''),
      ],
      home: Scaffold(
        appBar: AppBar(title: Text('Add New Location')),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.map),
          onPressed: () async {
            Position current = await Geolocator.getLastKnownPosition();
            LocationResult result = await showLocationPicker(
              context, "AIzaSyDsYSmcciHNv_6RJy_RzM3hmrcmfYErFkg",
              initialCenter: LatLng(current.latitude, current.longitude),
              // automaticallyAnimateToCurrentLocation: true,
              //mapStylePath: 'assets/mapStyle.json',
              myLocationButtonEnabled: true,
              // requiredGPS: true,
              layersButtonEnabled: true,
              // countries: ['AE', 'NG']

//                      resultCardAlignment: Alignment.bottomCenter,
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
                              MaterialPageRoute routeCluster =
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          ClusterPage(this.game, this.cluster));
                              Navigator.push(context, routeCluster);
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

  Future sendData() async {
    String pin = await storage.read(key: 'pin');

    http
        .post(
      globals.url + 'loc',
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: 'Basic ' + pin
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
}
