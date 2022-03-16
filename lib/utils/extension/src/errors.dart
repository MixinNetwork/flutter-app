import 'package:flutter/widgets.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../extension.dart';

extension GetErrorStringByCode on BuildContext {
  String getMixinErrorStringByCode(int code, String message) {
    switch (code) {
      case transaction:
        return '$code TRANSACTION';
      case badData:
        return l10n.errorBadData(code);
      case phoneSmsDelivery:
        return l10n.errorPhoneSmsDelivery(code);
      case recaptchaIsInvalid:
        return l10n.errorRecaptchaIsInvalid(code);
      case oldVersion:
        return l10n.errorOldVersion(code, '');
      case phoneInvalidFormat:
        return l10n.errorPhoneInvalidFormat(code);
      case insufficientIdentityNumber:
        return '$code INSUFFICIENT_IDENTITY_NUMBER';
      case invalidInvitationCode:
        return '$code INVALID_INVITATION_CODE';
      case phoneVerificationCodeInvalid:
        return l10n.errorPhoneVerificationCodeInvalid(code);
      case phoneVerificationCodeExpired:
        return l10n.errorPhoneVerificationCodeExpired(code);
      case invalidQrCode:
        return '$code INVALID_QR_CODE';
      case notFound:
        return l10n.errorNotFound(code);
      case groupChatFull:
        return l10n.errorFullGroup(code);
      case insufficientBalance:
        return l10n.errorInsufficientBalance(code);
      case invalidPinFormat:
        return l10n.errorInvalidPinFormat(code);
      case pinIncorrect:
        return l10n.errorPinIncorrect(code);
      case tooSmall:
        return l10n.errorTooSmall(code);
      case tooManyRequest:
        return l10n.errorTooManyRequests(code);
      case usedPhone:
        return l10n.errorUsedPhone(code);
      case tooManyStickers:
        return l10n.errorTooManyStickers(code);
      case blockchainError:
        return l10n.errorBlockchain(code);
      case invalidAddress:
        return l10n.errorInvalidAddressPlain(code);
      case withdrawalAmountSmall:
        return l10n.errorTooSmallWithdrawAmount(code);
      case invalidCodeTooFrequent:
        return l10n.errorInvalidCodeTooFrequent(code);
      case invalidEmergencyContact:
        return l10n.errorInvalidEmergencyContact(code);
      case withdrawalMemoFormatIncorrect:
        return l10n.errorWithdrawalMemoFormatIncorrect(code);
      case favoriteLimit:
      case circleLimit:
        return l10n.errorFavoriteLimit(code);
      case forbidden:
        return l10n.errorForbidden;
      case server:
      case insufficientPool:
        return l10n.errorServer5xx(code);
      case timeInaccurate:
        return '$code TIME_INACCURATE';
      default:
        return '${l10n.errorUnknownWithCode(code)}: $message';
    }
  }
}

extension MixinErrorExt on MixinError {
  String toDisplayString(BuildContext context) =>
      context.getMixinErrorStringByCode(code, description);
}
