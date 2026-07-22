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
}
