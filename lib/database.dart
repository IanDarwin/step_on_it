import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:step_on_it/datestuff.dart';

class StepCountDb {

	final tableName = 'stepcounts';

	late Database database;

	void init() async {
		// Open the database and store the reference.
		database = await openDatabase(
		  // Set the path to the database. Note: Using the `join` function from the
		  // `path` package is best practice to ensure the path is correctly
		  // constructed for each platform.
		  join(await getDatabasesPath(), 'stepcounts.db'),
		  onCreate: (db, version) {
			return db.execute(
			  'CREATE TABLE $tableName(id INTEGER PRIMARY KEY, date TEXT, count INTEGER)',
			);
		  },
		  version: 1,
		);
	}

	Future<DateCount> findByDate(String date) async {
		final db = await database;

		List<Map<String,String>> qr = await db.query(
			tableName,
			where: 'date = ?',
			whereArgs: [date],
		) as List<Map<String, String>>;
		return DateCount.fromMap(qr[0]);
	}

	Future<void> setTodayCount(int count) async {
		setCount(Date.today(), count);
	}

	Future<void> setCount(date, count) async {
		final db = await database;
		DateCount savedCount = await findByDate(date);
		if (count == null) {
			await db.insert(
				tableName,
				count.toMap(),
				conflictAlgorithm: ConflictAlgorithm.replace,
			);
		} else {
			await db.update(
			tableName,
			count.toMap(),
		  );
		}
		}

	Future<void> deleteCount(date) {
		throw Exception("Not written yet");
	}
}
