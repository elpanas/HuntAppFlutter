import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:devicelocale/devicelocale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_qr_bar_scanner/qr_bar_scanner_camera.dart';
import 'package:huntapp/addgroup.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_static_maps_controller/google_static_maps_controller.dart';
import 'package:huntapp/containers/selfiecontainer.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timer_count_down/timer_count_down.dart';
import 'package:image_picker/image_picker.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:http_parser/http_parser.dart';
import 'package:huntapp/clusterlist.dart';
import 'package:huntapp/containers/eventcontainer.dart';
import 'package:huntapp/containers/gamecontainer.dart';
import 'package:huntapp/containers/actioncontainer.dart';
import 'package:huntapp/containers/riddlecontainer.dart';
import 'package:huntapp/globals.dart' as globals;
import 'package:easy_localization/easy_localization.dart';

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
  List<Selfie> selfies = List<Selfie>();
  String _image;
  String _pin = '';
  String _idsg = '';
  Directory _dir;
  ActionClass action;
  Riddle riddle;

  bool isadmin;
  bool groupok;
  bool showActivateButton;
  bool showProgress;
  bool showWarning;
  bool showQrScanner;
  bool showPhotoButton;
  bool showLocationInfo;
  bool showRiddle;
  bool showRiddleButton;
  bool showCountDown;
  bool showCongrats;

  @override
  void initState() {
    showActivateButton = false;
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
    _requestDocDirectory();
    super.initState();
  }

  @override
  void dispose() {
    solController.dispose();
    super.dispose();
  }

  void _requestDocDirectory() {
    getApplicationSupportDirectory().then((value) => setState(() {
          _dir = value;
        }));
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
          (showLocationInfo)
              ? Padding(
                  padding: EdgeInsets.only(right: 20.0),
                  child: GestureDetector(
                      onTap: () {
                        _showHint();
                      },
                      child: Icon(Icons.live_help, size: 26.0)))
              : Container(),
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
                      child: Icon(Icons.blur_circular, size: 26.0)))
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
                if (showActivateButton && isadmin)
                  _buildActivateButton(context),
                if (showActivateButton && !isadmin) _buildWarning(),
                if (!groupok) _buildCreateButton(context),
                if (showProgress) Center(child: CircularProgressIndicator()),
                if (showWarning) _buildWarning(),
                if (groupok && showLocationInfo) _buildLocation(),
                if (groupok && showQrScanner) _buildQrCodeReader(),
                if (groupok && showQrScanner) _buildCancelButton(),
                if (groupok && showPhotoButton) _buildPhotoButton(),
                if (groupok && showRiddle) _buildRiddle(),
                if (showCountDown) _buildCounDown(),
                if (showCongrats) _buildCarousel(),
                if (showCongrats) _buildCongrats(context)
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildsubtitle() {
    return Text(
      'gameSubtitle',
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ).tr();
  }

  Widget _buildActivateButton(BuildContext context) {
    return FlatButton(
      color: Colors.orange,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      onPressed: () {
        activateGame();
      },
      child: Text(
        'gameActivate',
        style: TextStyle(color: Colors.white, fontSize: 20),
      ).tr(),
    );
  }

  Widget _buildCreateButton(BuildContext context) {
    return FlatButton(
      color: Colors.orange,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      onPressed: () {
        Navigator.push(context,
                MaterialPageRoute(builder: (context) => AddGroup(event, game)))
            .then((result) => {if (result != null) checkGroup()});
      },
      child: Text(
        'createTeam',
        style: TextStyle(color: Colors.white, fontSize: 20),
      ).tr(),
    );
  }

  Widget _buildLocation() {
    final dice = generateRandomNr(); // decide what to show
    return Column(
      children: <Widget>[
        if (action.locImage != '')
          Image.network(globals.baseurl + action.locImage),
        _buildsubtitle(),
        if (action.locImage == '')
          if ((dice % 2) == 0)
            _buildMap()
          else
            Text(
              action.locDesc,
              style: TextStyle(fontSize: 17),
            ),
        _buildQrCodeButton(),
      ],
    );
  }

  Widget _buildMap() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Center(
        child: StaticMap(
          width: MediaQuery.of(context).size.height / 1.5,
          height: MediaQuery.of(context).size.height / 2,
          scaleToDevicePixelRatio: true,
          googleApiKey: globals.mapsApiKey,
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
              color: Colors.orange,
              label: "T",
              locations: [
                Location(action.locLatitude, action.locLongitude),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showHint() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('gameHint').tr(),
          content: Text(action.locHint),
          actions: <Widget>[
            TextButton(
              child: Text(
                'gameHintOk',
                style: TextStyle(fontSize: 18, color: Colors.orange),
              ).tr(),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildQrCodeButton() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: FlatButton.icon(
        minWidth: MediaQuery.of(context).size.width / 1.3,
        icon: Icon(Icons.qr_code_scanner, color: Colors.white),
        color: Colors.orange,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        onPressed: () {
          setState(() {
            showLocationInfo = false;
            showQrScanner = true;
          });
        },
        label: Text(
          'gameScanQr',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ).tr(),
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
                showQrScanner = false;
                showLocationInfo = true;
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
          setState(() {
            showPhotoButton = false;
          });
          getImage();
        },
        label: Text(
          'gameSelfie',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ).tr(),
      ),
    );
  }

  Widget _buildRiddle() {
    print(riddle.ridSol);
    return Column(
      children: <Widget>[
        Text('gameRidTitle',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))
            .tr(),
        Image.network(globals.baseurl + riddle.ridImage,
            width: MediaQuery.of(context).size.height / 2.5,
            height: MediaQuery.of(context).size.height / 2.5),
        Divider(),
        Text(riddle.ridTxt, style: TextStyle(fontSize: 18)),
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: solController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  hintText: tr('gameHintSol'),
                  hintStyle: TextStyle(fontSize: 18),
                ),
                validator: (value) {
                  if (value.isEmpty)
                    return tr('emptyText');
                  else if (value.toLowerCase() != riddle.ridSol) {
                    setState(() {
                      showCountDown = true;
                      showRiddleButton = false;
                    });
                    return tr('gameWaitError');
                  }
                  return null;
                },
              ),
              Container(height: 10),
              (showRiddleButton)
                  ? RaisedButton(
                      onPressed: () {
                        if (_formKey.currentState.validate())
                          sendRiddle(solController.text.toLowerCase(), context);
                      },
                      //icon: Icon(Icons.save, color: Colors.white),
                      child: Text('gameSol',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 20))
                          .tr(),
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
            showCountDown = false;
            showRiddleButton = true;
            solController.clear();
          });
        });
  }

  Widget _buildCongrats(BuildContext context) {
    return Center(
      child: Column(children: [
        Container(height: 10),
        Text('gameCongrat',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
            .tr(),
        Container(height: 10),
        Text('matchDesc', style: TextStyle(fontSize: 12)).tr(),
        Divider(),
        FlatButton.icon(
            onPressed: () {
              loadCertificate(context);
              openCertificate();
            },
            minWidth: MediaQuery.of(context).size.width / 1.3,
            color: Colors.orange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            icon: Icon(
              Icons.file_download,
              color: Colors.black,
            ),
            label: Text('matchButton', style: TextStyle(color: Colors.black))
                .tr()),
        Divider(),
        Text('matchWarn', style: TextStyle(fontSize: 12)).tr(),
      ]),
    );
  }

  Widget _buildCarousel() {
    return CarouselSlider(
        items: selfies
            .map((item) => Container(
                    child: Center(
                        child: Image.network(
                  globals.baseurl + item.image,
                  fit: BoxFit.cover,
                  height: MediaQuery.of(context).size.height / 2,
                ))))
            .toList(),
        options: CarouselOptions(
          height: 300,
          aspectRatio: 16 / 9,
          viewportFraction: 0.8,
          initialPage: 0,
          enableInfiniteScroll: true,
          reverse: false,
          autoPlay: true,
          autoPlayInterval: Duration(seconds: 2),
          autoPlayAnimationDuration: Duration(milliseconds: 800),
          autoPlayCurve: Curves.fastOutSlowIn,
          enlargeCenterPage: true,
          scrollDirection: Axis.horizontal,
        ));
  }

  Widget _buildWarning() {
    return Text('gameWarn').tr();
  }

  ScaffoldFeatureController _buildError(context) {
    return Scaffold.of(context)
        .showSnackBar(SnackBar(content: Text('Something went wrong :(')));
  }

  void activateGame() {
    http.put(
      globals.url + 'game/activate/' + game.gameId,
      headers: <String, String>{
        HttpHeaders.authorizationHeader: 'Basic ' + _pin
      },
    ).then((res) => {
          if (res.statusCode == HttpStatus.ok)
            {
              setState(() {
                showActivateButton = false;
              }),
              checkMultipleGame()
            }
        });
  }

  void checkUser() async {
    await storage
        .read(key: 'pin')
        .then((value) => {_pin = value, checkActivate()});
    await storage.read(key: 'username').then((username) => {
          setState(() {
            isadmin = (username == event.userName);
          })
        });
  }

  void checkActivate() {
    if (game.gameActive)
      checkMultipleGame();
    else if (game.gameQr)
      setState(() {
        showActivateButton = true;
        showProgress = false;
      });
    else
      setState(() {
        showWarning = true;
        showProgress = false;
      });
  }

  void checkMultipleGame() {
    http.get(
      globals.url + 'sgame/multiple/' + game.gameId,
      headers: <String, String>{
        HttpHeaders.authorizationHeader: 'Basic ' + _pin
      },
    ).then((res) {
      print(res.body);
      if (res.statusCode == HttpStatus.ok)
        checkGroup();
      else
        setState(() {
          showWarning = true;
          showProgress = false;
        });
    });
  }

  void checkGroup() {
    http.get(
      globals.url + 'sgame/game/' + game.gameId,
      headers: <String, String>{
        HttpHeaders.authorizationHeader: 'Basic ' + _pin
      },
    ).then((res) {
      if (res.statusCode == 200) {
        final resJson = jsonDecode(res.body);
        setState(() {
          _idsg = resJson['_id'];
          groupok = true;
          loadStep();
        });
      } else
        setState(() {
          groupok = false;
          showProgress = false;
        });
    });
  }

  // generate a random number 0~5
  int generateRandomNr() {
    var rng = new Random();
    return rng.nextInt(6);
  }

  _qrCallback(String code) {
    setState(() {
      if (code == action.locId)
        showPhotoButton = true;
      else
        showLocationInfo = true;
      showQrScanner = false;
    });
  }

  Future getImage() async {
    final pickedFile =
        await picker.getImage(source: ImageSource.camera, imageQuality: 60);

    setState(() {
      if (pickedFile != null) {
        _image = pickedFile.path;
        showProgress = true;
        sendImage();
      } else {
        print('No image selected.');
      }
    });
  }

  void sendImage() async {
    var request =
        http.MultipartRequest('POST', Uri.parse(globals.url + 'action/gphoto'));

    request.headers[HttpHeaders.authorizationHeader] = 'Basic ' + _pin;
    request.fields['ida'] = action.actId;
    request.fields['img'] = 'selfie' + action.actId + '.jpg';
    request.files.add(await http.MultipartFile.fromPath('selfie', _image,
        contentType: MediaType('image', 'jpeg')));

    await request
        .send()
        .then((res) => {if (res.statusCode == HttpStatus.ok) setReached()});
  }

  void setReached() {
    http.put(
      globals.url + 'action/reached/' + action.actId,
      headers: <String, String>{
        HttpHeaders.authorizationHeader: 'Basic ' + _pin
      },
    ).then((res) {
      if (res.statusCode == 200) loadRiddle();
    });
    showProgress = true;
  }

  void loadStep() {
    http.get(
      globals.url + 'action/sgame/' + _idsg,
      headers: <String, String>{
        HttpHeaders.authorizationHeader: 'Basic ' + _pin
      },
    ).then((res) {
      if (res.statusCode == HttpStatus.ok) {
        final resJson = jsonDecode(res.body);
        action = ActionClass.fromJson(resJson);
        setState(() {
          action = action;
          if (action.actReach == null) {
            showLocationInfo = true;
            showProgress = false;
          } else
            loadRiddle();
        });
      }
    });
  }

  void loadRiddle() async {
    final myLocale = await Devicelocale.currentLocale;
    http.get(
      globals.url + 'action/riddle/' + action.actId + '/' + myLocale,
      headers: <String, String>{
        HttpHeaders.authorizationHeader: 'Basic ' + _pin
      },
    ).then((res) {
      if (res.statusCode == HttpStatus.ok) {
        final resJson = jsonDecode(res.body);
        riddle = Riddle.fromJson(resJson);
        setState(() {
          riddle = riddle;
          showRiddle = true;
          showProgress = false;
        });
      }
    });
    showProgress = true;
    showRiddleButton = true;
  }

  void sendRiddle(String solution, BuildContext context) {
    http
        .put(
      globals.url + 'action/solution',
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: 'Basic ' + _pin
      },
      body: jsonEncode(<String, dynamic>{
        'ida': action.actId,
        'idr': riddle.ridId,
        '_idsg': _idsg,
        'solution': solution,
        'is_final': action.isFinal
      }),
    )
        .then((res) {
      if (res.statusCode == HttpStatus.ok) {
        setState(() {
          solController.clear();
          showRiddle = false;
          if (!action.isFinal)
            loadStep();
          else
            setCompleted(context);
        });
      } else {
        setState(() {
          showRiddleButton = false;
          showCountDown = true;
        });
      }
    });
  }

  void setCompleted(BuildContext context) {
    http
        .put(
          globals.url + 'sgame/completed',
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            HttpHeaders.authorizationHeader: 'Basic ' + _pin
          },
          body: jsonEncode(<String, dynamic>{'_idsg': _idsg}),
        )
        .then((res) => {
              if (res.statusCode == HttpStatus.ok)
                {
                  loadPhotos(),
                  //loadCertificate(context),
                  showCongrats = true,
                  showProgress = false
                }
            });
  }

  void loadPhotos() {
    http.get(globals.url + 'action/selfies/' + _idsg, headers: <String, String>{
      HttpHeaders.authorizationHeader: 'Basic ' + _pin
    }).then((res) {
      if (res.statusCode == HttpStatus.ok) {
        final resJson = jsonDecode(res.body);
        selfies = resJson.map<Selfie>((json) => Selfie.fromJson(json)).toList();
        setState(() {
          selfies = selfies;
        });
      } else
        print('NO');
    });
  }

  void loadCertificate(BuildContext context) {
    http.get(
      globals.url + 'sgame/pdf/' + _idsg,
      headers: <String, String>{
        HttpHeaders.authorizationHeader: 'Basic ' + _pin
      },
    ).then((res) => {
          if (res.statusCode == HttpStatus.ok)
            {
              if (_dir != null)
                File(_dir.path + '/' + _idsg + '-certificate.pdf')
                    .writeAsBytes(res.bodyBytes),
            }
          else
            _buildError(context),
          showProgress = false
        });
    showProgress = true;
  }

  void openCertificate() {
    if (_dir != null)
      OpenFile.open(
        _dir.path + '/' + _idsg + '-certificate.pdf',
        type: 'application/pdf',
      );
  }
}
