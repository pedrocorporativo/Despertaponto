import 'package:flutter_test/flutter_test.dart';
import 'package:despertador_pro/main.dart';

void main() {
  group('Alarm.fromMap', () {
    test('normalizes and sorts valid weekdays', () {
      final alarm = Alarm.fromMap({
        'id': 1,
        'hour': 7,
        'minute': 5,
        'enabled': true,
        'weekdays': '5,1,5,7',
        'appName': 'Chrome',
        'packageName': 'com.android.chrome',
        'label': 'Acordar',
        'tone': 'Clássico',
      });

      expect(alarm.time.hour, 7);
      expect(alarm.time.minute, 5);
      expect(alarm.weekdays, [1, 5, 7]);
    });

    test('rejects invalid time', () {
      expect(
        () => Alarm.fromMap(_map(hour: 24)),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects an alarm without valid weekdays', () {
      expect(
        () => Alarm.fromMap(_map(weekdays: '0,8')),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

Map<String, dynamic> _map({int hour = 7, String weekdays = '1,2,3'}) => {
  'id': 1,
  'hour': hour,
  'minute': 30,
  'enabled': true,
  'weekdays': weekdays,
  'appName': 'Chrome',
  'packageName': 'com.android.chrome',
  'label': '',
  'tone': 'Clássico',
};
