import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../db/database_event_bus.dart';
import '../../../db/mixin_database.dart';
import '../../../utils/extension/extension.dart';
import '../../../widgets/app_bar.dart';
import '../../../widgets/mixin_image.dart';
import '../../../widgets/user/user_dialog.dart';
import '../../provider/conversation_provider.dart';
import '../../provider/database_provider.dart';
import '../../provider/ui_context_providers.dart';

final sharedAppsProvider = StreamProvider.autoDispose
    .family<List<App>, String?>((ref, userId) {
      if (userId == null) {
        return Stream.value(const <App>[]);
      }
      final database = ref.watch(databaseProvider).value;
      if (database == null) {
        return Stream.value(const <App>[]);
      }
      return database.favoriteAppDao
          .getFavoriteAppsByUserId(userId)
          .watchWithStream(
            eventStreams: [DataBaseEventBus.instance.updateAppIdStream],
            duration: kVerySlowThrottleDuration,
          );
    });

class SharedAppsPage extends ConsumerWidget {
  const SharedAppsPage(this.conversationState, {super.key});

  final ConversationState conversationState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = conversationState.userId;
    final apps = ref.watch(sharedAppsProvider(userId)).value ?? const [];
    final l10n = ref.watch(localizationProvider);
    final theme = ref.watch(brightnessThemeDataProvider);

    return Scaffold(
      backgroundColor: theme.primary,
      appBar: MixinAppBar(title: Text(l10n.shareApps)),
      body: Column(
        children: [
          const SizedBox(height: 6),
          for (final app in apps) _AppTile(app: app),
        ],
      ),
    );
  }
}

class _AppTile extends ConsumerWidget {
  const _AppTile({required this.app});

  final App app;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    return InkWell(
      onTap: () => showUserDialog(context, ref.container, app.appId),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Row(
          children: [
            _AppIcon(app: app, size: 50),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app.name,
                    style: TextStyle(
                      color: theme.text,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    app.description,
                    maxLines: 1,
                    style: TextStyle(
                      color: theme.secondaryText,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OverlappedAppIcons extends ConsumerWidget {
  OverlappedAppIcons({required this.apps, super.key}) : assert(apps.isNotEmpty);

  final List<App> apps;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    return Stack(
      children: [
        for (var index = 0; index < apps.length; index++)
          Padding(
            padding: EdgeInsets.fromLTRB(index.toDouble() * 14, 0, 0, 0),
            child: ClipOval(
              child: Container(
                color: Color.alphaBlend(
                  theme.listSelected,
                  theme.popUp,
                ),
                padding: const EdgeInsets.all(2),
                child: _AppIcon(size: 24, app: apps[index]),
              ),
            ),
          ),
      ].reversed.toList(),
    );
  }
}

class _AppIcon extends ConsumerWidget {
  const _AppIcon({required this.app, required this.size});

  final App app;

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    return ClipOval(
      child: MixinImage.network(
        app.iconUrl,
        width: size,
        height: size,
        placeholder: () => SizedBox.fromSize(
          size: Size.square(size),
          child: ColoredBox(color: theme.listSelected),
        ),
      ),
    );
  }
}
