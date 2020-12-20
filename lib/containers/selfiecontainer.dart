class Selfie {
  String image;
  Selfie(this.image);

  Selfie.fromJson(Map<String, dynamic> json) {
    this.image = json['group_photo']; //selfie remote path
  }
}
