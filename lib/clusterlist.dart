import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'cluster.dart';
import 'containers/clustercontainer.dart';
import 'containers/gamecontainer.dart';
import 'containers/locationcontainer.dart';
import 'globals.dart' as globals;

class ClusterList extends StatefulWidget {
  final Game game;
  ClusterList(this.game);

  @override
  _ClusterListState createState() => _ClusterListState(game);
}

class _ClusterListState extends State<ClusterList> {
  final Game game;
  _ClusterListState(this.game);

  final storage = new FlutterSecureStorage();
  final pdf = pw.Document();
  List<Cluster> clusters = List<Cluster>();
  bool isadmin = true;
  String pin = '';
  String idsg = '';
  String message = '';
  String urlqrcode = '';
  bool showQrButton;
  bool showAddButton;
  bool showProgress;

  @override
  void initState() {
    checkUser();
    this.showQrButton = false;
    this.showAddButton = false;
    this.showProgress = true;
    super.initState();
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(game.gameName),
        actions: <Widget>[
          (showQrButton) ? _buildQrButton() : (Container()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        ClusterPage(this.game, clusters.length + 1)));
          }),
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
                                builder: (_) => ClusterPage(
                                    game, clusters[index].clusterNr)));
                      },
                      leading: Icon(Icons.adjust),
                      title: Text(
                        'Cluster nr.: ' + clusters[index].clusterNr.toString(),
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
          if (showProgress) _buildLoader()
        ],
      ),
    );
  }

  Widget _buildQrButton() {
    return Padding(
        padding: EdgeInsets.only(right: 40.0),
        child: GestureDetector(
            onTap: () {
              createPdf();
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

  void createPdf() {
    http.get(
      globals.url + 'loc/pdf/' + game.gameId,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: 'Basic ' + this.pin
      },
    ).then((res) => {
          if (res.statusCode == HttpStatus.ok)
            {print('CIAO')}
          else
            print('NOTHING')
        });
  }

  void setQrCodesFlag() {
    http
        .put(globals.url + 'game/' + game.gameId,
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
      globals.url + 'loc/game/' + game.gameId,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
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

  void checkLocationNumber() {
    http.get(
      globals.url + 'loc/checklocnr/' + game.gameId,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: 'Basic ' + this.pin
      },
    ).then((res) {
      switch (res.statusCode) {
        case 210:
          setState(() {
            this.showQrButton = true;
          });
          break;
        case 220:
          break;
        case 230:
          setState(() {
            this.showQrButton = true;
            this.showAddButton = false;
          });
          break;
      }
    });
  }

  void checkUser() async {
    this.isadmin = (await storage.read(key: 'is_admin') == 'true');
    await storage.read(key: 'pin').then(
        (value) => {this.pin = value, loadClusters(), checkLocationNumber()});
  }
}
