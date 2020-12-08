class Event {
  String eventId, userId, eventName, userName;
  int minLoc, maxLoc, avgLoc;

  Event(this.eventId, this.eventName, this.minLoc, this.maxLoc, this.avgLoc,
      this.userId, this.userName);

  Event.fromJson(Map<String, dynamic> json) {
    this.eventId = json['_id'];
    this.eventName = json['name'];
    this.maxLoc = json['min_locations'];
    this.minLoc = json['max_locations'];
    this.avgLoc = json['min_avg_distance'];
    this.userId = json['organizer']['_id'];
    this.userName = json['organizer']['username'];
  }
}
