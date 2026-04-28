import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../ai/model/ai_provider_config.dart';
import '../../ai/model/ai_provider_type.dart';
import '../../utils/extension/extension.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/cell.dart';
import '../../widgets/dialog.dart';
import '../../widgets/toast.dart';
import '../provider/database_provider.dart';

class AiProviderEditPage extends HookConsumerWidget {
  const AiProviderEditPage({super.key, this.initial});

  final AiProviderConfig? initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final database = ref.watch(databaseProvider).requireValue;
    final theme = context.theme;
    final inputBackgroundColor = context.dynamicColor(
      Colors.white,
      darkColor: const Color.fromRGBO(255, 255, 255, 0.08),
    );
    final inputBorderColor = context.dynamicColor(
      theme.divider,
      darkColor: const Color.fromRGBO(255, 255, 255, 0.10),
    );
    final inputIconColor = context.dynamicColor(
      theme.secondaryText,
      darkColor: const Color.fromRGBO(255, 255, 255, 0.52),
    );
    final nameController = useTextEditingController(text: initial?.name ?? '');
    final baseUrlController = useTextEditingController(
      text: initial?.baseUrl ?? '',
    );
    final apiKeyController = useTextEditingController(
      text: initial?.apiKey ?? '',
    );
    final providerType = useState(
      initial?.type ?? AiProviderType.openaiCompatible,
    );
    final models = useState(
      _normalizeModels(initial?.models ?? [initial?.model ?? '']),
    );
    final defaultModel = useState(
      _resolveDefaultModel(
        models.value,
        initial?.defaultModel ?? initial?.model,
      ),
    );
    final obscureApiKey = useState(true);

    useEffect(() {
      if (initial != null) return null;
      final suggestion = _defaultBaseUrlFor(providerType.value);
      if (baseUrlController.text.trim().isEmpty && suggestion.isNotEmpty) {
        baseUrlController.text = suggestion;
      }
      return null;
    }, [initial, providerType.value]);

    useEffect(() {
      final resolved = _resolveDefaultModel(models.value, defaultModel.value);
      if (resolved != defaultModel.value) {
        defaultModel.value = resolved;
      }
      return null;
    }, [models.value, defaultModel.value]);

    Future<void> showModelDialog({String? initialValue, int? index}) async {
      final result = await showMixinDialog<String>(
        context: context,
        child: EditDialog(
          title: Text(index == null ? 'Add Model' : 'Edit Model'),
          editText: initialValue ?? '',
          hintText: 'gpt-4.1-mini',
          positiveAction: index == null ? 'Add' : 'Save',
        ),
      );
      final model = result?.trim();
      if (model == null || model.isEmpty) return;

      final nextModels = [...models.value];
      if (index != null && index >= 0 && index < nextModels.length) {
        nextModels[index] = model;
      } else {
        nextModels.add(model);
      }
      models.value = _normalizeModels(nextModels);
      defaultModel.value = _resolveDefaultModel(
        models.value,
        index != null && initialValue == defaultModel.value
            ? model
            : defaultModel.value,
      );
    }

    void removeModelAt(int index) {
      final nextModels = [...models.value]..removeAt(index);
      final removed = models.value[index];
      models.value = nextModels;
      defaultModel.value = _resolveDefaultModel(
        nextModels,
        removed == defaultModel.value ? null : defaultModel.value,
      );
    }

    return Scaffold(
      backgroundColor: theme.background,
      appBar: MixinAppBar(
        title: Text(initial == null ? 'Add AI Provider' : 'Edit AI Provider'),
        actions: [
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              final baseUrl = baseUrlController.text.trim();
              final apiKey = apiKeyController.text.trim();
              final normalizedModels = _normalizeModels(models.value);
              final resolvedDefaultModel = _resolveDefaultModel(
                normalizedModels,
                defaultModel.value,
              );
              if (name.isEmpty ||
                  baseUrl.isEmpty ||
                  apiKey.isEmpty ||
                  normalizedModels.isEmpty ||
                  resolvedDefaultModel.isEmpty) {
                showToastFailed(ToastError('Please complete all fields'));
                return;
              }

              final provider =
                  (initial ??
                          AiProviderConfig(
                            id: const Uuid().v4(),
                            name: name,
                            type: providerType.value,
                            baseUrl: baseUrl,
                            apiKey: apiKey,
                            model: resolvedDefaultModel,
                            models: normalizedModels,
                            defaultModel: resolvedDefaultModel,
                          ))
                      .copyWith(
                        name: name,
                        type: providerType.value,
                        baseUrl: baseUrl,
                        apiKey: apiKey,
                        models: normalizedModels,
                        defaultModel: resolvedDefaultModel,
                        model: resolvedDefaultModel,
                      );
              database.settingProperties.saveAiProvider(provider);
              Navigator.of(context).pop();
            },
            child: Text(
              'Save',
              style: TextStyle(color: theme.accent, fontSize: 16),
            ),
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionLabel(
                    title: 'Provider',
                  ),
                  CellGroup(
                    padding: const EdgeInsets.only(right: 10, left: 10),
                    cellBackgroundColor:
                        context.theme.settingCellBackgroundColor,
                    child: Column(
                      children: [
                        _FormFieldCell(
                          label: 'Display Name',
                          backgroundColor: inputBackgroundColor,
                          borderColor: inputBorderColor,
                          child: TextField(
                            controller: nameController,
                            style: TextStyle(
                              color: theme.text,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              hintText:
                                  'OpenAI / Anthropic / Gemini / Self-hosted',
                              hintStyle: TextStyle(color: theme.secondaryText),
                            ),
                          ),
                        ),
                        _CellDivider(color: theme.divider),
                        _FormFieldCell(
                          label: 'Provider Type',
                          backgroundColor: inputBackgroundColor,
                          borderColor: inputBorderColor,
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<AiProviderType>(
                              value: providerType.value,
                              isExpanded: true,
                              dropdownColor: theme.popUp,
                              style: TextStyle(
                                color: theme.text,
                                fontSize: 16,
                              ),
                              iconEnabledColor: inputIconColor,
                              onChanged: (value) {
                                if (value == null ||
                                    value == providerType.value) {
                                  return;
                                }
                                final previousType = providerType.value;
                                providerType.value = value;
                                if (initial == null) {
                                  final suggestion = _defaultBaseUrlFor(value);
                                  final current = baseUrlController.text.trim();
                                  final replaceCurrent =
                                      current.isEmpty ||
                                      current ==
                                          _defaultBaseUrlFor(previousType);
                                  if (replaceCurrent && suggestion.isNotEmpty) {
                                    baseUrlController.text = suggestion;
                                  }
                                }
                              },
                              items: AiProviderType.values
                                  .map(
                                    (type) => DropdownMenuItem<AiProviderType>(
                                      value: type,
                                      child: Text(
                                        switch (type) {
                                          AiProviderType.anthropic =>
                                            'Anthropic',
                                          AiProviderType.gemini => 'Gemini',
                                          AiProviderType.openaiCompatible =>
                                            'OpenAI Compatible',
                                        },
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const _SectionLabel(
                    title: 'Endpoint',
                  ),
                  CellGroup(
                    padding: const EdgeInsets.only(right: 10, left: 10),
                    cellBackgroundColor: theme.settingCellBackgroundColor,
                    child: _FormFieldCell(
                      label: 'Base URL',
                      backgroundColor: inputBackgroundColor,
                      borderColor: inputBorderColor,
                      child: TextField(
                        controller: baseUrlController,
                        keyboardType: TextInputType.url,
                        style: TextStyle(
                          color: theme.text,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: _baseUrlHintFor(providerType.value),
                          hintStyle: TextStyle(color: theme.secondaryText),
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
                      _baseUrlHelperTextFor(providerType.value),
                      style: TextStyle(
                        color: context.theme.secondaryText,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const _SectionLabel(
                    title: 'Authorization',
                  ),
                  CellGroup(
                    padding: const EdgeInsets.only(right: 10, left: 10),
                    cellBackgroundColor:
                        context.theme.settingCellBackgroundColor,
                    child: Column(
                      children: [
                        _FormFieldCell(
                          label: 'API Key',
                          backgroundColor: inputBackgroundColor,
                          borderColor: inputBorderColor,
                          trailing: IconButton(
                            onPressed: () =>
                                obscureApiKey.value = !obscureApiKey.value,
                            icon: Icon(
                              obscureApiKey.value
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 20,
                              color: inputIconColor,
                            ),
                          ),
                          child: TextField(
                            controller: apiKeyController,
                            obscureText: obscureApiKey.value,
                            style: TextStyle(
                              color: theme.text,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              hintText: _apiKeyHintFor(providerType.value),
                              hintStyle: TextStyle(color: theme.secondaryText),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const _SectionLabel(
                    title: 'Models',
                  ),
                  CellGroup(
                    padding: const EdgeInsets.only(right: 10, left: 10),
                    cellBackgroundColor: theme.settingCellBackgroundColor,
                    child: Column(
                      children: [
                        CellItem(
                          title: const Text('Default Model'),
                          description: Text(
                            defaultModel.value.isEmpty
                                ? 'No default model yet'
                                : defaultModel.value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: null,
                        ),
                        _CellDivider(color: context.theme.divider),
                        CellItem(
                          title: const Text('Add Model'),
                          leading: Icon(Icons.add, color: context.theme.icon),
                          trailing: null,
                          onTap: showModelDialog,
                        ),
                        if (models.value.isEmpty) ...[
                          _CellDivider(color: context.theme.divider),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 20,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.view_list_outlined,
                                  size: 18,
                                  color: theme.secondaryText,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'No models yet. Add at least one model before saving.',
                                    style: TextStyle(
                                      color: theme.secondaryText,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          for (var i = 0; i < models.value.length; i++) ...[
                            _CellDivider(color: context.theme.divider),
                            _ModelItem(
                              model: models.value[i],
                              selected: models.value[i] == defaultModel.value,
                              onTap: () => defaultModel.value = models.value[i],
                              onEdit: () => showModelDialog(
                                initialValue: models.value[i],
                                index: i,
                              ),
                              onDelete: () => removeModelAt(i),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static List<String> _normalizeModels(List<String> models) => models
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toSet()
      .toList(growable: false);

  static String _resolveDefaultModel(List<String> models, String? candidate) {
    if (models.isEmpty) return '';
    final normalized = candidate?.trim();
    if (normalized != null &&
        normalized.isNotEmpty &&
        models.contains(normalized)) {
      return normalized;
    }
    return models.first;
  }

  static String _defaultBaseUrlFor(AiProviderType type) => switch (type) {
    AiProviderType.openaiCompatible => '',
    AiProviderType.anthropic => 'https://api.anthropic.com/v1',
    AiProviderType.gemini => 'https://generativelanguage.googleapis.com/v1beta',
  };

  static String _baseUrlHintFor(AiProviderType type) => switch (type) {
    AiProviderType.openaiCompatible => 'https://api.example.com/v1',
    AiProviderType.anthropic => 'https://api.anthropic.com/v1',
    AiProviderType.gemini => 'https://generativelanguage.googleapis.com/v1beta',
  };

  static String _baseUrlHelperTextFor(AiProviderType type) => switch (type) {
    AiProviderType.openaiCompatible =>
      'For OpenAI-compatible APIs, use the server root that exposes /chat/completions.',
    AiProviderType.anthropic =>
      'Anthropic uses the Messages API under /v1/messages.',
    AiProviderType.gemini =>
      'Gemini uses the Google Generative Language API and appends /models/{model}:streamGenerateContent automatically.',
  };

  static String _apiKeyHintFor(AiProviderType type) => switch (type) {
    AiProviderType.openaiCompatible => 'sk-...',
    AiProviderType.anthropic => 'sk-ant-...',
    AiProviderType.gemini => 'AIza...',
  };
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 20, right: 20, bottom: 6, top: 6),
    child: Text(
      title,
      style: TextStyle(
        color: context.theme.text,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _FormFieldCell extends StatelessWidget {
  const _FormFieldCell({
    required this.label,
    required this.child,
    required this.backgroundColor,
    required this.borderColor,
    this.trailing,
  });

  final String label;
  final Widget child;
  final Color backgroundColor;
  final Color borderColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: context.theme.secondaryText,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        _InputSurface(
          backgroundColor: backgroundColor,
          borderColor: borderColor,
          trailing: trailing,
          child: child,
        ),
      ],
    ),
  );
}

class _InputSurface extends StatelessWidget {
  const _InputSurface({
    required this.child,
    required this.backgroundColor,
    required this.borderColor,
    this.trailing,
  });

  final Widget child;
  final Color backgroundColor;
  final Color borderColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: backgroundColor,
      borderRadius: const BorderRadius.all(Radius.circular(10)),
      border: Border.all(color: borderColor),
    ),
    child: Row(
      children: [
        Expanded(child: child),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing!,
        ],
      ],
    ),
  );
}

class _ModelItem extends StatelessWidget {
  const _ModelItem({
    required this.model,
    required this.selected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final String model;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => CellItem(
    selected: selected,
    onTap: onTap,
    title: Row(
      children: [
        Expanded(
          child: Text(
            model,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (selected)
          Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: context.theme.accent.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.all(Radius.circular(999)),
            ),
            child: Text(
              'Default',
              style: TextStyle(
                color: context.theme.accent,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    ),
    description: Text(
      selected ? 'Used for new AI requests' : 'Tap to set as default',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onEdit,
          icon: Icon(Icons.edit_outlined, color: context.theme.icon),
        ),
        IconButton(
          onPressed: onDelete,
          icon: Icon(Icons.delete_outline, color: context.theme.red),
        ),
      ],
    ),
  );
}

class _CellDivider extends StatelessWidget {
  const _CellDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Divider(
    height: 0.5,
    indent: 16,
    endIndent: 16,
    color: color,
  );
}
