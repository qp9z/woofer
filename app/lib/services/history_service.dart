import 'package:sqflite/sqflite.dart';

/// One completed download, persisted in the local history table.
class HistoryEntry {
  final int? id; // null until inserted; assigned by SQLite
  final String? title;
  final String? thumbnail;
  final String sourceUrl;
  final String filePath;
  final String? format;
  final int? size; // bytes
  final DateTime createdAt;

  HistoryEntry({
    this.id,
    this.title,
    this.thumbnail,
    required this.sourceUrl,
    required this.filePath,
    this.format,
    this.size,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'thumbnail': thumbnail,
        'source_url': sourceUrl,
        'file_path': filePath,
        'format': format,
        'size': size,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory HistoryEntry.fromMap(Map<String, Object?> m) => HistoryEntry(
        id: m['id'] as int?,
        title: m['title'] as String?,
        thumbnail: m['thumbnail'] as String?,
        sourceUrl: m['source_url'] as String,
        filePath: m['file_path'] as String,
        format: m['format'] as String?,
        size: (m['size'] as num?)?.toInt(),
        createdAt:
            DateTime.fromMillisecondsSinceEpoch((m['created_at'] as num).toInt()),
      );
}

/// Local download history backed by sqflite.
///
/// Takes an open [Database] so tests can inject an in-memory one; production
/// callers use [open]. Call [init] once before use (or let [open] do it).
class HistoryService {
  static const String table = 'history';

  final Database _db;
  HistoryService(this._db);

  /// Open the on-device database and create the table if needed.
  static Future<HistoryService> open([String? path]) async {
    final db = await openDatabase(
      path ?? '${await getDatabasesPath()}/woofer_history.db',
      version: 1,
      onCreate: (db, _) => db.execute(_createTableSql),
    );
    return HistoryService(db);
  }

  static const String _createTableSql = '''
    CREATE TABLE IF NOT EXISTS $table (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT,
      thumbnail TEXT,
      source_url TEXT NOT NULL,
      file_path TEXT NOT NULL,
      format TEXT,
      size INTEGER,
      created_at INTEGER NOT NULL
    )
  ''';

  /// Idempotent — safe to call on an injected database.
  Future<void> init() => _db.execute(_createTableSql);

  /// Insert [entry]; returns the new row id.
  Future<int> add(HistoryEntry entry) => _db.insert(table, entry.toMap());

  /// All entries, newest first.
  Future<List<HistoryEntry>> getAll() async {
    final rows = await _db.query(table, orderBy: 'created_at DESC, id DESC');
    return rows.map(HistoryEntry.fromMap).toList();
  }

  /// Delete one entry by id; returns rows removed (0 or 1).
  Future<int> delete(int id) =>
      _db.delete(table, where: 'id = ?', whereArgs: [id]);

  /// Remove every entry; returns rows removed.
  Future<int> clear() => _db.delete(table);
}
