class Match {
  String matchId, gameName;
  Match(this.matchId, this.gameName);

  Match.fromJson(Map<String, dynamic> json) {
    this.matchId = json['_id'];
    this.gameName = json['game']['name'];
  }
}
