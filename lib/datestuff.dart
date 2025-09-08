import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

// Track a date with its stepcount
class DateCount {
  final Date date;
  int count;

  DateCount({required this.date, this.count = 0});

	Map<String, Object?> toMap() {
		return {'date': '$date', 'count': count};
	}

  DateCount.fromMap(Map<String, String?> map) :
		this(date: Date.fromString(map['date']!),
	  	count: int.parse(map['count']!));
}

// Mostly don't need the baggage of full DateTime class
class Date {
	int year, month, day;
	Date(this.year, this.month, this.day);
	Date.fromDateTime(DateTime v) :
		this(v.year, v.month, v.day);
	Date.today() :
		this.fromDateTime(DateTime.now());
	Date.fromString(String s) :
			this(int.parse(s.substring(0,3)),
					int.parse(s.substring(5,7)),
					int.parse(s.substring(8,10))
					);

	Map<String, Object?> toMap() {
		return {'date': '$year-$month-$day'};
	}

	@override
  String toString() {
		return "Date($year-$month-$day)";
	}
}

