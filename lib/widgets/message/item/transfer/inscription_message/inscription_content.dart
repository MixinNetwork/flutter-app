import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hexagon/hexagon.dart';

import '../../../../../constants/resources.dart';
import '../../../../../db/vo/inscription.dart';
import '../../../../../utils/cache_client.dart';
import '../../../../../utils/extension/extension.dart';
import '../../../../../utils/hook.dart';
import '../../../../cache_image.dart';
import 'inscription_message.dart';

class InscriptionContent extends HookWidget {
  const InscriptionContent({
    required this.inscription,
    required this.mode,
    super.key,
  });

  final Inscription? inscription;
  final InscriptionContentMode mode;

  @override
  Widget build(BuildContext context) {
    final defaultInscriptionImage =
        SvgPicture.asset(Resources.assetsImagesInscriptionPlaceholderSvg);

    return AspectRatio(
      aspectRatio: 1,
      child: inscription == null
          ? defaultInscriptionImage
          : inscription?.contentType.startsWith('image') ?? false
              ? CacheImage(
                  inscription?.contentUrl ?? '',
                  errorWidget: () => defaultInscriptionImage,
                  placeholder: () => defaultInscriptionImage,
                )
              : _Text(inscription: inscription, mode: mode),
    );
  }
}

class _Text extends HookWidget {
  const _Text({required this.inscription, required this.mode});

  final Inscription? inscription;
  final InscriptionContentMode mode;

  @override
  Widget build(BuildContext context) {
    final defaultInscriptionImage =
        SvgPicture.asset(Resources.assetsImagesInscriptionPlaceholderSvg);
    final defaultCollectionImage =
        SvgPicture.asset(Resources.assetsImagesCollectionPlaceholderSvg);

    final client = useMemoized(
        () => CacheClient(context.database.settingProperties.activatedProxy,
            cacheInscriptionTextFolderName),
        []);

    final text = useMemoizedFuture(
      () async {
        if (inscription == null) return null;
        final response = await client.get(Uri.parse(inscription!.contentUrl));
        return response.body;
      },
      null,
      keys: [inscription?.contentUrl],
    );

    return (inscription?.contentType.startsWith('text') ?? false) &&
            text.hasData
        ? Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(Resources.assetsImagesTextBgPng),
              LayoutBuilder(
                builder: (context, constraints) => Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    HexagonWidget(
                      type: HexagonType.FLAT,
                      cornerRadius: constraints.maxWidth / 3 / 5,
                      height: constraints.maxWidth / 3,
                      width: constraints.maxWidth / 3,
                      child: SizedBox.square(
                        dimension: constraints.maxWidth / 3,
                        child: CacheImage(
                          inscription!.iconUrl ?? '',
                          errorWidget: () => defaultCollectionImage,
                          placeholder: () => defaultCollectionImage,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: constraints.maxWidth / 40),
                      child: AutoSizeText(
                        text.requireData!,
                        maxLines: mode.maxLines,
                        maxFontSize: 24,
                        // ignore: avoid_redundant_argument_values
                        minFontSize: 12,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color.fromRGBO(255, 167, 36, 1),
                          fontSize:
                              mode == InscriptionContentMode.small ? 14 : 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )
        : defaultInscriptionImage;
  }
}
