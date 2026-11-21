import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:sqflite/sqflite.dart';

/// Whether a saved download is video or audio. Stored explicitly since schema v2.
enum MediaKind { video, audio }

/// Best-effort kind for a row written before schema v2, which stored only a
/// display label. The old controller stored `resolution ?? note ?? formatId`, and
/// yt-dlp's `resolution` is `WxH` ("1920x1080") — a bare "1080p" only shows up
/// when the site gave a height and no resolution. It is null for audio-only
/// formats, so audio rows fall through to a note ("medium", "128k") and match
/// nothing here. Used to backfill the column in [HistoryService.migrate] and as
/// the fallback for a row whose `kind` is missing.
MediaKind kindFromLegacyLabel(String? label) {
  if (label == null) return MediaKind.audio;
  final video = RegExp(
    r'\d{2,4}\s*[x×]\s*\d{2,4}|\d{3,4}p\b|\bmp4\b|\bvideo\b|\bhd\b',
    caseSensitive: false,
  ).hasMatch(label);
  return video ? MediaKind.video : MediaKind.audio;
}

/// One completed download, persisted in the local history table.
class HistoryEntry {
  final int? id; // null until inserted; assigned by SQLite
  final String? title;
  final String? thumbnail;
  final String sourceUrl;
  final String filePath;
  final String? format; // display label only; use [kind] for audio vs video
  final int? size; // bytes
  final DateTime createdAt;
  final MediaKind kind;
  final String? mimeType; // what the file was saved as; null on pre-v2 rows
  final String? ext;
  final String? formatId; // yt-dlp's format id for the stream that was chosen

  HistoryEntry({
    this.id,
    this.title,
    this.thumbnail,
    required this.sourceUrl,
    required this.filePath,
    this.format,
    this.size,
    DateTime? createdAt,
    MediaKind? kind,
    this.mimeType,
    this.ext,
    this.formatId,
  }) : createdAt = createdAt ?? DateTime.now(),
       kind = kind ?? kindFromLegacyLabel(format);

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'thumbnail': thumbnail,
        'source_url': sourceUrl,
        'file_path': filePath,
        'format': format,
        'size': size,
        'created_at': createdAt.millisecondsSinceEpoch,
        'kind': kind.name,
        'mime_type': mimeType,
        'ext': ext,
        'format_id': formatId,
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
        kind: MediaKind.values.asNameMap()[m['kind']] ??
            kindFromLegacyLabel(m['format'] as String?),
        mimeType: m['mime_type'] as String?,
        ext: m['ext'] as String?,
        formatId: m['format_id'] as String?,
      );
}

/// Local download history backed by sqflite.
///
/// Takes an open [Database] so tests can inject an in-memory one; production
/// callers use [open]. Call [init] once before use (or let [open] do it).
class HistoryService {
  static const String table = 'history';

  /// Bump with every schema change AND extend [migrate] to match.
  static const int schemaVersion = 2;

  final Database _db;
  HistoryService(this._db);

  /// Open the on-device database and create the table if needed.
  static Future<HistoryService> open([String? path]) async {
    final db = await openDatabase(
      path ?? '${await getDatabasesPath()}/woofer_history.db',
      version: schemaVersion,
      onCreate: (db, _) => db.execute(_createTableSql),
      onUpgrade: (db, from, _) => migrate(db, from),
    );
    return HistoryService(db);
  }

  /// Bring a database at version [from] up to [schemaVersion]. sqflite already
  /// runs `onUpgrade` inside a transaction, so a failure leaves the old schema.
  @visibleForTesting
  static Future<void> migrate(Database db, int from) async {
    if (from < 2) {
      for (final col in const ['kind', 'mime_type', 'ext', 'format_id']) {
        await db.execute('ALTER TABLE $table ADD COLUMN $col TEXT');
      }
      // Old rows only have a label; infer once, store it, and stop guessing.
      final rows = await db.query(table, columns: ['id', 'format']);
      for (final r in rows) {
        await db.update(
          table,
          {'kind': kindFromLegacyLabel(r['format'] as String?).name},
          where: 'id = ?',
          whereArgs: [r['id']],
        );
      }
    }
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
      created_at INTEGER NOT NULL,
      kind TEXT,
      mime_type TEXT,
      ext TEXT,
      format_id TEXT
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

  /// Release the database file (tests open real files and must delete them).
  Future<void> close() => _db.close();
}
