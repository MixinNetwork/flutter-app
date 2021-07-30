import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';

import '../constants/resources.dart';
import '../utils/extension/extension.dart';

class StatusPending extends StatelessWidget {
  const StatusPending({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => _StatusLayout(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: SizedBox.fromSize(
                size: const Size.square(10),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.theme.accent,
                  ),
                ),
              ),
            ),
            CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(
                context.theme.accent,
              ),
            ),
          ],
        ),
      );
}

class StatusWarning extends StatelessWidget {
  const StatusWarning({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => _StatusLayout(
        child: Center(
          child: SvgPicture.asset(
            Resources.assetsImagesWarningSvg,
            color: context.theme.text,
          ),
        ),
      );
}

class StatusDownload extends StatelessWidget {
  const StatusDownload({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => _StatusLayout(
        child: Center(
          child: SvgPicture.asset(
            Resources.assetsImagesDownloadSvg,
            color: context.theme.accent,
          ),
        ),
      );
}

class StatusUpload extends StatelessWidget {
  const StatusUpload({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => _StatusLayout(
        child: Center(
          child: SvgPicture.asset(
            Resources.assetsImagesUploadSvg,
            color: context.theme.accent,
          ),
        ),
      );
}

class _StatusLayout extends StatelessWidget {
  const _StatusLayout({
    Key? key,
    required this.child,
  }) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox.fromSize(
        size: const Size.square(38),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.theme.statusBackground,
            shape: BoxShape.circle,
          ),
          child: child,
        ),
      );
}
