import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_map_location_picker/google_map_location_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:huntapp/containers/eventcontainer.dart';
import 'package:huntapp/containers/gamecontainer.dart';
import 'package:huntapp/containers/optionscontainer.dart';
import 'package:huntapp/globals.dart' as globals;
import 'package:easy_localization/easy_localization.dart';

class AddLocation extends StatefulWidget {
  final Event event;
  final Game game;
  final int cluster;
  final bool newCluster;
  final Opts options;

  AddLocation(
      this.event, this.game, this.cluster, this.newCluster, this.options);

  @override
  _AddLocationState createState() => _AddLocationState(
      this.event, this.game, this.cluster, this.newCluster, this.options);
}

enum LocationType { is_start, is_middle, is_final }

class _AddLocationState extends State<AddLocation> {
  final Event event;
  final Game game;
  final int cluster;
  final bool newCluster;
  final Opts options;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController hintController = TextEditingController();
  final storage = new FlutterSecureStorage();
  final picker = ImagePicker();
  LocationResult _pickedLocation;
  LocationType _loctype = LocationType.is_middle;
  String _address;
  String _pin = '';
  String _image;
  String _imgName;

  bool _showImgButton;
  bool _showRadioStart;
  bool _showRadioMiddle;
  bool _showRadioFinal;
  bool _showLocButton;

  _AddLocationState(
      this.event, this.game, this.cluster, this.newCluster, this.options);

  @override
  void initState() {
    _showRadioStart = false;
    _showRadioMiddle = false;
    _showRadioFinal = false;
    _showLocButton = true;
    _showImgButton = true;
    _imgName = tr('hintImage');
    _address = tr('hintPosition');
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
    return Scaffold(
      appBar: AppBar(title: Text('newLoc').tr()),
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
                    hintText: tr('hintLoc'),
                    hintStyle: TextStyle(fontSize: 18),
                  ),
                  validator: (value) {
                    if (value.isEmpty) {
                      return tr('emptyText');
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: descController,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    hintText: tr('hintDescLoc'),
                    hintStyle: TextStyle(fontSize: 18),
                  ),
                ),
                TextFormField(
                  controller: hintController,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    hintText: tr('hintHintLoc'),
                    hintStyle: TextStyle(fontSize: 18),
                  ),
                ),
                Container(height: 10),
                Row(
                  children: <Widget>[
                    if (_showRadioStart)
                      Expanded(
                        child: RadioListTile<LocationType>(
                          title: Text('startLoc').tr(),
                          value: LocationType.is_start,
                          groupValue: _loctype,
                          onChanged: (LocationType value) {
                            setState(() {
                              _loctype = value;
                            });
                          },
                        ),
                      ),
                    if (_showRadioMiddle)
                      Expanded(
                        child: RadioListTile<LocationType>(
                          title: Text('midLoc').tr(),
                          value: LocationType.is_middle,
                          groupValue: _loctype,
                          onChanged: (LocationType value) {
                            setState(() {
                              _loctype = value;
                            });
                          },
                        ),
                      ),
                    if (_showRadioFinal)
                      Expanded(
                        child: RadioListTile<LocationType>(
                          title: Text('finalLoc').tr(),
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
                                _imgName = tr('hintImage');
                              });
                            }),
                  ],
                ),
                Container(height: 15),
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
                    (_showLocButton)
                        ? Ink(
                            decoration: const ShapeDecoration(
                              color: Colors.orange,
                              shape: CircleBorder(),
                            ),
                            child: IconButton(
                                icon: Icon(
                                  Icons.add_location,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  getPlace();
                                }))
                        : IconButton(
                            icon: Icon(Icons.cancel),
                            onPressed: () {
                              setState(() {
                                _showLocButton = true;
                                _address = tr('hintPosition');
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
                                Navigator.pop(context, true)
                              else
                                _buildError(context)
                            });
                      }
                    },
                    child: Text(
                      'saveLoc',
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ).tr(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ScaffoldFeatureController _buildError(context) {
    return Scaffold.of(context)
        .showSnackBar(SnackBar(content: Text('Something went wrong :(')));
  }

  void checkLocations() {
    setState(() {
      if (options.locnr == 0)
        _showRadioStart = true;
      else if (((event.maxLoc - options.locnr) == 1) &&
          (cluster == options.totClusters))
        _showRadioFinal = true;
      else if ((options.locnr < event.maxLoc) &&
          (cluster == options.totClusters)) {
        _showRadioMiddle = true;
        _showRadioFinal = true;
      } else if (options.locnr < event.minLoc)
        _showRadioMiddle = true;
      else {
        _showRadioMiddle = true;
        if (cluster == options.totClusters) _showRadioFinal = true;
      }
    });
  }

  void getPlace() async {
    Position current = await Geolocator.getLastKnownPosition();
    LocationResult result = await showLocationPicker(
        context, globals.mapsApiKey,
        initialCenter: LatLng(current.latitude, current.longitude),
        myLocationButtonEnabled: true,
        desiredAccuracy: LocationAccuracy.best,
        mapStylePath: 'assets/styles/mapStyle.json');
    setState(() => {
          _pickedLocation = result,
          if (result != null)
            {_address = result.address, _showLocButton = false}
        });
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
        http.MultipartRequest('POST', Uri.parse(globals.url + 'loc/'));

    request.fields['avg_distance'] = event.avgLoc.toString();
    request.fields['new_cluster'] = newCluster.toString();
    request.fields['game_id'] = game.gameId;
    request.fields['cluster'] = cluster.toString();
    request.fields['name'] = nameController.text;
    request.fields['description'] = descController.text;
    request.fields['hint'] = hintController.text;
    request.fields['is_start'] = (_loctype == LocationType.is_start).toString();
    request.fields['is_final'] = (_loctype == LocationType.is_final).toString();
    request.fields['image'] = (_imgName == tr('hintImage')) ? '' : _imgName;
    request.fields['latitude'] = _pickedLocation.latLng.latitude.toString();
    request.fields['longitude'] = _pickedLocation.latLng.longitude.toString();

    request.headers[HttpHeaders.authorizationHeader] = 'Basic ' + _pin;

    request.files.add(await http.MultipartFile.fromPath('lphoto', _image,
        contentType: MediaType('image', 'jpeg')));

    return await request.send();
  }

  /*
  Future sendData() async {
    return http.post(
      globals.url + 'loc',
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: 'Basic ' + this._pin
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
  */

  void checkUser() async {
    await storage
        .read(key: 'pin')
        .then((value) => {_pin = value, checkLocations()});
  }
}
