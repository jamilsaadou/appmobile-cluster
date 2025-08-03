class Activity {
  final int? id;
  final String localId;
  final String type;
  final String thematique;
  final double duree;
  final double? latitude;
  final double? longitude;
  final double? precisionMeters;
  final int hommes;
  final int femmes;
  final int jeunes;
  final String? commentaires;
  final int siteId;
  final int regionId;
  final DateTime dateCreation;
  final bool isSynced;
  final List<String>? photos;
  final String statut;
  final String? motifRefus;

  Activity({
    this.id,
    String? localId,
    required this.type,
    required this.thematique,
    required this.duree,
    this.latitude,
    this.longitude,
    this.precisionMeters,
    this.hommes = 0,
    this.femmes = 0,
    this.jeunes = 0,
    this.commentaires,
    required this.siteId,
    required this.regionId,
    DateTime? dateCreation,
    this.isSynced = false,
    this.photos,
    this.statut = 'en_attente',
    this.motifRefus,
  }) : localId = localId ?? DateTime.now().millisecondsSinceEpoch.toString(),
       dateCreation = dateCreation ?? DateTime.now();

  // ✅ MÉTHODE toMap CORRIGÉE
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'local_id': localId,
      'type': type,
      'thematique': thematique,
      'duree': duree,
      'latitude': latitude,
      'longitude': longitude,
      'precision_meters': precisionMeters,
      'hommes': hommes,
      'femmes': femmes,
      'jeunes': jeunes,
      'commentaires': commentaires,
      'site_id': siteId,
      'region_id': regionId,
      'date_creation': dateCreation.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
      'photos': photos != null ? photos!.join(',') : null,
      'statut': statut,
      'motif_refus': motifRefus,
    };
    
    // ✅ Inclure l'ID seulement s'il existe (pour les updates)
    if (id != null) {
      map['id'] = id;
    }
    
    return map;
  }

  factory Activity.fromMap(Map<String, dynamic> map) {
    return Activity(
      id: map['id'],
      localId: map['local_id'] ?? '',
      type: map['type'] ?? '',
      thematique: map['thematique'] ?? '',
      duree: (map['duree'] ?? 0.0).toDouble(),
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      precisionMeters: map['precision_meters']?.toDouble(),
      hommes: map['hommes'] ?? 0,
      femmes: map['femmes'] ?? 0,
      jeunes: map['jeunes'] ?? 0,
      commentaires: map['commentaires'],
      siteId: map['site_id'] ?? 0,
      regionId: map['region_id'] ?? 0,
      dateCreation: DateTime.parse(map['date_creation'] ?? DateTime.now().toIso8601String()),
      isSynced: (map['is_synced'] ?? 0) == 1,
      photos: map['photos'] != null && map['photos'].toString().isNotEmpty 
          ? map['photos'].toString().split(',').where((p) => p.isNotEmpty).toList()
          : null,
      statut: map['statut'] ?? 'en_attente',
      motifRefus: map['motif_refus'],
    );
  }

  // ✅ NOUVELLE MÉTHODE : Créer depuis les données de l'API
  factory Activity.fromApiJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'],
      localId: json['localId'] ?? json['id'].toString(),
      type: json['type'] ?? json['typeActivite'] ?? '',
      thematique: json['thematique'] ?? '',
      duree: (json['duree'] ?? 0).toDouble(),
      latitude: json['geolocalisation']?['lat']?.toDouble(),
      longitude: json['geolocalisation']?['lng']?.toDouble(),
      precisionMeters: json['geolocalisation']?['precision']?.toDouble(),
      hommes: json['beneficiaires']?['hommes'] ?? 0,
      femmes: json['beneficiaires']?['femmes'] ?? 0,
      jeunes: json['beneficiaires']?['jeunes'] ?? 0,
      commentaires: json['commentaires'],
      siteId: json['siteId'] ?? json['site']?['id'] ?? 0,
      regionId: json['regionId'] ?? json['region']?['id'] ?? 0,
      dateCreation: DateTime.parse(json['dateCreation'] ?? DateTime.now().toIso8601String()),
      isSynced: true,
      photos: json['photos'] != null ? List<String>.from(json['photos']) : null,
      statut: json['statut'] ?? 'en_attente',
      motifRefus: json['motifRejet'] ?? json['motifRefus'],
    );
  }

  Map<String, dynamic> toApiJson() {
    return {
      'typeActivite': type,
      'thematique': thematique,
      'regionId': regionId,
      'siteId': siteId,
      'duree': duree,
      'geolocation': {
        'latitude': latitude,
        'longitude': longitude,
      },
      'beneficiaires': {
        'hommes': hommes,
        'femmes': femmes,
        'jeunes': jeunes,
      },
      'commentaires': commentaires,
      'photos': photos ?? [],
    };
  }

  Activity copyWith({
    int? id,
    String? localId,
    String? type,
    String? thematique,
    double? duree,
    double? latitude,
    double? longitude,
    double? precisionMeters,
    int? hommes,
    int? femmes,
    int? jeunes,
    String? commentaires,
    int? siteId,
    int? regionId,
    DateTime? dateCreation,
    bool? isSynced,
    List<String>? photos,
    String? statut,
    String? motifRefus,
  }) {
    return Activity(
      id: id ?? this.id,
      localId: localId ?? this.localId,
      type: type ?? this.type,
      thematique: thematique ?? this.thematique,
      duree: duree ?? this.duree,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      precisionMeters: precisionMeters ?? this.precisionMeters,
      hommes: hommes ?? this.hommes,
      femmes: femmes ?? this.femmes,
      jeunes: jeunes ?? this.jeunes,
      commentaires: commentaires ?? this.commentaires,
      siteId: siteId ?? this.siteId,
      regionId: regionId ?? this.regionId,
      dateCreation: dateCreation ?? this.dateCreation,
      isSynced: isSynced ?? this.isSynced,
      photos: photos ?? this.photos,
      statut: statut ?? this.statut,
      motifRefus: motifRefus ?? this.motifRefus,
    );
  }

  // Méthodes helper pour les statuts
  bool get isApproved => statut == 'approuve';
  bool get isRejected => statut == 'rejete';
  bool get isPending => statut == 'en_attente';
  bool get canEdit => statut == 'en_attente' || statut == 'rejete';
}