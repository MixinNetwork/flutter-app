import '../utils/extension/extension.dart';
import 'message_category.dart';

enum EncryptCategory { plain, signal, encrypted }

extension EncryptCategoryExtension on EncryptCategory {
  String toCategory(
    String plainCategory,
    String signalCategory,
    String encryptedCategory,
  ) {
    if (this == EncryptCategory.plain) {
      return plainCategory;
    } else if (this == EncryptCategory.signal) {
      return signalCategory;
    } else {
      return encryptedCategory;
    }
  }

  String asCategory(String category) {
    if (category.isText) {
      return toCategory(
        MessageCategory.plainText,
        MessageCategory.signalText,
        MessageCategory.encryptedText,
      );
    }
    if (category.isImage) {
      return toCategory(
        MessageCategory.plainImage,
        MessageCategory.signalImage,
        MessageCategory.encryptedImage,
      );
    }
    if (category.isAudio) {
      return toCategory(
        MessageCategory.plainAudio,
        MessageCategory.signalAudio,
        MessageCategory.encryptedAudio,
      );
    }
    if (category.isVideo) {
      return toCategory(
        MessageCategory.plainVideo,
        MessageCategory.signalVideo,
        MessageCategory.encryptedVideo,
      );
    }
    if (category.isSticker) {
      return toCategory(
        MessageCategory.plainSticker,
        MessageCategory.signalSticker,
        MessageCategory.encryptedSticker,
      );
    }
    if (category.isData) {
      return toCategory(
        MessageCategory.plainData,
        MessageCategory.signalData,
        MessageCategory.encryptedData,
      );
    }
    if (category.isLive) {
      return toCategory(
        MessageCategory.plainLive,
        MessageCategory.signalLive,
        MessageCategory.encryptedLive,
      );
    }
    if (category.isPost) {
      return toCategory(
        MessageCategory.plainPost,
        MessageCategory.signalPost,
        MessageCategory.encryptedPost,
      );
    }
    if (category.isLocation) {
      return toCategory(
        MessageCategory.plainLocation,
        MessageCategory.signalLocation,
        MessageCategory.encryptedLocation,
      );
    }
    if (category.isTranscript) {
      return toCategory(
        MessageCategory.plainTranscript,
        MessageCategory.signalTranscript,
        MessageCategory.encryptedTranscript,
      );
    }
    if (category.isContact) {
      return toCategory(
        MessageCategory.plainContact,
        MessageCategory.signalContact,
        MessageCategory.encryptedContact,
      );
    }
    if (category.isAppCard) {
      return MessageCategory.appCard;
    }

    if (category.isAppButtonGroup) {
      return MessageCategory.appButtonGroup;
    }

    throw ArgumentError('Unknown type. $category');
  }

  bool get isEncrypt => this != EncryptCategory.plain;
}
