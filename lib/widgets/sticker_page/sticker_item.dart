import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lottie/lottie.dart';

import '../../app.dart';
import '../../utils/app_lifecycle.dart';
import '../../utils/hook.dart';
import '../cache_image.dart';

class StickerItem extends HookWidget {
  const StickerItem({
    Key? key,
    required this.assetUrl,
    required this.assetType,
    this.placeholder,
    this.width,
    this.height,
  }) : super(key: key);

  final String assetUrl;
  final String? assetType;
  final Widget? placeholder;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    late Widget child;
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

    if (isJson) {
      child = Lottie.network(
        assetUrl,
        controller: controller,
        height: height,
        width: width,
        fit: BoxFit.contain,
        onLoaded: (composition) {
          controller.duration = composition.duration;
          listener();
        },
      );
    } else {
      child = CacheImage(
        assetUrl,
        height: height,
        width: width,
        controller: playing,
        fit: BoxFit.contain,
        placeholder: () => placeholder ?? const SizedBox(),
      );
    }

    if (width == null || height == null) {
      return AspectRatio(aspectRatio: 1, child: child);
    }

    return child;
  }
}
