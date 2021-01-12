class Location {
  String locId, locName, locDescription, locHint, locImagepath;
  int locCluster;
  bool locStart, locFinal;

  Location(this.locId, this.locName, this.locDescription, this.locCluster,
      this.locHint, this.locImagepath, this.locStart, this.locFinal);

  Location.fromJson(Map<String, dynamic> json) {
    this.locId = json['_id'];
    this.locName = json['name'];
    this.locDescription = json['description'];
    this.locCluster = json['cluster'];
    this.locHint = json['hint'];
    this.locImagepath = json['image_path'];
    this.locStart = json['is_start'];
    this.locFinal = json['is_final'];
  }
}
