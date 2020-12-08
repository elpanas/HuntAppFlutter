class Cluster {
  int clusterNr;
  Cluster(this.clusterNr);

  Cluster.fromJson(Map<String, dynamic> json) {
    this.clusterNr = json['_id']; //cluster
  }
}
