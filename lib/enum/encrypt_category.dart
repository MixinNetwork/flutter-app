enum EncryptCategory { plain, signal, encrypted }

extension EncryptCategoryExtension on EncryptCategory {
  String toCategory(
      String plainCategory, String signalCategory, String encryptedCategory) {
    if (this == EncryptCategory.plain) {
      return plainCategory;
    } else if (this == EncryptCategory.signal) {
      return signalCategory;
    } else {
      return encryptedCategory;
    }
  }
}