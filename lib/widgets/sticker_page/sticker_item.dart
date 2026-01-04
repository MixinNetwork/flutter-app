import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../../app.dart';
import '../../db/extension/job.dart';
import '../../utils/app_lifecycle.dart';
import '../../utils/extension/extension.dart';
import '../../utils/hook.dart';
import '../cache_lottie.dart';
import '../mixin_image.dart';

void _triggerRefreshJob(BuildContext context, String? stickerId) {
  if (stickerId == null || stickerId.isEmpty) return;
  context.accountServer.addUpdateStickerJob(createUpdateStickerJob(stickerId));
}

class StickerItem extends HookConsumerWidget {
  const StickerItem({
    required this.assetUrl,
    required this.assetType,
    super.key,
    this.stickerId,
    this.errorWidget,
    this.width,
    this.height,
  });

  final String assetUrl;
  final String? assetType;
  final String? stickerId;
  final Widget? errorWidget;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isJson = useMemoized(() => assetType == 'json', [assetType]);

    final playing = useState(true);
    final controller = useAnimationController();
    final isCurrentRoute = useRef(true);

    final secondContext = useSecondNavigatorContext(context);

    final listener = useCallback(() {
      if (isJson && controller.duration == null) return;
      if (isAppActive && isCurrentRoute.value) {
        if (isJson) controller.repeat();
        playing.value = true;
      } else {
        if (isJson) controller.stop();
        playing.value = false;
      }
    }, [controller]);

    useRouteObserver(
      rootRouteObserver,
      context: secondContext,
      didPushNext: () {
        isCurrentRoute.value = false;
        listener();
      },
      didPopNext: () {
        isCurrentRoute.value = true;
        listener();
      },
    );

    useEffect(() {
      listener();
      appActiveListener.addListener(listener);
      return () => appActiveListener.removeListener(listener);
    }, [controller, appActiveListener]);

    final child = isJson
        ? LottieBuilder(
            lottie: CachedNetworkLottie(
              assetUrl,
              proxyConfig: context.database.settingProperties.activatedProxy,
            ),
            controller: controller,
            height: height,
            width: width,
            fit: BoxFit.contain,
            onLoaded: (composition) {
              controller.duration = composition.duration;
              listener();
            },
            errorBuilder: (context, error, stackTrace) {
              _triggerRefreshJob(context, stickerId);
              return errorWidget ?? const SizedBox();
            },
          )
        : MixinImage.network(
            assetUrl,
            height: height,
            width: width,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              _triggerRefreshJob(context, stickerId);
              return errorWidget ?? const SizedBox();
            },
          );

    if (width == null || height == null) {
      return AspectRatio(aspectRatio: 1, child: child);
    }

    return child;
  }
}

class StickerGroupIcon extends StatelessWidget {
  const StickerGroupIcon({
    required this.iconUrl,
    required this.size,
    super.key,
  });

  final String iconUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isLottie = iconUrl.toLowerCase().endsWith('.json');
    return StickerItem(
      assetUrl: iconUrl,
      assetType: isLottie ? 'json' : null,
      width: size,
      height: size,
    );
  }
}
