import 'package:step_on_it/date_count.dart';
import 'package:test/test.dart';

const Date date = Date(2014, 6, 10);

Future main() async {

  test('Test DateCount.toString', (){
    DateCount dc = DateCount(date: date, count: 100, goal: 5000);
    expect(dc.toString(), '2014-06-10 100 5000');
  });

  test('Test DateCount.fromString', (){
    var dc = DateCount.fromString('2014-06-10 200 2500');
    expect(date, dc.date);
    expect(200, dc.count);
    expect(2500, dc.goal);
  });

  test('Test DateCount.fromMap', () {
    var map = {'date': date.toString(), 'count': 200, 'goal': 10000};
    var d = Date.fromString(map['date'] as String);
    var dateCount = DateCount.fromMap(map);
    expect(2014, d.year);
    expect(200, dateCount.count);
    expect(10000, dateCount.goal);
  });
}
