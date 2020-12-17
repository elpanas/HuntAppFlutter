import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'cluster.dart';
import 'containers/clustercontainer.dart';
import 'containers/eventcontainer.dart';
import 'containers/gamecontainer.dart';
import 'containers/locationcontainer.dart';
import 'containers/optionscontainer.dart';
import 'package:path_provider/path_provider.dart';
import 'globals.dart' as globals;
import 'package:open_file/open_file.dart';

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
  Directory dir;
  String pin = '';
  String message = '';
  String urlqrcode = '';
  int locnr;
  int minlocs;
  int maxlocs;
  bool loctype;
  bool showQrButton;
  bool showAddButton;
  bool showProgress;

  @override
  void initState() {
    checkUser();
    this.showQrButton = false;
    this.showAddButton = false;
    this.showProgress = true;
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
          this.dir = value;
        }));
  }

  void _deleteTmpDirectory() {
    if (this.dir.existsSync()) this.dir.deleteSync(recursive: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(game.gameName),
        actions: <Widget>[
          (showQrButton) ? _buildQrButton(context) : (Container()),
        ],
      ),
      floatingActionButton: (showAddButton)
          ? FloatingActionButton(
              child: Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ClusterPage(this.event, this.game,
                            clusters.length + 1, this.locOptions)));
              })
          : null,
      body: Column(
        children: [
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
                        'Cluster ' + clusters[index].clusterNr.toString(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  );
                }),
          ),
          Text(message),
          if (showProgress) _buildLoader()
        ],
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

  Widget _buildLoader() {
    return SizedBox(
      height: MediaQuery.of(context).size.height / 1.3,
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  ScaffoldFeatureController _buildError(context) {
    return Scaffold.of(context)
        .showSnackBar(SnackBar(content: Text('Something went wrong :(')));
  }

  Future requestPdf() async {
    this.showProgress = true;
    return http.get(
      globals.url + 'loc/pdf/' + this.game.gameId,
      headers: <String, String>{
        HttpHeaders.authorizationHeader: 'Basic ' + this.pin
      },
    );
  }

  void createPdf(res) {
    if (this.dir != null)
      File(this.dir.path + '/' + 'cw_qrcodes.pdf')
          .writeAsBytes(res.bodyBytes)
          .then((file) => {
                this.showProgress = false,
                OpenFile.open(this.dir.path + '/' + 'cw_qrcodes.pdf',
                    type: 'application/pdf')
              });
  }

  void setQrCodesFlag() {
    http
        .put(globals.url + 'game/qrc',
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
              HttpHeaders.authorizationHeader: 'Basic ' + this.pin
            },
            body: jsonEncode(<String, dynamic>{'idg': this.game.gameId}))
        .then((res) => {
              if (res.statusCode == HttpStatus.ok)
                {
                  setState(() {
                    this.showProgress = false;
                  })
                }
            });
  }

  void loadClusters() {
    http.get(
      globals.url + 'loc/clusters/' + this.game.gameId,
      headers: <String, String>{
        HttpHeaders.authorizationHeader: 'Basic ' + this.pin
      },
    ).then((res) {
      if (res.statusCode == 200) {
        final resJson = jsonDecode(res.body);
        clusters =
            resJson.map<Cluster>((json) => Cluster.fromJson(json)).toList();
        setState(() {
          clusters = clusters;
          this.showProgress = false;
        });
      } else {
        setState(() {
          message = 'No clusters';
          this.showProgress = false;
        });
      }
    });
  }

  void loadLocations() {
    http.get(
      globals.url + 'loc/game/' + this.game.gameId,
      headers: <String, String>{
        HttpHeaders.authorizationHeader: 'Basic ' + this.pin
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
            this.showQrButton = true;
          });
        } else {
          setState(() {
            this.showAddButton = true;
          });
        }
      } else {
        locOptions = Opts(0, false, false, 0);
        setState(() {
          this.showAddButton = true;
        });
      }
      this.showProgress = false;
    });
  }

  void checkUser() async {
    await storage
        .read(key: 'pin')
        .then((value) => {this.pin = value, loadClusters(), loadLocations()});
  }
}
