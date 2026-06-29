import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart'
    show ConversationCategory;

import '../../../db/dao/conversation_dao.dart';
import '../../../db/dao/participant_dao.dart';
import '../../../db/database.dart';
import '../../../db/database_event_bus.dart';
import '../../../db/mixin_database.dart' hide Offset;
import '../../../utils/logger.dart';

class ConversationAvatarCache extends ChangeNotifier {
  ConversationAvatarCache(this.database) {
    _participantSubscription = DataBaseEventBus
        .instance
        .updateParticipantIdStream
        .listen(_handleParticipantUpdate);
  }

  final Database database;
  final Map<String, List<User>> _avatars = {};
  final Set<String> _loadedGroupIds = {};
  StreamSubscription<List<MiniParticipantItem>>? _participantSubscription;
  var _disposed = false;

  List<User>? usersFor(String conversationId) => _avatars[conversationId];

  Future<void> warm(Iterable<ConversationItem> conversations) async {
    final missingGroupIds = conversations
        .where(
          (conversation) => conversation.category == ConversationCategory.group,
        )
        .map((conversation) => conversation.conversationId)
        .where((conversationId) => !_avatars.containsKey(conversationId))
        .toSet();
    if (missingGroupIds.isEmpty) return;
    await _refresh(missingGroupIds);
  }

  Future<void> _refresh(Iterable<String> conversationIds) async {
    final ids = conversationIds.toSet();
    if (ids.isEmpty) return;
    _loadedGroupIds.addAll(ids);

    try {
      final rows = await database.participantDao
          .participantsAvatarByConversationIds(ids);
      var changed = false;
      for (final id in ids) {
        final users = rows[id] ?? const <User>[];
        if (listEquals(_avatars[id], users)) continue;
        _avatars[id] = users;
        changed = true;
      }
      if (changed && !_disposed) notifyListeners();
    } catch (error, stackTrace) {
      e('conversation avatar cache failed: $error, $stackTrace');
    }
  }

  void _handleParticipantUpdate(List<MiniParticipantItem> participants) {
    final changedGroupIds = participants
        .map((participant) => participant.conversationId)
        .where(_loadedGroupIds.contains)
        .toSet();
    if (changedGroupIds.isEmpty) return;
    unawaited(_refresh(changedGroupIds));
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_participantSubscription?.cancel());
    super.dispose();
  }
}
