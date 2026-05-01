import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../ai/model/ai_prompt_template.dart';
import '../../ai/model/ai_provider_config.dart';
import '../../utils/extension/extension.dart';
import '../../utils/mcp/mixin_mcp_server.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/cell.dart';
import '../../widgets/dialog.dart';
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
    final selectedTranslatorProvider =
        database.settingProperties.selectedAiTranslatorProvider;
    final selectedTranslatorProviderId =
        database.settingProperties.selectedAiTranslatorProviderId;
    final selectedTranslatorModel =
        database.settingProperties.selectedAiTranslatorModel;
    final customizedPromptCount = aiPromptTemplateDefinitions
        .where(
          (definition) =>
              database.settingProperties.hasAiPromptTemplateOverride(
                definition.key,
              ),
        )
        .length;
    final mcpServer = useListenable(MixinMcpServer.instance);
    final enableMcpServer = database.settingProperties.enableMcpServer;
    final mcpEndpoint = mcpServer.endpoint;
    final mcpToken = database.settingProperties.mcpServerToken;

    return Scaffold(
      backgroundColor: context.theme.background,
      appBar: const MixinAppBar(title: Text('AI Settings')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CellGroup(
                    padding: const EdgeInsets.only(right: 10, left: 10),
                    cellBackgroundColor:
                        context.theme.settingCellBackgroundColor,
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
                    padding: const EdgeInsets.only(
                      left: 20,
                      bottom: 14,
                      top: 10,
                    ),
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
                    cellBackgroundColor:
                        context.theme.settingCellBackgroundColor,
                    child: Column(
                      children: [
                        CellItem(
                          title: const Text('Local MCP Server'),
                          leading: Icon(
                            Icons.hub_outlined,
                            color: context.theme.icon,
                          ),
                          description: Text(
                            mcpServer.isRunning ? 'Running' : 'Off',
                          ),
                          trailing: Transform.scale(
                            scale: 0.7,
                            child: CupertinoSwitch(
                              activeTrackColor: context.theme.accent,
                              value: enableMcpServer,
                              onChanged: (value) {
                                database.settingProperties.enableMcpServer =
                                    value;
                              },
                            ),
                          ),
                        ),
                        if (enableMcpServer) ...[
                          Divider(
                            height: 0.5,
                            indent: 16,
                            endIndent: 16,
                            color: context.theme.divider,
                          ),
                          CellItem(
                            title: const Text('Endpoint'),
                            description: Expanded(
                              child: Text(
                                mcpEndpoint?.toString() ?? 'Starting...',
                                textAlign: TextAlign.end,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            trailing: IconButton(
                              onPressed: mcpEndpoint == null
                                  ? null
                                  : () {
                                      Clipboard.setData(
                                        ClipboardData(
                                          text: mcpEndpoint.toString(),
                                        ),
                                      );
                                      showToastSuccessful();
                                    },
                              icon: Icon(
                                Icons.copy_rounded,
                                color: context.theme.icon,
                              ),
                            ),
                          ),
                          Divider(
                            height: 0.5,
                            indent: 16,
                            endIndent: 16,
                            color: context.theme.divider,
                          ),
                          CellItem(
                            title: const Text('Access Token'),
                            description: Expanded(
                              child: Text(
                                mcpToken ?? 'Unavailable',
                                textAlign: TextAlign.end,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: mcpToken == null
                                      ? null
                                      : () {
                                          Clipboard.setData(
                                            ClipboardData(text: mcpToken),
                                          );
                                          showToastSuccessful();
                                        },
                                  icon: Icon(
                                    Icons.copy_rounded,
                                    color: context.theme.icon,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    database.settingProperties
                                        .regenerateMcpServerToken();
                                    showToastSuccessful();
                                  },
                                  icon: Icon(
                                    Icons.refresh_rounded,
                                    color: context.theme.icon,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 20,
                      bottom: 14,
                      top: 10,
                    ),
                    child: Text(
                      'Exposes read-only conversation tools, UI navigation, draft editing, and AI thread inspection on localhost only. It never sends messages.',
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
                    padding: const EdgeInsets.only(
                      left: 20,
                      bottom: 14,
                      top: 10,
                    ),
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
                    CellGroup(
                      padding: const EdgeInsets.only(right: 10, left: 10),
                      cellBackgroundColor:
                          context.theme.settingCellBackgroundColor,
                      child: CellItem(
                        title: const Text('Translator Provider'),
                        leading: Icon(
                          Icons.translate_rounded,
                          color: context.theme.icon,
                        ),
                        description: Text(
                          selectedTranslatorProviderId == null
                              ? 'Default · ${_providerModelSummary(selectedTranslatorProvider)}'
                              : _providerModelSummary(
                                  selectedTranslatorProvider,
                                ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _showTranslatorProviderDialog(
                          context,
                          providers: providers,
                          selectedProviderId: selectedTranslatorProviderId,
                          selectedModel: selectedTranslatorModel,
                        ),
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

  static String _providerModelSummary(AiProviderConfig? provider) {
    if (provider == null) return 'No enabled provider';
    return '${provider.name} · ${provider.model}';
  }

  static Future<void> _showTranslatorProviderDialog(
    BuildContext context, {
    required List<AiProviderConfig> providers,
    required String? selectedProviderId,
    required String? selectedModel,
  }) async {
    await showMixinDialog<void>(
      context: context,
      child: _TranslatorProviderDialog(
        providers: providers
            .where((provider) => provider.enabled)
            .where((provider) => provider.model.trim().isNotEmpty)
            .toList(growable: false),
        selectedProviderId: selectedProviderId,
        selectedModel: selectedModel,
      ),
    );
  }
}

class _TranslatorProviderDialog extends HookConsumerWidget {
  const _TranslatorProviderDialog({
    required this.providers,
    required this.selectedProviderId,
    required this.selectedModel,
  });

  final List<AiProviderConfig> providers;
  final String? selectedProviderId;
  final String? selectedModel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final database = ref.watch(databaseProvider).requireValue;
    final selection = useState(
      _AiProviderModelSelection(
        providerId: selectedProviderId,
        model: selectedModel,
      ),
    );

    return AlertDialogLayout(
      title: const Text('Translator Provider'),
      titleMarginBottom: 20,
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 360),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ProviderModelOption(
                title: 'Use Default Provider',
                subtitle: _providerSummary(
                  database.settingProperties.selectedAiProvider,
                ),
                selected: selection.value.providerId == null,
                onTap: () =>
                    selection.value = const _AiProviderModelSelection(),
              ),
              for (final provider in providers)
                for (final model in provider.models)
                  _ProviderModelOption(
                    title: provider.name,
                    subtitle: model,
                    selected:
                        selection.value.providerId == provider.id &&
                        selection.value.model == model,
                    onTap: () => selection.value = _AiProviderModelSelection(
                      providerId: provider.id,
                      model: model,
                    ),
                  ),
            ],
          ),
        ),
      ),
      actions: [
        MixinButton(
          backgroundTransparent: true,
          onTap: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        MixinButton(
          onTap: () {
            database.settingProperties.selectedAiTranslatorProviderId =
                selection.value.providerId;
            database.settingProperties.selectedAiTranslatorModel =
                selection.value.model;
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  static String _providerSummary(AiProviderConfig? provider) {
    if (provider == null) return 'No enabled provider';
    return '${provider.name} · ${provider.model}';
  }
}

class _AiProviderModelSelection {
  const _AiProviderModelSelection({this.providerId, this.model});

  final String? providerId;
  final String? model;
}

class _ProviderModelOption extends StatelessWidget {
  const _ProviderModelOption({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(
            selected
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_unchecked_rounded,
            color: selected
                ? context.theme.accent
                : context.theme.secondaryText,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: context.theme.text, fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.theme.secondaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
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
