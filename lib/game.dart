import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_qr_bar_scanner/qr_bar_scanner_camera.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_static_maps_controller/google_static_maps_controller.dart';
import 'package:timer_count_down/timer_count_down.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:huntapp/clusterlist.dart';
import 'containers/eventcontainer.dart';
import 'containers/gamecontainer.dart';
import 'package:huntapp/containers/actioncontainer.dart';
import 'containers/riddlecontainer.dart';
import 'globals.dart' as globals;

class GamePage extends StatefulWidget {
  final Event event;
  final Game game;
  GamePage(this.event, this.game);

  @override
  _GamePageState createState() => _GamePageState(event, game);
}

class _GamePageState extends State<GamePage> {
  final Event event;
  final Game game;
  _GamePageState(this.event, this.game);
  final storage = new FlutterSecureStorage();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController solController = TextEditingController();
  final picker = ImagePicker();
  String _image;
  String pin = '';
  bool isadmin;
  bool groupok;
  var idsg = '';
  ActionClass action;
  Riddle riddle;

  bool showProgress;
  bool showWarning;
  bool showQrScanner;
  bool showPhotoButton;
  bool showLocationInfo;
  bool showRiddle;
  bool showRiddleButton;
  bool showCountDown;
  bool showCongrats;

  _qrCallback(String code) {
    setState(() {
      //if (code == this.action.actId) {
      this.showPhotoButton = true;
      //}
      this.showQrScanner = false;
    });
  }

  @override
  void initState() {
    isadmin = false;
    groupok = true;
    showProgress = true;
    showWarning = false;
    showLocationInfo = false;
    showQrScanner = false;
    showPhotoButton = false;
    showRiddle = false;
    showRiddleButton = false;
    showCountDown = false;
    showCongrats = false;
    checkUser();
    super.initState();
  }

  @override
  void dispose() {
    solController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(game.gameName),
        actions: <Widget>[
          /*Padding(
              padding: EdgeInsets.only(right: 20.0),
              child: GestureDetector(
                  onTap: () {}, child: Icon(Icons.edit, size: 26.0))),*/
          (isadmin)
              ? Padding(
                  padding: EdgeInsets.only(right: 20.0),
                  child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    ClusterList(this.event, this.game)));
                      },
                      child: Icon(Icons.storage, size: 26.0)))
              : Container()
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Container(),
                if (!groupok) _buildCreateButton(),
                if (showProgress) _buildLoader(),
                if (showWarning) _buildWarning(),
                if (groupok && showLocationInfo) _buildLocation(),
                if (groupok && showQrScanner) _buildQrCodeReader(),
                if (groupok && showQrScanner) _buildCancelButton(),
                if (groupok && showPhotoButton) _buildPhotoButton(),
                if (groupok && showRiddle) _buildRiddle(),
                if (showCountDown) _buildCounDown(),
                if (showCongrats) _buildCongrats()
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoader() {
    return Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildsubtitle() {
    return Text(
      'The location you have to reach:',
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildCreateButton() {
    return RaisedButton(
      color: Colors.orange,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      onPressed: () {},
      child: Text(
        'Create a team',
        style: TextStyle(color: Colors.white, fontSize: 20),
      ),
    );
  }

  Widget _buildLocation() {
    return Column(
      children: <Widget>[
        //Image.network(this.action.locImage),
        _buildsubtitle(),
        _buildMap(),
        Text(
          this.action.locDesc,
          style: TextStyle(fontSize: 18),
        ),
        _buildQrCodeButton(),
      ],
    );
  }

  Widget _buildMap() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Center(
        child: StaticMap(
          width: MediaQuery.of(context).size.height / 2,
          height: MediaQuery.of(context).size.height / 2,
          scaleToDevicePixelRatio: true,
          googleApiKey: 'AIzaSyDsYSmcciHNv_6RJy_RzM3hmrcmfYErFkg',
          styles: <MapStyle>[
            MapStyle(
              element: StyleElement.geometry.fill,
              feature: StyleFeature.landscape.natural,
              rules: <StyleRule>[
                StyleRule.color(Colors.grey),
              ],
            ),
            MapStyle(
              feature: StyleFeature.water,
              rules: <StyleRule>[
                StyleRule.color(Colors.grey),
                StyleRule.lightness(-30),
              ],
            )
          ],
          markers: <Marker>[
            Marker(
              color: Colors.lightBlue,
              label: "T",
              locations: [
                Location(this.action.locLatitude, this.action.locLongitude),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrCodeButton() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: FlatButton.icon(
        minWidth: MediaQuery.of(context).size.width / 1.2,
        icon: Icon(Icons.qr_code_scanner, color: Colors.white),
        color: Colors.orange,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        onPressed: () {
          setState(() {
            this.showLocationInfo = false;
            this.showQrScanner = true;
          });
        },
        label: Text(
          'Scan Qr Code',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
    );
  }

  Widget _buildQrCodeReader() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SizedBox(
          height: MediaQuery.of(context).size.height / 2,
          width: MediaQuery.of(context).size.height / 2,
          child: QRBarScannerCamera(
            onError: (context, error) => Text(
              error.toString(),
              style: TextStyle(color: Colors.red),
            ),
            qrCodeCallback: (code) {
              _qrCallback(code);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return Center(
        child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Ink(
        decoration: const ShapeDecoration(
          color: Colors.orange,
          shape: CircleBorder(),
        ),
        child: IconButton(
            icon: Icon(Icons.cancel),
            color: Colors.white,
            onPressed: () {
              setState(() {
                this.showQrScanner = false;
                this.showLocationInfo = true;
              });
            }),
      ),
    ));
  }

  Widget _buildPhotoButton() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: RaisedButton.icon(
        icon: Icon(Icons.camera_alt, color: Colors.white),
        color: Colors.orange,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        onPressed: () {
          getImage();
        },
        label: Text(
          'Send a selfie',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
    );
  }

  Widget _buildRiddle() {
    return Column(
      children: <Widget>[
        Text('Solve this riddle',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Image.network(globals.imageurl + this.riddle.ridImage,
            width: MediaQuery.of(context).size.height / 2.5,
            height: MediaQuery.of(context).size.height / 2.5),
        Divider(),
        Text(this.riddle.ridTxt, style: TextStyle(fontSize: 18)),
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: solController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  hintText: 'Type the solution here',
                  hintStyle: TextStyle(fontSize: 18),
                ),
                validator: (value) {
                  if (value.isEmpty)
                    return 'Please enter some text';
                  else if (value.toLowerCase() != this.riddle.ridSol) {
                    setState(() {
                      this.showCountDown = true;
                      this.showRiddleButton = false;
                    });
                    return 'Wrong! Wait for 1 minute';
                  }
                  return null;
                },
              ),
              Divider(),
              (showRiddleButton)
                  ? RaisedButton(
                      onPressed: () {
                        if (_formKey.currentState.validate())
                          sendRiddle(solController.text.toLowerCase());
                      },
                      //icon: Icon(Icons.save, color: Colors.white),
                      child: Text('Send solution',
                          style: TextStyle(color: Colors.white, fontSize: 20)),
                      color: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ))
                  : Container()
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCounDown() {
    return Countdown(
        seconds: 60,
        build: (BuildContext context, double time) => Text(
              time.toString(),
              style: TextStyle(
                fontSize: 25,
                color: Colors.grey,
              ),
            ),
        interval: Duration(milliseconds: 100),
        onFinished: () {
          setState(() {
            this.showCountDown = false;
            this.showRiddleButton = true;
            this.solController.clear();
          });
        });
  }

  Widget _buildCongrats() {
    return Center(
      child: Text('Congratulations!'),
    );
  }

  Widget _buildWarning() {
    return Text('You cannot play this game again');
  }

  Future getImage() async {
    final pickedFile =
        await picker.getImage(source: ImageSource.camera, imageQuality: 60);

    setState(() {
      this.showPhotoButton = false;
      if (pickedFile != null) {
        _image = pickedFile.path;
        print(pickedFile.path);
        this.showProgress = true;
        sendImage();
      } else {
        print('No image selected.');
      }
    });
  }

  void sendImage() async {
    var request =
        http.MultipartRequest('POST', Uri.parse(globals.url + 'action/gphoto'));

    request.headers[HttpHeaders.authorizationHeader] = 'Basic ' + this.pin;
    request.fields['ida'] = this.action.actId;
    request.fields['img'] = 'selfie' + this.action.actId + '.jpg';
    request.files.add(await http.MultipartFile.fromPath('selfie', _image,
        contentType: MediaType('image', 'jpeg')));

    await request
        .send()
        .then((res) => {if (res.statusCode == HttpStatus.ok) setReached()});
  }

  void setReached() {
    http.put(
      globals.url + 'action/reached/' + this.action.actId,
      headers: <String, String>{
        HttpHeaders.authorizationHeader: 'Basic ' + this.pin
      },
    ).then((res) {
      if (res.statusCode == 200) loadRiddle();
    });
    this.showProgress = true;
  }

  void checkUser() async {
    this.isadmin = (await storage.read(key: 'is_admin') == 'true');
    await storage
        .read(key: 'pin')
        .then((value) => {this.pin = value, checkMultipleGame()});
  }

  void checkMultipleGame() {
    http.get(
      globals.url + 'sgame/multiple/' + this.game.gameId,
      headers: <String, String>{
        HttpHeaders.authorizationHeader: 'Basic ' + this.pin
      },
    ).then((res) {
      if (res.statusCode == 200)
        setState(() {
          this.showWarning = true;
        });
      else
        checkGroup();
    });
  }

  void checkGroup() {
    http.get(
      globals.url + 'sgame/game/' + this.game.gameId,
      headers: <String, String>{
        HttpHeaders.authorizationHeader: 'Basic ' + this.pin
      },
    ).then((res) {
      if (res.statusCode == 200) {
        final resJson = jsonDecode(res.body);
        setState(() {
          this.idsg = resJson['_id'];
          this.groupok = true;
          loadStep();
        });
      } else
        setState(() {
          this.groupok = false;
        });
    });
  }

  void loadStep() {
    http.get(
      globals.url + 'action/sgame/' + this.idsg,
      headers: <String, String>{
        HttpHeaders.authorizationHeader: 'Basic ' + this.pin
      },
    ).then((res) {
      if (res.statusCode == 200) {
        final resJson = jsonDecode(res.body);
        action = ActionClass.fromJson(resJson);
        setState(() {
          action = action;
          if (this.action.actReach == null) {
            this.showLocationInfo = true;
            this.showProgress = false;
          } else
            loadRiddle();
        });
      }
    });
  }

  void loadRiddle() {
    http.get(
      globals.url + 'action/riddle/' + this.action.actId,
      headers: <String, String>{
        HttpHeaders.authorizationHeader: 'Basic ' + this.pin
      },
    ).then((res) {
      if (res.statusCode == 200) {
        final resJson = jsonDecode(res.body);
        riddle = Riddle.fromJson(resJson);
        setState(() {
          riddle = riddle;
          this.showRiddle = true;
          this.showProgress = false;
        });
      }
    });
    this.showProgress = true;
    this.showRiddleButton = true;
  }

  void sendRiddle(String solution) {
    http
        .put(
      globals.url + 'action/solution',
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: 'Basic ' + this.pin
      },
      body: jsonEncode(<String, dynamic>{
        'ida': this.action.actId,
        'idr': this.riddle.ridId,
        'idsg': this.idsg,
        'solution': solution,
        'is_final': this.action.isFinal
      }),
    )
        .then((res) {
      if (res.statusCode == 200) {
        setState(() {
          this.showRiddle = false;
          if (!this.action.isFinal)
            loadStep();
          else {
            setCompleted();
            this.showCongrats = true;
          }
        });
      } else {
        setState(() {
          this.showRiddleButton = false;
          this.showCountDown = true;
        });
      }
    });
  }

  void setCompleted() {
    http
        .put(
          globals.url + 'sgame/complete',
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            HttpHeaders.authorizationHeader: 'Basic ' + this.pin
          },
          body: jsonEncode(<String, dynamic>{'ida': this.action.actId}),
        )
        .then((res) => {if (res.statusCode == 200) {}});
  }
}