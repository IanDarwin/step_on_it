import 'package:step_on_it/datestuff.dart';
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
}
