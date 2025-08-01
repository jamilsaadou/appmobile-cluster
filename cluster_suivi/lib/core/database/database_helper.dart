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
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
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

// ✅ REMPLACER la création de la table activities par :
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
  }
}