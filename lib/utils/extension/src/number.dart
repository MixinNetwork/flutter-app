part of '../extension.dart';

extension CurrencyExtension on BuildContext {
  String currencyFormat(dynamic value) =>
      currentCurrencyNumberFormat.format(num.tryParse('$value'));

  String currencyFormatWithoutSymbol(dynamic value) => currencyFormat(value)
      .replaceAll(currentCurrencyNumberFormat.currencySymbol, '');

  String get currencyFormatCoin => NumberFormat().format(num.tryParse('$this'));

  NumberFormat get currentCurrencyNumberFormat =>
      NumberFormat.simpleCurrency(name: account?.fiatCurrency);
}

extension StringCurrencyExtension on String {
  bool get isZero => (double.tryParse(this) ?? 0.0) == 0;

  Decimal get asDecimal => Decimal.parse(this);

  Decimal get asDecimalOrZero => Decimal.tryParse(this) ?? Decimal.zero;

  String numberFormat() {
    if (isEmpty) return this;
    try {
      return NumberFormat('#,###.########').format(DecimalIntl(asDecimal));
    } catch (error) {
      return this;
    }
  }

  String getPattern({int count = 8}) {
    if (isEmpty) return '';

    final index = indexOf('.');
    if (index == -1) return ',###';
    if (index >= count) return ',###';

    final int bit;
    if (index == 1 && this[0] == '0') {
      bit = count + 1;
    } else if (index == 2 && this[0] == '-' && this[1] == '0') {
      bit = count + 2;
    } else {
      bit = count;
    }

    final sb = StringBuffer(',###.');

    // NumberFormat#_formatFixed power variable's type is [int],
    // and the maxValue of int is 9.223372e+18
    // So it only supports up to the 18th decimal place.
    final decimalPartLength = min(18, bit - index);

    for (var i = 0; i < decimalPartLength; i++) {
      sb.write('#');
    }
    return sb.toString();
  }
}

extension DoubleCurrencyExtension on num {
  Decimal get asDecimal => Decimal.parse('$this');
}

// extension AssetResultExtension on AssetResult {
//   Decimal get amountOfUsd => balance.asDecimal * priceUsd.asDecimal;
//
//   Decimal get amountOfBtc => balance.asDecimal * priceBtc.asDecimal;
//
//   Decimal get amountOfCurrentCurrency =>
//       balance.asDecimal * priceUsd.asDecimal * fiatRate.asDecimal;
//
//   Decimal get usdUnitPrice => priceUsd.asDecimal * fiatRate.asDecimal;
//
//   bool get needShowMemo => tag?.isNotEmpty == true;
//
//   bool get needShowReserve => (int.tryParse(reserve ?? '0') ?? 0) > 0;
//
//   String getTip(BuildContext context) {
//     switch (chainId) {
//       case bitcoin:
//         return context.l10n.depositTipBtc;
//       case ethereum:
//         return context.l10n.depositTipEth;
//       case eos:
//         return context.l10n.depositTipEos;
//       case tron:
//         return context.l10n.depositTipTron;
//       default:
//         return context.l10n.depositTip(symbol);
//     }
//   }
// }
//
extension SnapshotItemExtension on SnapshotItem {
  Decimal amountOfCurrentCurrency() =>
      amount.asDecimal * priceUsd!.asDecimal * fiatRate!.asDecimal;

  bool get isPositive => (double.tryParse(amount) ?? 0) > 0;
}
//
// extension AddressExtension on Addresse {
//   String displayAddress() {
//     if (tag == null || tag?.isEmpty == true) {
//       return '$destination$tag';
//     } else {
//       return destination;
//     }
//   }
// }
