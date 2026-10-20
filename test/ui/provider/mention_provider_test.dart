import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/ui/provider/mention_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('selectedUser ignores stale selection indexes', () {
    const user = User(
      userId: 'user',
      identityNumber: '7001',
      fullName: 'User',
    );

    expect(const MentionState().selectedUser, isNull);
    expect(
      const MentionState(users: [user], index: -1).selectedUser,
      isNull,
    );
    expect(
      const MentionState(users: [user], index: 1).selectedUser,
      isNull,
    );
    expect(const MentionState(users: [user]).selectedUser, user);
  });
}
