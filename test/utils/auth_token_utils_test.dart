import 'package:flutter_app/utils/auth_token_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('auth token utils', () {
    test('parses iat from bearer token header', () {
      const header =
          'Bearer eyJhbGciOiJub25lIn0.eyJpYXQiOjE3MTAwMDAwMDAsInVpZCI6InUxIn0.';

      expect(
        bearerTokenIssuedAt(header),
        DateTime.fromMillisecondsSinceEpoch(
          1710000000 * 1000,
          isUtc: true,
        ),
      );
    });

    test('treats old bearer token as delayed', () {
      const header =
          'Bearer eyJhbGciOiJub25lIn0.eyJpYXQiOjE3MTAwMDAwMDAsInVpZCI6InUxIn0.';

      expect(
        isBearerTokenDelayed(
          header,
          now: DateTime.fromMillisecondsSinceEpoch(
            1710000061 * 1000,
            isUtc: true,
          ),
        ),
        isTrue,
      );
    });

    test('ignores malformed authorization header', () {
      expect(isBearerTokenDelayed('invalid'), isFalse);
      expect(bearerTokenIssuedAt('invalid'), isNull);
    });
  });
}
