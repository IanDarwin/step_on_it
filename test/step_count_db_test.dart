import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:step_on_it/step_count_db.dart';
import 'package:step_on_it/date_count.dart';

void main() async {

  late StepCountDB db;

    // Initialize FFI
    sqfliteFfiInit();
    // Change the default factory for unit testing calls for SQFlite
    databaseFactory = databaseFactoryFfi; // do not inline!
    StepCountDB.database = await databaseFactory.openDatabase(inMemoryDatabasePath);
    db = StepCountDB();
    await db.createTables();

    Date now = Date.today();

    test('find by day test', () async {
      await StepCountDB.database.insert(db.tableName, {'date':  now.toString(), 'count': 42});
      var dateCountFromDB = await db.findByDate(now);
      expect(now.year, dateCountFromDB.date.year);
      expect(now.month, dateCountFromDB.date.month);
      expect(now.day, dateCountFromDB.date.day);
      expect(42, dateCountFromDB.count);
    });

  test("update date count", () async {
    Date then = Date(2028,11,07);
    await StepCountDB.database.insert(db.tableName, {'date':  then.toString(), 'count': 42});
    var dateCountFromDB = await db.findByDate(then);
    await db.setCount(then, dateCountFromDB.count+1);
    var dateCount2FromDB = await db.findByDate(then);
    expect(43, dateCount2FromDB.count);
  });

  test("find not found returns null", () async {
    expect(false, await db.existsForDate(Date.fromString("2014-06-10")));
  });

  test('setCount where already exists', () async {
    print("test not written yet!");
  });

  test('setCount where does not exist', () async {
    print("test not written yet!");
  });
}
