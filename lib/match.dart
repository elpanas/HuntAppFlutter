import 'dart:io';
import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:huntapp/containers/matchcontainer.dart';
import 'package:huntapp/containers/selfiecontainer.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:huntapp/globals.dart' as globals;
import 'package:easy_localization/easy_localization.dart';

class MatchPage extends StatefulWidget {
  final Match match;
  MatchPage(this.match);

  @override
  _MatchPageState createState() => _MatchPageState(match);
}

class _MatchPageState extends State<MatchPage> {
  final Match match;
  _MatchPageState(this.match);
  final storage = new FlutterSecureStorage();
  List<Selfie> selfies = List<Selfie>();
  String _pin = '';
  String message = '';
  Directory _dir;
  bool showProgress;
  bool showCongrats;

  @override
  void initState() {
    showProgress = true;
    showCongrats = false;
    _requestDocDirectory();
    checkUser();
    super.initState();
  }

  void _requestDocDirectory() {
    getApplicationSupportDirectory().then(
      (value) => setState(() {
        _dir = value;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(match.gameName)),
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Container(),
                  if (showProgress) Center(child: CircularProgressIndicator()),
                  if (showCongrats) _buildCarousel(),
                  if (showCongrats) _buildCongrats(context)
                ],
              ),
            ),
          ),
        ));
  }

  Widget _buildCongrats(BuildContext context) {
    return Center(
      child: Column(children: [
        Container(height: 20),
        Text('matchDesc', style: TextStyle(fontSize: 12)).tr(),
        Divider(),
        FlatButton.icon(
            onPressed: () {
              openCertificate(context);
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
        Text('matchWarn', style: TextStyle(fontSize: 12)).tr()
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
          height: MediaQuery.of(context).size.height / 2,
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

  ScaffoldFeatureController _buildError(context) {
    return Scaffold.of(context)
        .showSnackBar(SnackBar(content: Text('Something went wrong :(')));
  }

  void checkUser() async {
    await storage.read(key: 'pin').then((value) =>
        {_pin = value, showCongrats = true, loadPhotos(), loadCertificate()});
  }

  void loadPhotos() {
    http.get(globals.url + 'action/selfies/' + match.matchId,
        headers: <String, String>{
          HttpHeaders.authorizationHeader: 'Basic ' + _pin
        }).then((res) {
      if (res.statusCode == HttpStatus.ok) {
        final resJson = jsonDecode(res.body);
        selfies = resJson.map<Selfie>((json) => Selfie.fromJson(json)).toList();
        setState(() {
          selfies = selfies;
          showProgress = false;
        });
      } else
        print('NO');
    });
  }

  void loadCertificate() {
    http.get(
      globals.url + 'sgame/pdf/' + this.match.matchId,
      headers: <String, String>{
        HttpHeaders.authorizationHeader: 'Basic ' + _pin
      },
    ).then((res) => {
          if (res.statusCode == HttpStatus.ok)
            {
              if (_dir != null)
                File(_dir.path + '/' + match.matchId + '-certificate.pdf')
                    .writeAsBytes(res.bodyBytes),
            }
          else
            _buildError(context)
        });
  }

  void openCertificate(BuildContext context) {
    if (_dir != null)
      OpenFile.open(
        _dir.path + '/' + match.matchId + '-certificate.pdf',
        type: 'application/pdf',
      );
    else
      _buildError(context);
  }
}
