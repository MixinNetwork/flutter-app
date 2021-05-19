const systemUser = '00000000-0000-0000-0000-000000000000';

const scp =
    'PROFILE:READ PROFILE:WRITE PHONE:READ PHONE:WRITE CONTACTS:READ CONTACTS:WRITE MESSAGES:READ MESSAGES:WRITE ASSETS:READ SNAPSHOTS:READ CIRCLES:READ CIRCLES:WRITE';

const acknowledgeMessageReceipt = 'ACKNOWLEDGE_MESSAGE_RECEIPT';
const acknowledgeMessageReceipts = 'ACKNOWLEDGE_MESSAGE_RECEIPTS';
const sendingMessage = 'SENDING_MESSAGE';
const recallMessage = 'RECALL_MESSAGE';
const resendMessages = 'RESEND_MESSAGES';
const createMessage = 'CREATE_MESSAGE';
const resendKey = 'RESEND_KEY';
const errorAction = 'ERROR';
const consumeSessionSignalKeys = 'CONSUME_SESSION_SIGNAL_KEYS';
const createSignalKeyMessages = 'CREATE_SIGNAL_KEY_MESSAGES';
const countSignalKeys = 'COUNT_SIGNAL_KEYS';
const syncSignalKeys = 'SYNC_SIGNAL_KEYS';

const int forbidden = 403;
const int conversationChecksumInvalidError = 20140;

const mixinScheme = 'mixin';
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
