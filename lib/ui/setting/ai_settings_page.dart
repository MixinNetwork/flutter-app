import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../utils/extension/extension.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/cell.dart';
import '../../widgets/toast.dart';
import '../provider/database_provider.dart';
import 'ai_provider_edit_page.dart';

class AiSettingsPage extends HookConsumerWidget {
  const AiSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final database = ref.watch(databaseProvider).requireValue;
    useListenable(database.settingProperties);
    final providers = database.settingProperties.aiProviders;
    final selectedId = database.settingProperties.selectedAiProviderId;

    return Scaffold(
      backgroundColor: context.theme.background,
      appBar: MixinAppBar(
        title: const Text('AI Settings'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const AiProviderEditPage(),
              ),
            ),
            child: Text(
              'Add',
              style: TextStyle(color: context.theme.accent, fontSize: 16),
            ),
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (providers.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No AI provider configured yet.',
                    style: TextStyle(color: context.theme.secondaryText),
                  ),
                )
              else
                CellGroup(
                  cellBackgroundColor: context.theme.settingCellBackgroundColor,
                  child: Column(
                    children: providers.map((provider) {
                      final selected = provider.id == selectedId;
                      return CellItem(
                        title: Text(provider.name),
                        description: Text(provider.model),
                        selected: selected,
                        onTap: () =>
                            database.settingProperties.selectedAiProviderId =
                                provider.id,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: provider.enabled,
                              onChanged: (value) {
                                database.settingProperties.saveAiProvider(
                                  provider.copyWith(enabled: value),
                                );
                              },
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      AiProviderEditPage(initial: provider),
                                ),
                              ),
                              icon: Icon(
                                Icons.edit_outlined,
                                color: context.theme.icon,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                database.settingProperties.removeAiProvider(
                                  provider.id,
                                );
                                showToastSuccessful();
                              },
                              icon: Icon(
                                Icons.delete_outline,
                                color: context.theme.red,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
