class Game {
  String gameId, gameName;
  Game(this.gameId, this.gameName);

  Game.fromJson(Map<String, dynamic> json) {
    this.gameId = json['_id'];
    this.gameName = json['name'];
  }
}
