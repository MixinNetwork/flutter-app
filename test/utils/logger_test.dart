import 'package:flutter_app/utils/logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('test logger colors', () {
    v('..... verbose message ......');
    d('===== debug message =====');
    i('info message');
    w('Just a warning!');
    e('Error! Something bad happened', 'Test Error');
    wtf('!!!! WTF message !!!!');
  });
}
