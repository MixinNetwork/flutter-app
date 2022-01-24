const systemUser = '00000000-0000-0000-0000-000000000000';

const scp =
    'PROFILE:READ PROFILE:WRITE PHONE:READ PHONE:WRITE CONTACTS:READ CONTACTS:WRITE MESSAGES:READ MESSAGES:WRITE ASSETS:READ SNAPSHOTS:READ CIRCLES:READ CIRCLES:WRITE';

const kAcknowledgeMessageReceipt = 'ACKNOWLEDGE_MESSAGE_RECEIPT';
const kAcknowledgeMessageReceipts = 'ACKNOWLEDGE_MESSAGE_RECEIPTS';
const kSendingMessage = 'SENDING_MESSAGE';
const kRecallMessage = 'RECALL_MESSAGE';
const kPinMessage = 'PIN_MESSAGE';
const kResendMessages = 'RESEND_MESSAGES';
const kCreateMessage = 'CREATE_MESSAGE';
const kCreateCall = 'CREATE_CALL';
const kCreateKraken = 'CREATE_KRAKEN';
const kListPendingMessage = 'LIST_PENDING_MESSAGES';
const kResendKey = 'RESEND_KEY';
const kNoKey = 'NO_KEY';
const kErrorAction = 'ERROR';
const kConsumeSessionSignalKeys = 'CONSUME_SESSION_SIGNAL_KEYS';
const kCreateSignalKeyMessages = 'CREATE_SIGNAL_KEY_MESSAGES';
const kCountSignalKeys = 'COUNT_SIGNAL_KEYS';
const kSyncSignalKeys = 'SYNC_SIGNAL_KEYS';

// Only from local.
const kUpdateAsset = 'LOCAL_UPDATE_ASSET';
const kUpdateSticker = 'LOCAL_UPDATE_STICKER';

const mixinScheme = 'mixin';
const mixinHost = 'mixin.one';

enum MixinSchemeHost {
  codes,
  pay,
  users,
  transfer,
  device,
  send,
  address,
  withdrawal,
  apps,
  snapshots,
}

const mixinProtocolUrls = {
  MixinSchemeHost.codes: 'https://mixin.one/codes',
  MixinSchemeHost.transfer: 'https://mixin.one/transfer',
  MixinSchemeHost.address: 'https://mixin.one/address',
  MixinSchemeHost.withdrawal: 'https://mixin.one/withdrawal',
  MixinSchemeHost.apps: 'https://mixin.one/apps',
  MixinSchemeHost.snapshots: 'https://mixin.one/snapshots'
};

const int hour1 = 1000 * 60 * 60;
const int hours24 = hour1 * 24;

const statusOffset = 'messages_status_offset';

const kMarkLimit = 10000;
