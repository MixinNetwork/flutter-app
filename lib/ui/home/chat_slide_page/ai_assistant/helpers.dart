import 'package:flutter/widgets.dart';

import '../../../../ai/model/ai_provider_config.dart';

AiProviderConfig? resolveAiAssistantProvider({
  required AiProviderConfig? selectedAiProvider,
  required List<AiProviderConfig> enabledAiProviders,
  required String? providerId,
  required String? selectedModel,
}) {
  var provider = selectedAiProvider;
  if (providerId != null) {
    for (final item in enabledAiProviders) {
      if (item.id == providerId) {
        provider = item;
        break;
      }
    }
  }
  if (provider == null || provider.model.trim().isEmpty) {
    provider = enabledAiProviders.firstOrNull;
  }
  if (provider == null) return null;

  final trimmedModel = selectedModel?.trim();
  if (trimmedModel == null || trimmedModel.isEmpty) return provider;
  if (!provider.models.contains(trimmedModel)) return provider;
  if (provider.model == trimmedModel) return provider;
  return provider.copyWith(defaultModel: trimmedModel, model: trimmedModel);
}

String currentLanguageTag(BuildContext context) {
  final locale = Localizations.localeOf(context);
  final countryCode = locale.countryCode;
  if (countryCode == null || countryCode.isEmpty) return locale.languageCode;
  return '${locale.languageCode}-$countryCode';
}
