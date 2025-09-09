import 'package:step_on_it/date_count.dart';
import 'package:test/test.dart';

Future main() async {
  test('Test Date.toString', (){
    Date d = Date(2028, 2, 29);
    expect(d.toString(), '2028-02-29');
  });

  test('Test Date.fromString Feb', (){
    Date d = Date.fromString('2028-02-29');
    expect(d, Date(2028, 2, 29));
  });

  test('Test Date.fromString Dec', (){
    Date d = Date.fromString('2028-12-29');
    expect(d, Date(2028, 12, 29));
  });

  test('Test Date.fromString Feb 1', (){
    Date d = Date(2028,1,1);
    String s = d.toString();
    expect(s, '2028-01-01');
  });

  test('Test all date constructors', () {
    var golden = Date(2112,04,01);
    expect(golden, Date(2112, 04, 01));
    expect(golden, Date.fromDateTime(DateTime(2112,4,1,0,0,0)));
    expect(golden, Date.fromString('2112-04-01'));
  });
}
