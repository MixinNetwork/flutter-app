import 'package:drift/drift.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:mixin_logger/mixin_logger.dart';

import '../../constants/constants.dart';
import '../../db/dao/inscription_collection_dao.dart';
import '../../db/dao/inscription_item_dao.dart';
import '../../db/mixin_database.dart';
import '../../db/vo/inscription.dart';
import '../../utils/load_balancer_utils.dart';
import '../job_queue.dart';

class SyncInscriptionMessageJob extends JobQueue<Job, List<Job>> {
  SyncInscriptionMessageJob({required super.database, required this.client});

  final Client client;

  @override
  String get name => 'SyncInscriptionMessageJob';

  @override
  Future<List<Job>> fetchJobs() =>
      database.jobDao.syncInscriptionMessageJobs().get();

  @override
  Future<void> insertJob(Job job) async {
    if (job.blazeMessage == null) return;

    final jobs = database.mixinDatabase.jobs;
    final exists = await database.mixinDatabase.hasData(
      jobs,
      [],
      jobs.action.equals(kSyncInscriptionMessage) &
          jobs.blazeMessage.equals(job.blazeMessage!),
    );

    if (exists) return;

    await database.jobDao.insert(job);
  }

  @override
  bool isValid(List<Job> jobs) => jobs.isNotEmpty;

  InscriptionItemDao get _inscriptionItemDao => database.inscriptionItemDao;

  InscriptionCollectionDao get _collectionDao =>
      database.inscriptionCollectionDao;

  @override
  Future<void> run(List<Job> jobs) async {
    for (final job in jobs) {
      final messageId = job.blazeMessage;
      if (messageId == null) {
        w('failed to sync inscription for message: ${job.jobId}');
        continue;
      }
      await syncInscriptionMessageItem(messageId);
      await database.jobDao.deleteJobById(job.jobId);
    }
  }

  Future<void> syncInscriptionMessageItem(String messageId) async {
    final message = await database.messageDao.findMessageByMessageId(messageId);
    if (message == null) {
      w('no message found for: $messageId');
      return;
    }
    final inscriptionHash = message.content;
    if (inscriptionHash == null) {
      w('no inscription hash found for message: $messageId');
      return;
    }

    try {
      inscriptionHash.hexToBytes();
    } catch (err, stacktrace) {
      e('inscription hash is not valid: $inscriptionHash', err, stacktrace);
      return;
    }

    var inscription = await _inscriptionItemDao.findInscriptionByHash(
      inscriptionHash,
    );
    if (inscription == null) {
      try {
        final resp = await client.tokenApi.getInscriptionItem(inscriptionHash);
        inscription = await _inscriptionItemDao.insertSdkItem(resp.data);
      } catch (error, stacktrace) {
        e('error to get inscription for $inscriptionHash', error, stacktrace);
        return;
      }
    }

    var collection = await _collectionDao.findCollectionByHash(
      inscription.collectionHash,
    );
    if (collection == null) {
      try {
        final resp = await client.tokenApi.getInscriptionCollection(
          inscription.collectionHash,
        );
        collection = await _collectionDao.insertSdkCollection(resp.data);
      } catch (error, stacktrace) {
        e(
          'error to get inscription collection for ${inscription.collectionHash}($inscriptionHash)',
          error,
          stacktrace,
        );
        return;
      }
    }

    await database.messageDao.updateMessageContent(
      messageId,
      jsonEncode(
        Inscription(
          collectionHash: collection.collectionHash,
          inscriptionHash: inscriptionHash,
          sequence: inscription.sequence,
          contentType: inscription.contentType,
          contentUrl: inscription.contentUrl,
          name: collection.name,
          iconUrl: collection.iconUrl,
        ),
      ),
    );
  }
}
