import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:woofer/services/history_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late HistoryService svc;

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    svc = HistoryService(db);
    await svc.init();
  });

  tearDown(() => db.close());

  HistoryEntry entry(String url, {String? title, int? size, DateTime? at}) =>
      HistoryEntry(
        title: title,
        thumbnail: 'thumb/$url',
        sourceUrl: url,
        filePath: '/downloads/$url.mp4',
        format: 'mp4',
        size: size,
        createdAt: at,
      );

  test('add assigns an id and getAll round-trips every field', () async {
    final at = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final id = await svc.add(entry('a', title: 'Clip A', size: 4096, at: at));
    expect(id, greaterThan(0));

    final all = await svc.getAll();
    expect(all, hasLength(1));
    final e = all.single;
    expect(e.id, id);
    expect(e.title, 'Clip A');
    expect(e.thumbnail, 'thumb/a');
    expect(e.sourceUrl, 'a');
    expect(e.filePath, '/downloads/a.mp4');
    expect(e.format, 'mp4');
    expect(e.size, 4096);
    expect(e.createdAt, at);
  });

  test('nullable columns persist as null', () async {
    await svc.add(HistoryEntry(sourceUrl: 'u', filePath: '/f.mp3'));
    final e = (await svc.getAll()).single;
    expect(e.title, isNull);
    expect(e.thumbnail, isNull);
    expect(e.format, isNull);
    expect(e.size, isNull);
  });

  test('getAll returns newest first', () async {
    await svc.add(entry('old', at: DateTime(2020)));
    await svc.add(entry('new', at: DateTime(2024)));
    await svc.add(entry('mid', at: DateTime(2022)));
    final urls = (await svc.getAll()).map((e) => e.sourceUrl).toList();
    expect(urls, ['new', 'mid', 'old']);
  });

  test('delete removes only the target row', () async {
    final id1 = await svc.add(entry('one'));
    await svc.add(entry('two'));
    expect(await svc.delete(id1), 1);
    final urls = (await svc.getAll()).map((e) => e.sourceUrl).toList();
    expect(urls, ['two']);
  });

  test('delete of a missing id removes nothing', () async {
    await svc.add(entry('one'));
    expect(await svc.delete(9999), 0);
    expect(await svc.getAll(), hasLength(1));
  });

  test('clear empties the table and reports the count', () async {
    await svc.add(entry('one'));
    await svc.add(entry('two'));
    expect(await svc.clear(), 2);
    expect(await svc.getAll(), isEmpty);
  });

  test('the v2 fields round-trip', () async {
    await svc.add(
      HistoryEntry(
        sourceUrl: 'u',
        filePath: '/f.webm',
        format: '3840x2160',
        kind: MediaKind.video,
        mimeType: 'video/webm',
        ext: 'webm',
        formatId: '313+251',
      ),
    );
    final e = (await svc.getAll()).single;
    expect(e.kind, MediaKind.video);
    expect(e.mimeType, 'video/webm');
    expect(e.ext, 'webm');
    expect(e.formatId, '313+251');
  });

  test('an explicit kind beats what the label looks like', () async {
    // "mp4" in the label would sniff as video; the stored kind is what counts.
    await svc.add(
      HistoryEntry(
        sourceUrl: 'u',
        filePath: '/f.mp3',
        format: 'mp4 audio',
        kind: MediaKind.audio,
      ),
    );
    expect((await svc.getAll()).single.kind, MediaKind.audio);
  });

  test('a row with no stored kind falls back to the label', () {
    final video = HistoryEntry.fromMap({
      'source_url': 'u',
      'file_path': '/f',
      'format': '1920x1080',
      'created_at': 0,
    });
    final audio = HistoryEntry.fromMap({
      'source_url': 'u',
      'file_path': '/f',
      'format': 'medium',
      'created_at': 0,
    });
    expect(video.kind, MediaKind.video);
    expect(audio.kind, MediaKind.audio);
  });

  // What yt-dlp actually reports, and so what v1 history actually stored.
  test('kindFromLegacyLabel sniffs a resolution or mp4 as video', () {
    expect(kindFromLegacyLabel('1080p'), MediaKind.video);
    expect(kindFromLegacyLabel('720p · MP4'), MediaKind.video);
    expect(kindFromLegacyLabel('1920x1080'), MediaKind.video);
    expect(kindFromLegacyLabel('192x144'), MediaKind.video);
    expect(kindFromLegacyLabel('192×144'), MediaKind.video);
    expect(kindFromLegacyLabel('MP3 · 192 kbps'), MediaKind.audio);
    expect(kindFromLegacyLabel('audio only'), MediaKind.audio);
    expect(kindFromLegacyLabel('medium'), MediaKind.audio);
    expect(kindFromLegacyLabel(null), MediaKind.audio);
  });

  group('upgrade from schema v1', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('woofer_hist_'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('keeps old rows, backfills kind, and bumps the version', () async {
      final path = '${dir.path}/old.db';
      // A database exactly as the shipped v1 app left it.
      final old = await databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, _) => db.execute('''
            CREATE TABLE history (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT,
              thumbnail TEXT,
              source_url TEXT NOT NULL,
              file_path TEXT NOT NULL,
              format TEXT,
              size INTEGER,
              created_at INTEGER NOT NULL
            )
          '''),
        ),
      );
      await old.insert('history', {
        'title': 'Old video',
        'source_url': 'https://youtu.be/v',
        'file_path': 'content://media/1',
        'format': '1920x1080',
        'size': 100,
        'created_at': 2,
      });
      await old.insert('history', {
        'title': 'Old song',
        'source_url': 'https://youtu.be/s',
        'file_path': 'content://media/2',
        'format': 'medium',
        'size': 50,
        'created_at': 1,
      });
      await old.close();

      final upgraded = await HistoryService.open(path);
      final rows = await upgraded.getAll();

      expect(rows.map((r) => r.title), ['Old video', 'Old song']);
      expect(rows.map((r) => r.kind), [MediaKind.video, MediaKind.audio]);
      expect(rows.every((r) => r.mimeType == null), isTrue);
      expect(rows.every((r) => r.ext == null && r.formatId == null), isTrue);
      expect(rows.first.size, 100); // existing columns untouched

      // The new columns really exist and take writes on the upgraded file.
      await upgraded.add(
        HistoryEntry(
          sourceUrl: 'n',
          filePath: '/n',
          kind: MediaKind.audio,
          mimeType: 'audio/mpeg',
        ),
      );
      expect((await upgraded.getAll()).first.mimeType, 'audio/mpeg');
      await upgraded.close();

      final db = await databaseFactory.openDatabase(path);
      final version = await db.getVersion();
      // The column itself, not HistoryEntry.kind: reading falls back to the
      // label, which would hide a migration that forgot to backfill.
      final stored = await db.query('history', columns: ['kind'], orderBy: 'id');
      await db.close();
      expect(stored.map((r) => r['kind']).take(2), ['video', 'audio']);
      expect(version, HistoryService.schemaVersion);
      expect(HistoryService.schemaVersion, 2);
    });
  });
}
