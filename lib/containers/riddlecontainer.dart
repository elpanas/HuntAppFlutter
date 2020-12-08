class Riddle {
  String ridId, ridTxt, ridImage, ridSol;

  Riddle(this.ridId, this.ridTxt, this.ridImage, this.ridSol);

  Riddle.fromJson(Map<String, dynamic> json) {
    this.ridId = json['idr'];
    this.ridTxt = json['text'];
    this.ridImage = json['riddle_image_path'];
    this.ridSol = json['riddle_solution'];
  }
}
