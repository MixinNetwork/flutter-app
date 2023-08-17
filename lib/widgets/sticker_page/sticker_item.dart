import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../../app.dart';
import '../../utils/app_lifecycle.dart';
import '../../utils/hook.dart';
import '../cache_image.dart';
import '../cache_lottie.dart';

class StickerItem extends HookConsumerWidget {
  const StickerItem({
    super.key,
    required this.assetUrl,
    required this.assetType,
    this.errorWidget,
    this.width,
    this.height,
  });

  final String assetUrl;
  final String? assetType;
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
            lottie: CachedNetworkLottie(assetUrl),
            controller: controller,
            height: height,
            width: width,
            fit: BoxFit.contain,
            onLoaded: (composition) {
              controller.duration = composition.duration;
              listener();
            },
            errorBuilder:
                errorWidget != null ? (_, __, ___) => errorWidget! : null,
          )
        : CacheImage(
            assetUrl,
            height: height,
            width: width,
            controller: playing,
            fit: BoxFit.contain,
            errorWidget: errorWidget != null ? () => errorWidget! : null,
          );

    if (width == null || height == null) {
      return AspectRatio(aspectRatio: 1, child: child);
    }

    return child;
  }
}

class StickerGroupIcon extends StatelessWidget {
  const StickerGroupIcon({
    super.key,
    required this.iconUrl,
    required this.size,
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
