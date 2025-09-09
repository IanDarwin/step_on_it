import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:step_on_it/step_count_db.dart';
import 'package:step_on_it/date_count.dart';

void main() async {

  late StepCountDB db;

    // Initialize FFI
    sqfliteFfiInit();
    // Change the default factory for unit testing calls for SQFlite
    databaseFactory = databaseFactoryFfi;
    StepCountDB.database = await databaseFactory.openDatabase(inMemoryDatabasePath);
    db = StepCountDB();
    await db.createTables();

    Date now = Date.today();
    print("Now = $now");

    test('find by day test', () async {
      await StepCountDB.database.insert(db.tableName, {'date':  now.toString(), 'count': 42});
      var dateCountFromDB = await db.findByDate(now);
      expect(now.year, dateCountFromDB.date.year);
      expect(now.month, dateCountFromDB.date.month);
      expect(now.day, dateCountFromDB.date.day);
      expect(42, dateCountFromDB.count);
    });


}
