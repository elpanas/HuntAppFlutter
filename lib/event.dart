import 'package:flutter/material.dart';
import 'eventslist.dart';

class SingleEventPage extends StatefulWidget {
  final Event event;
  SingleEventPage(this.event);

  @override
  _SingleEventPageState createState() => _SingleEventPageState(event);
}

class _SingleEventPageState extends State<SingleEventPage> {
  final Event event;
  _SingleEventPageState(this.event);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(event.eventName + ': Games')),
        body: SingleChildScrollView());
  }
}
