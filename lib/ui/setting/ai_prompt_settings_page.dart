import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../ai/model/ai_prompt_template.dart';
import '../../utils/extension/extension.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/cell.dart';
import '../../widgets/toast.dart';
import '../provider/database_provider.dart';

class AiPromptSettingsPage extends HookConsumerWidget {
  const AiPromptSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final database = ref.watch(databaseProvider).requireValue;
    useListenable(database.settingProperties);
    final customizedCount = aiPromptTemplateDefinitions
        .where(
          (definition) =>
              database.settingProperties.hasAiPromptTemplateOverride(
                definition.key,
              ),
        )
        .length;

    return Scaffold(
      backgroundColor: context.theme.background,
      appBar: const MixinAppBar(title: Text('AI Prompt Templates')),
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
                  CellGroup(
                    padding: const EdgeInsets.only(right: 10, left: 10),
                    cellBackgroundColor:
                        context.theme.settingCellBackgroundColor,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customizedCount == 0
                                ? 'All prompts are using built-in defaults.'
                                : '$customizedCount prompt templates currently use custom overrides.',
                            style: TextStyle(
                              color: context.theme.text,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Templates support placeholders like {{conversationId}}, {{currentIsoDateTime}}, {{language}}, and {{input}}. Each editor shows the variables available for that prompt.',
                            style: TextStyle(
                              color: context.theme.secondaryText,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Leave a template empty to disable that prompt block. Saving the exact default text removes the custom override.',
                            style: TextStyle(
                              color: context.theme.secondaryText,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  for (final group in AiPromptTemplateGroup.values) ...[
                    _SectionLabel(title: group.title),
                    CellGroup(
                      padding: const EdgeInsets.only(right: 10, left: 10),
                      cellBackgroundColor:
                          context.theme.settingCellBackgroundColor,
                      child: Column(
                        children: [
                          for (
                            var i = 0;
                            i <
                                aiPromptTemplateDefinitions
                                    .where((item) => item.group == group)
                                    .length;
                            i++
                          ) ...[
                            _PromptTemplateCell(
                              definition: aiPromptTemplateDefinitions
                                  .where((item) => item.group == group)
                                  .elementAt(i),
                            ),
                            if (i !=
                                aiPromptTemplateDefinitions
                                        .where((item) => item.group == group)
                                        .length -
                                    1)
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
}

class _PromptTemplateCell extends HookConsumerWidget {
  const _PromptTemplateCell({required this.definition});

  final AiPromptTemplateDefinition definition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final database = ref.watch(databaseProvider).requireValue;
    final currentValue = database.settingProperties.aiPromptTemplate(
      definition.key,
    );
    final isCustomized = database.settingProperties.hasAiPromptTemplateOverride(
      definition.key,
    );

    return CellItem(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _AiPromptTemplateEditPage(definition: definition),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(definition.title),
          const SizedBox(height: 4),
          Text(
            definition.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.theme.secondaryText,
              fontSize: 13,
              height: 1.3,
            ),
          ),
        ],
      ),
      description: SizedBox(
        width: 120,
        child: Text(
          _statusText(currentValue, isCustomized),
          textAlign: TextAlign.end,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  String _statusText(String value, bool customized) {
    final compact = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    final preview = compact.isEmpty ? 'Empty' : compact;
    final prefix = customized ? 'Custom' : 'Default';
    return '$prefix · $preview';
  }
}

class _AiPromptTemplateEditPage extends HookConsumerWidget {
  const _AiPromptTemplateEditPage({required this.definition});

  final AiPromptTemplateDefinition definition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final database = ref.watch(databaseProvider).requireValue;
    useListenable(database.settingProperties);
    final initialText = database.settingProperties.aiPromptTemplate(
      definition.key,
    );
    final controller = useTextEditingController(text: initialText);
    final theme = context.theme;
    final inputBackgroundColor = context.dynamicColor(
      Colors.white,
      darkColor: const Color.fromRGBO(255, 255, 255, 0.08),
    );
    final inputBorderColor = context.dynamicColor(
      theme.divider,
      darkColor: const Color.fromRGBO(255, 255, 255, 0.10),
    );

    void save() {
      final value = controller.text;
      if (value == definition.defaultValue) {
        database.settingProperties.resetAiPromptTemplate(definition.key);
      } else {
        database.settingProperties.saveAiPromptTemplate(definition.key, value);
      }
      showToastSuccessful();
      Navigator.of(context).pop();
    }

    return Scaffold(
      backgroundColor: theme.background,
      appBar: MixinAppBar(
        title: Text(definition.title),
        actions: [
          TextButton(
            onPressed: () => controller.text = definition.defaultValue,
            child: Text(
              'Use Default',
              style: TextStyle(color: theme.accent, fontSize: 16),
            ),
          ),
          TextButton(
            onPressed: save,
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
                  const _SectionLabel(title: 'Description'),
                  CellGroup(
                    padding: const EdgeInsets.only(right: 10, left: 10),
                    cellBackgroundColor: theme.settingCellBackgroundColor,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        definition.description,
                        style: TextStyle(
                          color: theme.text,
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ),
                  const _SectionLabel(title: 'Variables'),
                  CellGroup(
                    padding: const EdgeInsets.only(right: 10, left: 10),
                    cellBackgroundColor: theme.settingCellBackgroundColor,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _PromptVariableChipWrap(
                        variables: definition.variables,
                        onTap: (variable) =>
                            _insertToken(controller, variable.token),
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
                      'Hover to preview the description. Click a chip to insert it at the current cursor position.',
                      style: TextStyle(
                        color: theme.secondaryText,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const _SectionLabel(title: 'Template'),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: inputBackgroundColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: inputBorderColor),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: TextField(
                          controller: controller,
                          minLines: 10,
                          maxLines: null,
                          style: TextStyle(
                            color: theme.text,
                            fontSize: 15,
                            height: 1.45,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            hintText: definition.defaultValue,
                            hintStyle: TextStyle(color: theme.secondaryText),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 12,
                    ),
                    child: Text(
                      'Empty text disables this prompt block. Saving the exact default text removes the override and falls back to the built-in template.',
                      style: TextStyle(
                        color: theme.secondaryText,
                        fontSize: 13,
                        height: 1.4,
                      ),
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

  void _insertToken(TextEditingController controller, String token) {
    final value = controller.value;
    final selection = value.selection;
    final hasSelection = selection.isValid;
    final start = hasSelection ? selection.start : value.text.length;
    final end = hasSelection ? selection.end : value.text.length;
    final safeStart = start < 0 ? value.text.length : start;
    final safeEnd = end < 0 ? value.text.length : end;
    final nextText = value.text.replaceRange(safeStart, safeEnd, token);
    controller.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: safeStart + token.length),
    );
  }
}

class _PromptVariableChipWrap extends StatelessWidget {
  const _PromptVariableChipWrap({required this.variables, required this.onTap});

  final List<AiPromptVariable> variables;
  final ValueChanged<AiPromptVariable> onTap;

  @override
  Widget build(BuildContext context) {
    final fillColor = context.dynamicColor(
      const Color.fromRGBO(0, 0, 0, 0.04),
      darkColor: const Color.fromRGBO(255, 255, 255, 0.08),
    );
    final outlineColor = context.dynamicColor(
      const Color.fromRGBO(0, 0, 0, 0.08),
      darkColor: const Color.fromRGBO(255, 255, 255, 0.12),
    );

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final variable in variables)
          Tooltip(
            message: variable.description,
            waitDuration: const Duration(milliseconds: 250),
            child: ActionChip(
              onPressed: () => onTap(variable),
              label: Text(
                variable.token,
                style: TextStyle(
                  color: context.theme.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              labelPadding: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              side: BorderSide(color: outlineColor),
              backgroundColor: fillColor,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 20, bottom: 10, top: 12),
    child: Text(
      title,
      style: TextStyle(
        color: context.theme.secondaryText,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
