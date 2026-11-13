import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../constants/resources.dart';
import '../../../action_button.dart';
import '../../../mixin_image.dart';
import '../image/preview_image_widget.dart';

class NetworkCoverPreview extends StatefulWidget {
  const NetworkCoverPreview({required this.url, super.key});

  final String url;

  static Future<void> push(BuildContext context, String url) => showGeneralDialog(
    context: context,
    barrierColor: Colors.transparent,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    requestFocus: true,
    pageBuilder: (_, _, _) => NetworkCoverPreview(url: url),
  );

  @override
  State<NetworkCoverPreview> createState() => _NetworkCoverPreviewState();
}

class _NetworkCoverPreviewState extends State<NetworkCoverPreview> {
  final controller = TransformImageController();

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.escape): () =>
          Navigator.maybePop(context),
    },
    child: Focus(
      autofocus: true,
      child: Scaffold(
        backgroundColor: const Color.fromRGBO(62, 65, 72, 0.9),
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ActionButton(
                      name: Resources.assetsImagesZoomInSvg,
                      color: Colors.white,
                      onTap: controller.zoomIn,
                    ),
                    ActionButton(
                      name: Resources.assetsImagesZoomOutSvg,
                      color: Colors.white,
                      onTap: controller.zoomOut,
                    ),
                    ActionButton(
                      name: Resources.assetsImagesIcCloseBigSvg,
                      color: Colors.white,
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => ClipRect(
                    child: ImagPreviewWidget(
                      controller: controller,
                      image: SizedBox(
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                        child: MixinImage.network(
                          widget.url,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
