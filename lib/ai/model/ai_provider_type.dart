enum AiProviderType {
  openaiCompatible('openai_compatible'),
  anthropic('anthropic')
  ;

  const AiProviderType(this.value);

  final String value;

  static AiProviderType fromValue(String value) =>
      AiProviderType.values.firstWhere(
        (element) => element.value == value,
        orElse: () => AiProviderType.openaiCompatible,
      );
}
