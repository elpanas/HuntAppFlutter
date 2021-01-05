import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:huntapp/addlocation.dart';
import 'package:huntapp/containers/eventcontainer.dart';
import 'package:huntapp/containers/gamecontainer.dart';
import 'package:huntapp/containers/locationcontainer.dart';
import 'package:huntapp/containers/optionscontainer.dart';
import 'package:huntapp/globals.dart' as globals;
import 'package:easy_localization/easy_localization.dart';

class ClusterPage extends StatefulWidget {
  final Event event;
  final Game game;
  final int cluster;
  final Opts options;
  ClusterPage(this.event, this.game, this.cluster, this.options);

  @override
  _ClusterPageState createState() =>
      _ClusterPageState(event, game, cluster, options);
}

class _ClusterPageState extends State<ClusterPage> {
  final Event event;
  final Game game;
  final int cluster;
  final Opts options;
  _ClusterPageState(this.event, this.game, this.cluster, this.options);
  final storage = new FlutterSecureStorage();
  List<Location> locations = List<Location>();
  String _pin = '';
  bool _showAddButton;
  bool _showDropMenu;
  bool _showProgress = true;
  bool _showMessage = false;
  bool _locStartFinalWarn = false;
  String message = '';
  List<int> stepsNrList = [1];
  int _stepsValue = 1;
  String _clusterInfoId;

  @override
  void initState() {
    _showAddButton = false;
    _showDropMenu = false;
    checkUser();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(
              'Cluster ' + cluster.toString() + ' ( ' + game.gameName + ')')),
      floatingActionButton: (_showAddButton)
          ? FloatingActionButton(
              child: Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                AddLocation(event, game, cluster, options)))
                    .then((result) => {
                          if (result != null)
                            {loadLocations(), loadClusterInfo()}
                        });
              },
            )
          : null,
      body: Column(
        children: <Widget>[
          if (message != '')
            Expanded(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [Text(message)]),
            ),
          if (_showDropMenu)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: DropdownButtonFormField<int>(
                decoration: InputDecoration(labelText: tr('clusterSteps')),
                value: _stepsValue,
                items: stepsNrList.map((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text(value.toString()),
                  );
                }).toList(),
                onChanged: (int newValue) {
                  setState(() {
                    _stepsValue = newValue;
                  });
                  updateClusterInfo();
                },
              ),
            ),
          if (_showMessage) _buildMessage(),
          if (_showProgress) _buildLoader(),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView.builder(
                  itemCount: locations.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Card(
                      elevation: 2,
                      child: ListTile(
                        tileColor: (locations[index].locStart ||
                                locations[index].locFinal)
                            ? Colors.indigo
                            : null,
                        onTap: () {
                          /*MaterialPageRoute routeEvent = MaterialPageRoute(
                                builder: (_) =>
                                    SingleEventPage(locations[index]));
                            Navigator.push(context, routeEvent);*/
                        },
                        leading: Icon(Icons.location_on),
                        title: Text(
                          (locations[index].locFinal)
                              ? tr('clusterFinalLoc')
                              : tr('clusterLoc',
                                  args: [(index + 1).toString()]),
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
          ),
          if (_locStartFinalWarn) _buildWarning(),
        ],
      ),
    );
  }

  Widget _buildWarning() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Text('You have to add Start and/or final locations').tr(),
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
          child: Text('nolocs').tr(),
        ),
      ),
    );
  }

  // check if the max number of locations has been reached
  void checkAddButton() {
    if (!options.isfinal || options.locnr < event.minLoc) {
      setState(() {
        _showAddButton = true;
      });
    }
  }

  void loadLocations() {
    http.get(
      globals.url + 'loc/game/' + game.gameId,
      headers: <String, String>{
        HttpHeaders.authorizationHeader: 'Basic ' + _pin
      },
    ).then((res) {
      if (res.statusCode == HttpStatus.ok) {
        final resJson = jsonDecode(res.body);
        locations =
            resJson.map<Location>((json) => Location.fromJson(json)).toList();
        setState(() {
          locations = locations
              .where((element) => element.locCluster == cluster)
              .toList();
          _showProgress = false;
        });
        try {
          if (locations.length > 1) {
            final totLocs = (locations
                        .where(
                            (element) => element.locStart || element.locFinal)
                        .length >
                    0)
                ? locations.length - 1
                : locations.length;
            generateList(totLocs);
          }
        } on Exception catch (_) {
          setState(() {
            _showMessage = true;
          });
        }
      }
    });
  }

  void generateList(int totLocs) {
    for (var i = 2; i <= totLocs; i++) stepsNrList.add(i);
    setState(() {
      stepsNrList = stepsNrList;
      _showDropMenu = true;
    });
  }

  void loadClusterInfo() {
    http.get(
      globals.url +
          'cluster/game/' +
          game.gameId +
          '/clt/' +
          cluster.toString(),
      headers: <String, String>{
        HttpHeaders.authorizationHeader: 'Basic ' + _pin
      },
    ).then((res) {
      if (res.statusCode == HttpStatus.ok) {
        final resJson = jsonDecode(res.body);

        setState(() {
          _clusterInfoId = resJson['_id'];
          _stepsValue = resJson['nr_extracted_loc'];
        });
      }
    });
  }

  void updateClusterInfo() {
    http
        .put(
          globals.url + 'cluster',
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            HttpHeaders.authorizationHeader: 'Basic ' + this._pin
          },
          body: jsonEncode(<String, dynamic>{
            'idc': this._clusterInfoId,
            'stepsnr': this._stepsValue
          }),
        )
        .then((res) => {if (res.statusCode == HttpStatus.ok) print('OK')});
  }

  void checkUser() async {
    await storage.read(key: 'pin').then((value) => {
          this._pin = value,
          loadLocations(),
          loadClusterInfo(),
          checkAddButton()
        });
  }
}
