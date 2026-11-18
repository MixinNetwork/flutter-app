@TestOn('linux || mac-os')
library;

import 'package:drift/native.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/utils/event_bus.dart';
import 'package:flutter_test/flutter_test.dart';

TokensCompanion _token(String assetId, String kernelAssetId, String price) =>
    TokensCompanion.insert(
      assetId: assetId,
      kernelAssetId: kernelAssetId,
      symbol: assetId.toUpperCase(),
      name: assetId,
      iconUrl: '',
      priceBtc: '0',
      priceUsd: price,
      chainId: 'chain',
      changeUsd: '0',
      changeBtc: '0',
      confirmations: 1,
      assetKey: '',
      dust: '0',
    );

void main() {
  setUpAll(EventBus.initialize);

  late MixinDatabase database;

  setUp(() async {
    database = MixinDatabase(NativeDatabase.memory());
    await database.batch(
      (batch) => batch.insertAll(database.tokens, [
        _token('btc', 'k-btc', '100000'),
        _token('usdt', 'k-usdt', '1'),
        _token('xin', 'k-xin', '100'),
      ]),
    );
  });
  tearDown(() => database.close());

  Future<List<String>> visible({bool hidden = false}) async => [
    for (final item
        in await database.tokenDao.walletTokenItems(hidden: hidden).get())
      '${item.assetId}=${item.balance}',
  ];

  test('lists tokens with a balance by value, highest first', () async {
    await database.tokenDao.replaceBalances({
      'k-usdt': '50',
      'k-btc': '0.001',
      'k-unknown': '1',
    });
    expect(await visible(), ['btc=0.001', 'usdt=50']);
  });

  test('sets the balance of every other asset to zero', () async {
    await database.tokenDao.replaceBalances({'k-usdt': '50', 'k-xin': '1'});
    await database.tokenDao.replaceBalances({'k-xin': '2'});
    expect(await visible(), ['xin=2']);
    final usdt = await database.tokenDao.walletTokenItem('usdt').getSingle();
    expect(usdt.balance, '0');
  });

  test('keeps the hidden flag when the balance changes', () async {
    await database.tokenDao.replaceBalances({'k-usdt': '50', 'k-xin': '1'});
    await database.tokenDao.setHidden('k-usdt', hidden: true);
    await database.tokenDao.replaceBalances({'k-usdt': '60', 'k-xin': '1'});
    expect(await visible(), ['xin=1']);
    expect(await visible(hidden: true), ['usdt=60']);
  });

  test('shows a zero balance for a token that has no balance row', () async {
    final btc = await database.tokenDao.walletTokenItem('btc').getSingle();
    expect((btc.balance, btc.hidden), ('0', false));
  });

  test('creates tokens_extra when migrating from v29', () async {
    final migrated = MixinDatabase(
      NativeDatabase.memory(
        setup: (rawDatabase) => rawDatabase.userVersion = 29,
      ),
    );
    addTearDown(migrated.close);
    final rows = await migrated
        .customSelect(
          "SELECT name FROM sqlite_master WHERE name = 'tokens_extra'",
        )
        .get();
    expect(rows, hasLength(1));
  });
}
