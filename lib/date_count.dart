
import 'package:sprintf/sprintf.dart';
import 'package:step_on_it/main.dart';

// Track a date with its step count
class DateCount {
	final Date date;
	int count;
	int goal;

	DateCount({required this.date, this.count = 0, this.goal = defaultGoal});

	Map<String, Object?> toMap() {
		return {'date': '$date', 'count': count, 'goal': goal};
	}

	DateCount.fromMap(Map<String, Object?> map) :
				this(date: Date.fromString(map['date']! as String),
					count: map['count']! as int,
					goal: map['goal']! as int);

	@override
  String toString() {
    return "$date $count $goal";
  }

  static DateCount fromString(String s) {
		var bits = s.split(" ");
		if (bits.length != 3) {
			throw Exception("String $s doesn't have format 'date count goal'");
		}
		return DateCount(date: Date.fromString(bits[0]),
				count: int.parse(bits[1]),
				goal: int.parse(bits[2]));

	}
}

// Mostly don't need the baggage of full DateTime class
class Date {
	final int year, month, day;
	const Date(this.year, this.month, this.day);
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

