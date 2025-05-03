import 'package:flutter_app/utils/extension/extension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('test chunked list', () {
    final list = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
    final result = list.chunked(3);
    expect(result, [
      [1, 2, 3],
      [4, 5, 6],
      [7, 8, 9],
      [10],
    ]);

    final result2 = list.chunked(4);
    expect(result2, [
      [1, 2, 3, 4],
      [5, 6, 7, 8],
      [9, 10],
    ]);

    final result3 = list.chunked(5);
    expect(result3, [
      [1, 2, 3, 4, 5],
      [6, 7, 8, 9, 10],
    ]);

    final result4 = list.chunked(11);
    expect(result4, [
      [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
    ]);

    expect([].chunked(2), []);
  });
}
