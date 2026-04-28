import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../ai/model/ai_prompt_template.dart';
import '../../ai/model/ai_provider_config.dart';
import '../../utils/extension/extension.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/cell.dart';
import '../../widgets/toast.dart';
import '../provider/database_provider.dart';
import 'ai_prompt_settings_page.dart';
import 'ai_provider_edit_page.dart';

class AiSettingsPage extends HookConsumerWidget {
  const AiSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final database = ref.watch(databaseProvider).requireValue;
    useListenable(database.settingProperties);
    final providers = database.settingProperties.aiProviders;
    final selectedId = database.settingProperties.selectedAiProviderId;
    final selectedProvider = database.settingProperties.selectedAiProvider;
    final customizedPromptCount = aiPromptTemplateDefinitions
        .where(
          (definition) =>
              database.settingProperties.hasAiPromptTemplateOverride(
                definition.key,
              ),
        )
        .length;

    return Scaffold(
      backgroundColor: context.theme.background,
      appBar: const MixinAppBar(title: Text('AI Settings')),
      body: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CellGroup(
                  padding: const EdgeInsets.only(right: 10, left: 10),
                  cellBackgroundColor: context.theme.settingCellBackgroundColor,
                  child: CellItem(
                    title: const Text('Prompt Templates'),
                    leading: Icon(
                      Icons.tune_rounded,
                      color: context.theme.icon,
                    ),
                    description: Text(
                      customizedPromptCount == 0
                          ? 'Default'
                          : '$customizedPromptCount custom',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: null,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AiPromptSettingsPage(),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20, bottom: 14, top: 10),
                  child: Text(
                    'Customize chat prompts, assist prompts, and built-in variables like {{conversationId}}, {{currentIsoDateTime}}, and {{language}}.',
                    style: TextStyle(
                      color: context.theme.secondaryText,
                      fontSize: 14,
                    ),
                  ),
                ),
                CellGroup(
                  padding: const EdgeInsets.only(right: 10, left: 10),
                  cellBackgroundColor: context.theme.settingCellBackgroundColor,
                  child: CellItem(
                    title: const Text('Add Provider'),
                    leading: Icon(Icons.add, color: context.theme.icon),
                    trailing: null,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AiProviderEditPage(),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20, bottom: 14, top: 10),
                  child: Text(
                    providers.isEmpty
                        ? 'Add an AI provider to enable AI mode in chat.'
                        : 'The selected provider is used by default in AI mode.',
                    style: TextStyle(
                      color: context.theme.secondaryText,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (providers.isNotEmpty) ...[
                  CellGroup(
                    padding: const EdgeInsets.only(right: 10, left: 10),
                    cellBackgroundColor:
                        context.theme.settingCellBackgroundColor,
                    child: CellItem(
                      title: const Text('Default Provider'),
                      description: Text(
                        _providerSummary(selectedProvider),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: null,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 20,
                      bottom: 14,
                      top: 10,
                    ),
                    child: Text(
                      'Each API endpoint can contain multiple models. One default model is used for new AI requests.',
                      style: TextStyle(
                        color: context.theme.secondaryText,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  CellGroup(
                    padding: const EdgeInsets.only(right: 10, left: 10),
                    cellBackgroundColor:
                        context.theme.settingCellBackgroundColor,
                    child: Column(
                      children: [
                        for (var i = 0; i < providers.length; i++) ...[
                          _ProviderCell(
                            provider: providers[i],
                            selected: selectedId == providers[i].id,
                          ),
                          if (i != providers.length - 1)
                            Divider(
                              height: 0.5,
                              indent: 16,
                              endIndent: 16,
                              color: context.theme.divider,
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _providerSummary(AiProviderConfig? provider) {
    if (provider == null) return 'No enabled provider';
    final modelCount = provider.models.length;
    if (modelCount <= 1) {
      return provider.model;
    }
    return '${provider.model} · $modelCount models';
  }
}

class _ProviderCell extends HookConsumerWidget {
  const _ProviderCell({required this.provider, required this.selected});

  final AiProviderConfig provider;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final database = ref.watch(databaseProvider).requireValue;
    final subtitle = [
      provider.baseUrl,
      if (provider.models.isNotEmpty)
        provider.models.length == 1
            ? provider.model
            : '${provider.model} · ${provider.models.length} models',
    ].join('\n');

    return CellItem(
      selected: selected,
      onTap: () =>
          database.settingProperties.selectedAiProviderId = provider.id,
      title: Row(
        children: [
          Expanded(
            child: Text(
              provider.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (selected)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(
                Icons.check_circle_rounded,
                size: 18,
                color: context.theme.accent,
              ),
            ),
        ],
      ),
      description: Expanded(
        child: Text(
          subtitle,
          textAlign: TextAlign.end,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.scale(
            scale: 0.7,
            child: CupertinoSwitch(
              activeTrackColor: context.theme.accent,
              value: provider.enabled,
              onChanged: (value) {
                database.settingProperties.saveAiProvider(
                  provider.copyWith(enabled: value),
                );
              },
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => AiProviderEditPage(initial: provider),
              ),
            ),
            icon: Icon(Icons.edit_outlined, color: context.theme.icon),
          ),
          IconButton(
            onPressed: () {
              database.settingProperties.removeAiProvider(provider.id);
              showToastSuccessful();
            },
            icon: Icon(Icons.delete_outline, color: context.theme.red),
          ),
        ],
      ),
    );
  }
}
