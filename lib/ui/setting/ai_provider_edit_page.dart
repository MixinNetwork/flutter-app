import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../ai/model/ai_provider_config.dart';
import '../../ai/model/ai_provider_type.dart';
import '../../utils/extension/extension.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/cell.dart';
import '../../widgets/toast.dart';
import '../provider/database_provider.dart';

class AiProviderEditPage extends HookConsumerWidget {
  const AiProviderEditPage({super.key, this.initial});

  final AiProviderConfig? initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final database = ref.watch(databaseProvider).requireValue;
    final nameController = useTextEditingController(text: initial?.name ?? '');
    final baseUrlController = useTextEditingController(
      text: initial?.baseUrl ?? '',
    );
    final apiKeyController = useTextEditingController(
      text: initial?.apiKey ?? '',
    );
    final modelController = useTextEditingController(
      text: initial?.model ?? '',
    );
    final providerType = useState(
      initial?.type ?? AiProviderType.openaiCompatible,
    );

    return Scaffold(
      backgroundColor: context.theme.background,
      appBar: MixinAppBar(
        title: Text(initial == null ? 'Add AI Provider' : 'Edit AI Provider'),
        actions: [
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              final baseUrl = baseUrlController.text.trim();
              final apiKey = apiKeyController.text.trim();
              final model = modelController.text.trim();
              if (name.isEmpty ||
                  baseUrl.isEmpty ||
                  apiKey.isEmpty ||
                  model.isEmpty) {
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
                            model: model,
                          ))
                      .copyWith(
                        name: name,
                        type: providerType.value,
                        baseUrl: baseUrl,
                        apiKey: apiKey,
                        model: model,
                      );
              database.settingProperties.saveAiProvider(provider);
              Navigator.of(context).pop();
            },
            child: Text(
              'Save',
              style: TextStyle(color: context.theme.accent, fontSize: 16),
            ),
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          child: CellGroup(
            cellBackgroundColor: context.theme.settingCellBackgroundColor,
            child: Column(
              children: [
                _TextFieldCell(
                  title: 'Display Name',
                  controller: nameController,
                ),
                _ProviderTypeCell(
                  value: providerType.value,
                  onChanged: (value) => providerType.value = value,
                ),
                _TextFieldCell(
                  title: 'Base URL',
                  controller: baseUrlController,
                ),
                _TextFieldCell(
                  title: 'API Key',
                  controller: apiKeyController,
                  obscureText: true,
                ),
                _TextFieldCell(title: 'Model', controller: modelController),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProviderTypeCell extends StatelessWidget {
  const _ProviderTypeCell({required this.value, required this.onChanged});

  final AiProviderType value;
  final ValueChanged<AiProviderType> onChanged;

  @override
  Widget build(BuildContext context) => CellItem(
    title: const Text('Provider Type'),
    trailing: DropdownButtonHideUnderline(
      child: DropdownButton<AiProviderType>(
        value: value,
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
        items: AiProviderType.values
            .map(
              (type) => DropdownMenuItem<AiProviderType>(
                value: type,
                child: Text(
                  type == AiProviderType.anthropic
                      ? 'Anthropic'
                      : 'OpenAI Compatible',
                ),
              ),
            )
            .toList(),
      ),
    ),
  );
}

class _TextFieldCell extends StatelessWidget {
  const _TextFieldCell({
    required this.title,
    required this.controller,
    this.obscureText = false,
  });

  final String title;
  final TextEditingController controller;
  final bool obscureText;

  @override
  Widget build(BuildContext context) => CellItem(
    title: TextField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(color: context.theme.text, fontSize: 16),
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: title,
        hintStyle: TextStyle(color: context.theme.secondaryText),
      ),
    ),
    trailing: const SizedBox.shrink(),
  );
}
