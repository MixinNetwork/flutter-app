import 'package:rxdart/rxdart.dart';

import '../../db/dao/user_dao.dart';
import '../../db/database_event_bus.dart';
import '../../db/mixin_database.dart';

const kMentionReadModelThrottleDuration = Duration(seconds: 3);

class MentionReadModel {
  MentionReadModel({
    required UserDao userDao,
    DataBaseEventBus? eventBus,
  }) : _userDao = userDao,
       _eventBus = eventBus ?? DataBaseEventBus.instance;

  final UserDao _userDao;
  final DataBaseEventBus _eventBus;

  Stream<List<User>> friends() => _watch(
    events: [_eventBus.updateUserIdsStream],
    fetch: () => _userDao.friends().get(),
  );

  Stream<List<User>> groupParticipants({
    required String conversationId,
    required String currentUserId,
  }) => _watch(
    events: [
      _eventBus.watchUpdateParticipantStream(conversationIds: [conversationId]),
    ],
    fetch: () async {
      final users = await _userDao.groupParticipants(conversationId).get();
      return users.where((user) => user.userId != currentUserId).toList();
    },
  );

  Stream<List<User>> searchBotGroupUsers({
    required String currentUserId,
    required String conversationId,
    required String keyword,
  }) => _watch(
    events: [
      _eventBus.updateUserIdsStream,
      _eventBus.insertOrReplaceMessageIdsStream,
      _eventBus.deleteMessageIdStream,
    ],
    fetch: () => _userDao
        .fuzzySearchBotGroupUser(
          currentUserId: currentUserId,
          conversationId: conversationId,
          keyword: keyword,
        )
        .get(),
  );

  Stream<List<User>> searchGroupUsers({
    required String currentUserId,
    required String conversationId,
    required String keyword,
  }) => _watch(
    events: [
      _eventBus.watchUpdateParticipantStream(conversationIds: [conversationId]),
    ],
    fetch: () => _userDao
        .fuzzySearchGroupUser(currentUserId, conversationId, keyword)
        .get(),
  );

  Stream<List<T>> _watch<T>({
    required Iterable<Stream<dynamic>> events,
    required Future<List<T>> Function() fetch,
  }) => Rx.merge(events)
      .throttleTime(kMentionReadModelThrottleDuration)
      .startWith(null)
      .asyncMap((_) => fetch());
}
