import 'package:flutter_app/crypto/signal/storage/mixin_identity_key_store.dart';
import 'package:flutter_app/crypto/signal/storage/mixin_prekey_store.dart';
import 'package:flutter_app/crypto/signal/storage/mixin_session_store.dart';
import 'package:flutter_app/crypto/signal/storage/mixin_signal_protocol_store.dart';
import 'package:objectbox/objectbox.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_app/objectbox.g.dart';

class SignalDatabase {
  SignalDatabase(this._sessionId);

  final String _sessionId;

  late Store _store;

  Future initStore() async {
    final dir = await getApplicationDocumentsDirectory();
    _store = Store(getObjectBoxModel(), directory: '${dir.path}/objectbox');

    final preKeyStore = MixinPreKeyStore(store);
    final signedPreKeyStore = MixinPreKeyStore(store);
    final identityKeyStore = MixinIdentityKeyStore(store, _sessionId);
    final sessionStore = MixinSessionStore(store);
    final mixinSignalProtocolStore = MixinSignalProtocolStore(
        preKeyStore, signedPreKeyStore, identityKeyStore, sessionStore);
  }

  Store get store => _store;
}
