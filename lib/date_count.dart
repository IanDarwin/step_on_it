
import 'package:sprintf/sprintf.dart';

// Track a date with its step count
class DateCount {
	final Date date;
	int count;

	DateCount({required this.date, this.count = 0});

	Map<String, Object?> toMap() {
		return {'date': '$date', 'count': count};
	}

	DateCount.fromMap(Map<String, Object?> map) :
				this(date: Date.fromString(map['date']! as String),
					count: map['count']! as int);
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
				this(int.parse((s).substring(0,4)),
					int.parse((s).substring(5,7)),
					int.parse(s.substring(8))
			);

	Map<String, Object?> toMap() {
		return {'date': '$year-$month-$day'};
	}

	@override
	String toString() {
		return sprintf("%4d-%02d-%02d", [year, month, day]);
	}

	bool operator ==(Object other) {
		return other is Date
				&& year == other.year
				&& month == other.month
				&& day == other.day;
	}
	int get hashCode => Object.hash(year, month, day);
}

