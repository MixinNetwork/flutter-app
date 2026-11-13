import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../constants/resources.dart';
import '../../../../utils/extension/extension.dart';
import '../../../../utils/platform.dart';
import '../../../action_button.dart';
import '../../../image.dart';
import '../../../media_image_pipeline.dart';
import '../../../mixin_image.dart';
import '../image/preview_image_widget.dart';

/// The image preview of a network image, such as an AppCard cover.
class NetworkCoverPreview extends HookWidget {
  const NetworkCoverPreview({required this.url, this.thumbnail, super.key});

  final String url;

  /// A blurhash or base64 image that shows until [url] loads.
  final String? thumbnail;

  static Future<void> push(
    BuildContext context, {
    required String url,
    String? thumbnail,
  }) => showGeneralDialog(
    context: context,
    barrierColor: Colors.transparent,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    requestFocus: true,
    pageBuilder: (_, _, _) =>
        NetworkCoverPreview(url: url, thumbnail: thumbnail),
  );

  @override
  Widget build(BuildContext context) {
    final controller = useMemoized(TransformImageController.new);
    final proxyConfig = context.database.settingProperties.activatedProxy;
    // The same provider as MixinImage.network, so the preview uses the
    // download of the card.
    final provider = useMemoized(
      () => resolveMediaImageProvider(NetworkImage(url), proxyConfig),
      [url, proxyConfig],
    );
    final imageSize = useState<Size?>(null);
    useEffect(() {
      final stream = provider.resolve(ImageConfiguration.empty);
      final listener = ImageStreamListener(
        (info, _) => imageSize.value = Size(
          info.image.width / info.scale,
          info.image.height / info.scale,
        ),
        onError: (_, _) {},
      );
      stream.addListener(listener);
      return () => stream.removeListener(listener);
    }, [provider]);

    final thumbnail = this.thumbnail;
    Widget placeholder() => thumbnail == null || thumbnail.isEmpty
        ? const SizedBox()
        : ImageByBlurHashOrBase64(imageData: thumbnail, fit: BoxFit.contain);

    return FocusableActionDetector(
      autofocus: true,
      shortcuts: {
        const SingleActivator(LogicalKeyboardKey.escape): const DismissIntent(),
        const SingleActivator(LogicalKeyboardKey.zoomIn): const _ZoomInIntent(),
        SingleActivator(
          LogicalKeyboardKey.equal,
          meta: kPlatformIsDarwin,
          control: !kPlatformIsDarwin,
        ): const _ZoomInIntent(),
        const SingleActivator(LogicalKeyboardKey.zoomOut):
            const _ZoomOutIntent(),
        SingleActivator(
          LogicalKeyboardKey.minus,
          meta: kPlatformIsDarwin,
          control: !kPlatformIsDarwin,
        ): const _ZoomOutIntent(),
        SingleActivator(
          LogicalKeyboardKey.keyR,
          meta: kPlatformIsDarwin,
          control: !kPlatformIsDarwin,
        ): const _RotateIntent(),
      },
      actions: {
        DismissIntent: CallbackAction<DismissIntent>(
          onInvoke: (_) => Navigator.maybePop(context),
        ),
        _ZoomInIntent: CallbackAction<_ZoomInIntent>(
          onInvoke: (_) => controller.zoomIn(),
        ),
        _ZoomOutIntent: CallbackAction<_ZoomOutIntent>(
          onInvoke: (_) => controller.zoomOut(),
        ),
        _RotateIntent: CallbackAction<_RotateIntent>(
          onInvoke: (_) => controller.rotate(),
        ),
      },
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              Container(
                height: 70,
                padding: const EdgeInsets.only(right: 24),
                decoration: BoxDecoration(color: context.theme.primary),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  spacing: 14,
                  children: [
                    ActionButton(
                      name: Resources.assetsImagesZoomInSvg,
                      color: context.theme.icon,
                      size: 20,
                      onTap: controller.zoomIn,
                    ),
                    ActionButton(
                      name: Resources.assetsImagesZoomOutSvg,
                      color: context.theme.icon,
                      size: 20,
                      onTap: controller.zoomOut,
                    ),
                    ActionButton(
                      name: Resources.assetsImagesRotatoSvg,
                      color: context.theme.icon,
                      size: 20,
                      onTap: controller.rotate,
                    ),
                    ActionButton(
                      name: Resources.assetsImagesIcCloseBigSvg,
                      color: context.theme.icon,
                      size: 20,
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = imageSize.value;
                    if (size == null) {
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => Navigator.maybePop(context),
                        child: DecoratedBox(
                          decoration: const BoxDecoration(
                            color: Color.fromRGBO(62, 65, 72, 0.9),
                          ),
                          child: placeholder(),
                        ),
                      );
                    }
                    return PreviewImageViewport(
                      imageSize: size,
                      viewport: constraints.biggest,
                      controller: controller,
                      image: MixinImage.network(
                        url,
                        fit: BoxFit.contain,
                        placeholder: placeholder,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZoomInIntent extends Intent {
  const _ZoomInIntent();
}

class _ZoomOutIntent extends Intent {
  const _ZoomOutIntent();
}

class _RotateIntent extends Intent {
  const _RotateIntent();
}
