import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:step_on_it/database.dart';
import 'package:step_on_it/datestuff.dart';

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
      var datecountmap = await db.findByDate(now);
    });


}
