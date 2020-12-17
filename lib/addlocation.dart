import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:google_map_location_picker/generated/l10n.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
  String _address;
  String pin = '';
  bool showRadioStart;
  bool showRadioMiddle;
  bool showRadioFinal;
  bool showLocButton;
  bool sendok;

  _AddLocationState(this.event, this.game, this.cluster, this.options);

  @override
  void initState() {
    this.showRadioStart = false;
    this.showRadioMiddle = false;
    this.showRadioFinal = false;
    this.showLocButton = true;
    this._address = 'No position inserted';
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
      theme:
          ThemeData(primarySwatch: Colors.orange, brightness: Brightness.light),
      darkTheme: ThemeData(
        primarySwatch: Colors.orange,
        primaryColor: Colors.orange,
        brightness: Brightness.dark,
        backgroundColor: const Color(0xFF212121),
        accentColor: Colors.orangeAccent,
        accentIconTheme: IconThemeData(color: Colors.orange),
        dividerColor: Colors.black12,
      ),
      themeMode: ThemeMode.dark,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const <Locale>[Locale('en', ''), Locale('it', '')],
      home: Scaffold(
        appBar: AppBar(title: Text('New Location')),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
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
                  TextFormField(
                    controller: descController,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      hintText: 'Type a description (Optional)',
                      hintStyle: TextStyle(fontSize: 18),
                    ),
                  ),
                  TextFormField(
                    controller: hintController,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      hintText: 'Type an hint (Optional)',
                      hintStyle: TextStyle(fontSize: 18),
                    ),
                  ),
                  Container(height: 10),
                  Row(
                    children: <Widget>[
                      if (showRadioStart)
                        Expanded(
                          child: RadioListTile<LocationType>(
                            title: const Text('Start'),
                            value: LocationType.is_start,
                            groupValue: _loctype,
                            onChanged: (LocationType value) {
                              setState(() {
                                _loctype = value;
                              });
                            },
                          ),
                        ),
                      if (showRadioMiddle)
                        Expanded(
                          child: RadioListTile<LocationType>(
                            title: const Text('Middle'),
                            value: LocationType.is_middle,
                            groupValue: _loctype,
                            onChanged: (LocationType value) {
                              setState(() {
                                _loctype = value;
                              });
                            },
                          ),
                        ),
                      if (showRadioFinal)
                        Expanded(
                          child: RadioListTile<LocationType>(
                            title: const Text('Final'),
                            value: LocationType.is_final,
                            groupValue: _loctype,
                            onChanged: (LocationType value) {
                              setState(() {
                                _loctype = value;
                              });
                            },
                          ),
                        )
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextFormField(
                          enabled: false,
                          decoration: InputDecoration(
                            hintText: _address,
                            hintStyle: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                      (showLocButton)
                          ? Ink(
                              decoration: const ShapeDecoration(
                                color: Colors.orange,
                                shape: CircleBorder(),
                              ),
                              child: IconButton(
                                  icon: Icon(
                                    Icons.map,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    getPlace();
                                  }))
                          : IconButton(
                              icon: Icon(Icons.cancel),
                              onPressed: () {
                                setState(() {
                                  this.showLocButton = true;
                                  _address = null;
                                  _pickedLocation = null;
                                });
                              }),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.0),
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
                                  {
                                    this.options.locnr++,
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => ClusterPage(
                                                this.event,
                                                this.game,
                                                this.cluster,
                                                this.options)))
                                  }
                                else
                                  _buildError(context)
                              });
                        }
                      },
                      child: Text(
                        'Save Location',
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ),
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
    setState(() {
      if (this.options.locnr == 0)
        this.showRadioStart = true;
      else if (((this.event.maxLoc - this.options.locnr) == 1) &&
          (this.cluster == this.options.tot_clusters))
        this.showRadioFinal = true;
      else if (this.options.locnr < this.event.minLoc)
        this.showRadioMiddle = true;
      else {
        this.showRadioMiddle = true;
        if (this.cluster == this.options.tot_clusters)
          this.showRadioFinal = true;
      }
    });
  }

  void getPlace() async {
    Position current = await Geolocator.getLastKnownPosition();
    LocationResult result = await showLocationPicker(
        context, 'AIzaSyDsYSmcciHNv_6RJy_RzM3hmrcmfYErFkg',
        initialCenter: LatLng(current.latitude, current.longitude),
        myLocationButtonEnabled: true,
        desiredAccuracy: LocationAccuracy.best,
        mapStylePath: 'assets/styles/mapStyle.json');
    setState(() => {
          _pickedLocation = result,
          if (result != null) _address = result.address
        });
  }

  Future sendData() async {
    return http.post(
      globals.url + 'loc',
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: 'Basic ' + this.pin
      },
      body: jsonEncode(<String, dynamic>{
        'avg_distance': this.event.avgLoc,
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
    );
  }

  ScaffoldFeatureController _buildError(context) {
    return Scaffold.of(context)
        .showSnackBar(SnackBar(content: Text('Something went wrong :(')));
  }

  void checkUser() async {
    await storage
        .read(key: 'pin')
        .then((value) => {this.pin = value, checkLocations()});
  }
}
