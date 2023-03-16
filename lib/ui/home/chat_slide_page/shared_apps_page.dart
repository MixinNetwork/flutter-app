import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../db/database_event_bus.dart';
import '../../../db/mixin_database.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/hook.dart';
import '../../../widgets/app_bar.dart';
import '../../../widgets/cache_image.dart';
import '../../../widgets/user/user_dialog.dart';
import '../bloc/conversation_cubit.dart';

class SharedAppsPage extends HookWidget {
  const SharedAppsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = useMemoized(() {
      final userId = context.read<ConversationCubit>().state?.userId;
      assert(userId != null, 'userId is null');
      return userId ?? '';
    });

    final apps = useMemoizedStream(
            () => context.database.favoriteAppDao
                .getFavoriteAppsByUserId(userId)
                .watchWithStream(
                    eventStreams: [DataBaseEventBus.instance.updateAppIdStream],
                    duration: kVerySlowThrottleDuration),
            keys: [userId]).data ??
        const [];

    return Scaffold(
      backgroundColor: context.theme.primary,
      appBar: MixinAppBar(
        title: Text(context.l10n.shareApps),
      ),
      body: Column(
        children: [
          const SizedBox(height: 6),
          for (final app in apps) _AppTile(app: app),
        ],
      ),
    );
  }
}

class _AppTile extends StatelessWidget {
  const _AppTile({required this.app});

  final App app;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => showUserDialog(context, app.appId),
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
                      style: TextStyle(color: context.theme.text, fontSize: 16),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      app.description,
                      maxLines: 1,
                      style: TextStyle(
                        color: context.theme.secondaryText,
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

class OverlappedAppIcons extends StatelessWidget {
  OverlappedAppIcons({super.key, required this.apps}) : assert(apps.isNotEmpty);

  final List<App> apps;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          for (var index = 0; index < apps.length; index++)
            Padding(
              padding: EdgeInsets.fromLTRB(index.toDouble() * 14, 0, 0, 0),
              child: ClipOval(
                child: Container(
                  color: Color.alphaBlend(
                    context.theme.listSelected,
                    context.theme.popUp,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: _AppIcon(size: 24, app: apps[index]),
                ),
              ),
            ),
        ].reversed.toList(),
      );
}

class _AppIcon extends StatelessWidget {
  const _AppIcon({required this.app, required this.size});

  final App app;

  final double size;

  @override
  Widget build(BuildContext context) => ClipOval(
        child: CacheImage(
          app.iconUrl,
          width: size,
          height: size,
          placeholder: () => SizedBox.fromSize(
            size: Size.square(size),
            child: ColoredBox(color: context.theme.listSelected),
          ),
        ),
      );
}
