class Site {
  final int? id;
  final String nom;
  final String commune;
  final String village;
  final double superficie;
  final int regionId;
  final String? regionNom;
  final bool isSynced;

  Site({
    this.id,
    required this.nom,
    required this.commune,
    required this.village,
    required this.superficie,
    required this.regionId,
    this.regionNom,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'commune': commune,
      'village': village,
      'superficie': superficie,
      'region_id': regionId,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory Site.fromMap(Map<String, dynamic> map) {
    return Site(
      id: map['id'],
      nom: map['nom'],
      commune: map['commune'],
      village: map['village'],
      superficie: map['superficie']?.toDouble() ?? 0.0,
      regionId: map['region_id'],
      isSynced: map['is_synced'] == 1,
    );
  }

  factory Site.fromApi(Map<String, dynamic> json) {
    return Site(
      id: json['id'],
      nom: json['nom'],
      commune: json['commune'],
      village: json['village'],
      superficie: json['superficie']?.toDouble() ?? 0.0,
      regionId: json['regionId'],
      regionNom: json['region']?['nom'],
      isSynced: true,
    );
  }

  String get fullLocation => '$village, $commune';
}