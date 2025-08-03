// lib/core/models/activity_status.dart
import 'package:flutter/material.dart';

enum ActivityStatus {
  enAttente('en_attente', 'En attente', Colors.orange, Icons.schedule),
  approuve('approuve', 'Approuvé', Colors.green, Icons.check_circle),
  rejete('rejete', 'Rejeté', Colors.red, Icons.cancel);

  const ActivityStatus(this.value, this.label, this.color, this.icon);

  final String value;
  final String label;
  final Color color;
  final IconData icon;

  static ActivityStatus fromString(String value) {
    return ActivityStatus.values.firstWhere(
      (status) => status.value == value.toLowerCase(),
      orElse: () => ActivityStatus.enAttente,
    );
  }

  // ✅ Méthodes helper pour vérifier le statut
  bool get isPending => this == ActivityStatus.enAttente;
  bool get isApproved => this == ActivityStatus.approuve;
  bool get isRejected => this == ActivityStatus.rejete;
  
  // ✅ Vérifier si l'activité peut être modifiée
  bool get canEdit => this == ActivityStatus.enAttente || this == ActivityStatus.rejete;

  // ✅ Obtenir le widget chip pour l'affichage
  Widget toChip({bool showIcon = true, double fontSize = 11}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Obtenir la description du statut
  String get description {
    switch (this) {
      case ActivityStatus.enAttente:
        return 'Cette activité est en attente de validation par votre superviseur';
      case ActivityStatus.approuve:
        return 'Cette activité a été validée et approuvée par votre superviseur';
      case ActivityStatus.rejete:
        return 'Cette activité a été rejetée. Vous pouvez la modifier et la resoumetre';
    }
  }

  // ✅ Obtenir les couleurs pour le gradient
  List<Color> get gradientColors {
    switch (this) {
      case ActivityStatus.enAttente:
        return [Colors.orange[400]!, Colors.orange[600]!];
      case ActivityStatus.approuve:
        return [Colors.green[400]!, Colors.green[600]!];
      case ActivityStatus.rejete:
        return [Colors.red[400]!, Colors.red[600]!];
    }
  }
}