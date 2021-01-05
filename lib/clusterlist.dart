import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:huntapp/cluster.dart';
import 'package:huntapp/containers/clustercontainer.dart';
import 'package:huntapp/containers/eventcontainer.dart';
import 'package:huntapp/containers/gamecontainer.dart';
import 'package:huntapp/containers/locationcontainer.dart';
import 'package:huntapp/containers/optionscontainer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:huntapp/globals.dart' as globals;
import 'package:open_file/open_file.dart';
import 'package:easy_localization/easy_localization.dart';

class ClusterList extends StatefulWidget {
  final Event event;
  final Game game;
  ClusterList(this.event, this.game);

  @override
  _ClusterListState createState() => _ClusterListState(event, game);
}

class _ClusterListState extends State<ClusterList> {
  final Event event;
  final Game game;
  _ClusterListState(this.event, this.game);

  final storage = new FlutterSecureStorage();
  List<Cluster> clusters = List<Cluster>();
  List<Location> locations = List<Location>();
  Opts locOptions;
  Directory _dir;
  String _pin = '';
  String message = '';
  String urlqrcode = '';
  int locnr;
  int minlocs;
  int maxlocs;
  bool _showQrButton;
  bool _showAddButton;
  bool _showProgress = true;
  bool _showMessage = false;

  @override
  void initState() {
    checkUser();
    _showQrButton = false;
    _showAddButton = false;
    _requestDocDirectory();
    super.initState();
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    super.dispose();
  }

  void _requestDocDirectory() {
    getApplicationSupportDirectory().then((value) => setState(() {
          _dir = value;
        }));
  }

  void _deleteTmpDirectory() {
    if (_dir.existsSync()) _dir.deleteSync(recursive: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Clusters (' + game.gameName + ')'),
        actions: <Widget>[
          (_showQrButton) ? _buildQrButton(context) : (Container()),
        ],
      ),
      floatingActionButton: (_showAddButton)
          ? FloatingActionButton(
              child: Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ClusterPage(
                            event, game, clusters.length + 1, locOptions)));
              })
          : null,
      body: Column(
        children: [
          Container(height: 25),
          if (_showMessage) _buildMessage(),
          if (_showProgress) _buildLoader(),
          Expanded(
            child: ListView.builder(
                itemCount: clusters.length,
                itemBuilder: (BuildContext context, int index) {
                  return Card(
                    elevation: 2,
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => ClusterPage(event, game,
                                    clusters[index].clusterNr, locOptions)));
                      },
                      leading: Icon(Icons.scatter_plot),
                      title: Text(
                        'Cluster ' + (index + 1).toString(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  );
                }),
          )
        ],
      ),
    );
  }

  Widget _buildLoader() {
    return Expanded(
      child: SizedBox(
        height: MediaQuery.of(context).size.height / 1.3,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildMessage() {
    return Expanded(
      child: SizedBox(
        height: MediaQuery.of(context).size.height / 1.3,
        child: Center(
          child: Text('noclusters').tr(),
        ),
      ),
    );
  }

  Widget _buildQrButton(context) {
    return Padding(
        padding: EdgeInsets.only(right: 40.0),
        child: GestureDetector(
            onTap: () {
              requestPdf().then((res) => {
                    if (res.statusCode == HttpStatus.ok)
                      {createPdf(res), setQrCodesFlag()}
                    else
                      _buildError(context)
                  });
            },
            child: Icon(
              Icons.picture_as_pdf,
              size: 26.0,
            )));
  }

  ScaffoldFeatureController _buildError(context) {
    return Scaffold.of(context)
        .showSnackBar(SnackBar(content: Text('Something went wrong :(')));
  }

  Future requestPdf() async {
    _showProgress = true;
    return http.get(
      globals.url + 'loc/pdf/' + game.gameId,
      headers: <String, String>{
        HttpHeaders.authorizationHeader: 'Basic ' + _pin
      },
    );
  }

  void createPdf(res) {
    if (_dir != null)
      File(_dir.path + '/' + 'cw_qrcodes.pdf')
          .writeAsBytes(res.bodyBytes)
          .then((file) => {
                _showProgress = false,
                OpenFile.open(_dir.path + '/' + 'cw_qrcodes.pdf',
                    type: 'application/pdf')
              });
  }

  void setQrCodesFlag() {
    http
        .put(globals.url + 'game/qrc',
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
              HttpHeaders.authorizationHeader: 'Basic ' + _pin
            },
            body: jsonEncode(<String, dynamic>{'idg': game.gameId}))
        .then((res) => {
              if (res.statusCode == HttpStatus.ok)
                setState(() {
                  _showProgress = false;
                })
            });
  }

  void loadClusters() {
    http.get(
      globals.url + 'cluster/' + game.gameId,
      headers: <String, String>{
        HttpHeaders.authorizationHeader: 'Basic ' + _pin
      },
    ).then((res) {
      if (res.statusCode == HttpStatus.ok) {
        final resJson = jsonDecode(res.body);
        clusters =
            resJson.map<Cluster>((json) => Cluster.fromJson(json)).toList();
        setState(() {
          clusters = clusters;
          _showProgress = false;
        });
      } else {
        setState(() {
          _showMessage = true;
          _showProgress = false;
        });
      }
    });
  }

  void loadLocations() {
    http.get(
      globals.url + 'loc/game/' + this.game.gameId,
      headers: <String, String>{
        HttpHeaders.authorizationHeader: 'Basic ' + _pin
      },
    ).then((res) {
      if (res.statusCode == HttpStatus.ok) {
        final resJson = jsonDecode(res.body);
        locations =
            resJson.map<Location>((json) => Location.fromJson(json)).toList();

        var locs = locations.where((loc) => loc.locStart == true).toList();
        var locf = locations.where((loc) => loc.locFinal == true).toList();

        var locnr = locations.length;
        var isstart = (locs.length > 0) ? true : false;
        var isfinal = (locf.length > 0) ? true : false;

        locOptions = Opts(locnr, isstart, isfinal, clusters.length);

        if (locOptions.isfinal) {
          setState(() {
            _showQrButton = true;
          });
        } else {
          setState(() {
            _showAddButton = true;
          });
        }
      } else {
        locOptions = Opts(0, false, false, 0);
        setState(() {
          _showAddButton = true;
        });
      }
      _showProgress = false;
    });
  }

  void checkUser() async {
    await storage
        .read(key: 'pin')
        .then((value) => {_pin = value, loadClusters(), loadLocations()});
  }
}
