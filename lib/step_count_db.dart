import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:step_on_it/date_count.dart';

class StepCountDB {

	final tableName = 'step_counts';

	static late Database database;

	Future<void> createTables() {
		return database.execute(
			'CREATE TABLE $tableName(id INTEGER PRIMARY KEY, date TEXT, count INTEGER)',
		);
	}

	// Opens the database and calls createTables() on it.
	void init() async {
		// Open the database and store the reference.
		database = await openDatabase(
		  // Set the path to the database. Note: Using the `join` function from the
		  // `path` package is best practice to ensure the path is correctly
		  // constructed for each platform.
		  join(await getDatabasesPath(), 'step_counts.db'),
		  version: 1,
		);
		await createTables();
	}

	Future<DateCount> findByDate(Date date) async {

		var qr = await database.query(
			tableName,
			where: 'date = ?',
			whereArgs: [date.toString()],
		);
		return DateCount.fromMap(qr.first);
	}

	Future<void> setCount(date, count) async {
		DateCount savedCount = await findByDate(date);
		if (count == null) {
			await database.insert(
				tableName,
				count.toMap(),
				conflictAlgorithm: ConflictAlgorithm.replace,
			);
		} else {
			savedCount.count = count;
			await database.update(
				tableName,
				savedCount.toMap(),
		  );
		}
		}

		Future<void> setTodayCount(int count) async {
			setCount(Date.today(), count);
		}

		Future<void> deleteCount(date) {
			throw Exception("Not written yet");
		}
}
