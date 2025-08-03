import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'conseiller_app.db');

    return await openDatabase(
      path,
      version: 2, // ← AUGMENTER LA VERSION POUR FORCER LA MIGRATION
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // ← AJOUTER LA MIGRATION
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    print('🏗️ [DB] Création de la base de données version $version');
    
    // Table pour les utilisateurs
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY,
        prenom TEXT NOT NULL,
        nom TEXT NOT NULL,
        email TEXT NOT NULL,
        role TEXT NOT NULL,
        regions TEXT
      )
    ''');

    // Table pour les sites
    await db.execute('''
      CREATE TABLE sites (
        id INTEGER PRIMARY KEY,
        nom TEXT NOT NULL,
        commune TEXT NOT NULL,
        village TEXT NOT NULL,
        superficie REAL NOT NULL,
        region_id INTEGER,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    // ✅ Table activities CORRIGÉE avec tous les champs
    await db.execute('''
      CREATE TABLE activities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        local_id TEXT UNIQUE NOT NULL,
        type TEXT NOT NULL,
        thematique TEXT NOT NULL,
        duree REAL NOT NULL,
        latitude REAL,
        longitude REAL,
        precision_meters REAL,
        hommes INTEGER DEFAULT 0,
        femmes INTEGER DEFAULT 0,
        jeunes INTEGER DEFAULT 0,
        commentaires TEXT,
        site_id INTEGER,
        region_id INTEGER,
        date_creation TEXT,
        is_synced INTEGER DEFAULT 0,
        photos TEXT,
        statut TEXT DEFAULT 'en_attente',
        motif_refus TEXT
      )
    ''');
    
    print('✅ [DB] Tables créées avec succès');
  }

  // ✅ MIGRATION pour les bases existantes
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('🔄 [DB] Migration de version $oldVersion vers $newVersion');
    
    if (oldVersion < 2) {
      try {
        // Vérifier si les colonnes existent déjà
        final tableInfo = await db.rawQuery('PRAGMA table_info(activities)');
        final columnNames = tableInfo.map((col) => col['name'] as String).toList();
        
        print('📊 [DB] Colonnes existantes: $columnNames');
        
        // Ajouter la colonne statut si elle n'existe pas
        if (!columnNames.contains('statut')) {
          await db.execute('ALTER TABLE activities ADD COLUMN statut TEXT DEFAULT "en_attente"');
          print('✅ [DB] Colonne statut ajoutée');
        }
        
        // Ajouter la colonne motif_refus si elle n'existe pas
        if (!columnNames.contains('motif_refus')) {
          await db.execute('ALTER TABLE activities ADD COLUMN motif_refus TEXT');
          print('✅ [DB] Colonne motif_refus ajoutée');
        }
        
        // Mettre à jour les activités existantes avec le statut par défaut
        await db.execute('''
          UPDATE activities 
          SET statut = 'en_attente' 
          WHERE statut IS NULL OR statut = ''
        ''');
        
        print('✅ [DB] Migration terminée avec succès');
      } catch (e) {
        print('💥 [DB] Erreur migration: $e');
      }
    }
  }

  // ✅ MÉTHODE pour réinitialiser complètement la base
  Future<void> resetDatabase() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, 'conseiller_app.db');
      
      // Fermer la base actuelle
      if (_database != null) {
        await _database!.close();
        _database = null;
      }
      
      // Supprimer l'ancienne base
      await deleteDatabase(path);
      print('🗑️ [DB] Base de données supprimée');
      
      // La prochaine ouverture créera une nouvelle base
      print('✅ [DB] Prêt pour la recréation');
    } catch (e) {
      print('💥 [DB] Erreur reset: $e');
    }
  }

  // ✅ MÉTHODE pour vérifier la structure de la table
  Future<void> debugTableStructure() async {
    try {
      final db = await database;
      final tableInfo = await db.rawQuery('PRAGMA table_info(activities)');
      
      print('🔍 [DB] Structure de la table activities:');
      for (final column in tableInfo) {
        print('   - ${column['name']}: ${column['type']} (nullable: ${column['notnull'] == 0})');
      }
    } catch (e) {
      print('💥 [DB] Erreur debug: $e');
    }
  }
}