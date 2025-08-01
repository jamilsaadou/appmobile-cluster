import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class MigrationHelper {
  static Future<void> migrateToVersion2() async {
    final db = await DatabaseHelper().database;
    
    try {
      // Vérifier si les colonnes existent déjà
      final tableInfo = await db.rawQuery('PRAGMA table_info(activities)');
      final columnNames = tableInfo.map((col) => col['name'] as String).toList();
      
      // Ajouter la colonne statut si elle n'existe pas
      if (!columnNames.contains('statut')) {
        await db.execute('ALTER TABLE activities ADD COLUMN statut TEXT DEFAULT "en_attente"');
        print('✅ Colonne statut ajoutée');
      }
      
      // Ajouter la colonne motif_refus si elle n'existe pas
      if (!columnNames.contains('motif_refus')) {
        await db.execute('ALTER TABLE activities ADD COLUMN motif_refus TEXT');
        print('✅ Colonne motif_refus ajoutée');
      }
      
      // Mettre à jour les activités existantes avec le statut par défaut
      await db.execute('''
        UPDATE activities 
        SET statut = 'en_attente' 
        WHERE statut IS NULL OR statut = ''
      ''');
      
      print('✅ Migration terminée avec succès');
    } catch (e) {
      print('💥 Erreur migration: $e');
    }
  }
}