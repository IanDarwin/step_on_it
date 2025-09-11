import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:step_on_it/date_count.dart';
import 'package:step_on_it/main.dart';

class StepCountDB {

	final tableName = 'step_counts';

	static late Database database;

	Future<void> createTables() {
		return database.execute(
			'CREATE TABLE IF NOT EXISTS $tableName(id INTEGER PRIMARY KEY, date TEXT, count INTEGER, goal INTEGER)',
		);
	}

	// Opens the database and calls createTables() on it.
	Future<void> init() async {
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

	Future<List<DateCount>> findAll() async {
		var qr = await database.query(
			tableName,
		);
		List<DateCount> ret = [];
		for (var rd in qr) {
			ret.add(DateCount.fromMap(rd));
		}
		return ret;
	}

	Future<bool> existsForDate(Date date) async {
		var qr = await database.query(
			tableName,
			where: 'date = ?',
			whereArgs: [date.toString()],
		);
		// print("Query for date $date found ${qr.length} elements");
		return qr.isNotEmpty;
	}

	Future<void> save(DateCount dc) async {
		await database.insert(tableName, dc.toMap());
	}

	Future<void> setCount(Date date, int count) async {

		if (!await stepCountDB.existsForDate(date)) {
			await database.insert(
				tableName,
				{'date':date.toString(), 'count': count, 'goal': defaultGoal},
				conflictAlgorithm: ConflictAlgorithm.replace,
			);
		} else {
			DateCount savedCount = await findByDate(date);
			savedCount.count = count;
			await database.update(
				tableName,
				savedCount.toMap(),
				where: 'date = ?',
				whereArgs: [date.toString()]
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
