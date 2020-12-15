class Game {
  String gameId, gameName, gameOrganizer, gameRidCategory;
  bool gameQr, gameActive, gameOpen;
  Game(this.gameId, this.gameName, this.gameOrganizer, this.gameRidCategory,
      this.gameQr, this.gameActive, this.gameOpen);

  Game.fromJson(Map<String, dynamic> json) {
    this.gameId = json['_id'];
    this.gameName = json['name'];
    this.gameOrganizer = json['organizer'];
    this.gameRidCategory = json['riddle_category'];
    this.gameQr = json['qr_created'];
    this.gameActive = json['active'];
    this.gameOpen = json['is_open'];
  }
}
