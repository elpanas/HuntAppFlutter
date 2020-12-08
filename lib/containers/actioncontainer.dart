class ActionClass {
  String actId, actReach, locId, locImage, locDesc, locHint, locType, locGame;
  int locCluster;
  double locLatitude, locLongitude;
  bool isStart, isFinal;

  ActionClass(
      this.actId,
      this.locId,
      this.locImage,
      this.locDesc,
      this.locHint,
      this.locLatitude,
      this.locLongitude,
      this.locType,
      this.locGame,
      this.locCluster,
      this.isStart,
      this.isFinal,
      this.actReach);

  ActionClass.fromJson(Map<String, dynamic> json) {
    this.actId = json['_id'];
    this.locId = json['step']['_id'];
    this.locImage = json['step']['image_path'];
    this.locDesc = json['step']['description'];
    this.locHint = json['step']['hint'];
    this.locLatitude = json['step']['location']['coordinates'][0];
    this.locLongitude = json['step']['location']['coordinates'][1];
    this.locType = json['step']['location']['type'];
    this.locGame = json['step']['game'];
    this.locCluster = json['step']['cluster'];
    this.isStart = json['step']['is_start'];
    this.isFinal = json['step']['is_final'];
    this.actReach = json['reachedOn'];
  }
}
