import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_svg/svg.dart';
import 'package:markdown/markdown.dart';
import 'package:provider/provider.dart';

import '../../../constants/resources.dart';
import '../../../db/mixin_database.dart' hide Offset, Message;
import '../../../utils/markdown.dart';
import '../../../utils/uri_utils.dart';
import '../../brightness_observer.dart';
import '../../full_screen_portal.dart';
import '../../interacter_decorated_box.dart';
import '../message_bubble.dart';
import '../message_datetime_and_status.dart';

class PostMessage extends StatelessWidget {
  const PostMessage({
    Key? key,
    required this.showNip,
    required this.isCurrentUser,
    required this.message,
  }) : super(key: key);

  final bool showNip;
  final bool isCurrentUser;
  final MessageItem message;

  static const _decoration = BoxDecoration(
    borderRadius: BorderRadius.all(Radius.circular(8)),
    color: Color.fromRGBO(0, 0, 0, 0.2),
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => MessageBubble(
          messageId: message.messageId,
          showNip: showNip,
          isCurrentUser: isCurrentUser,
          child: FullScreenPortal(
            builder: (context) => InteractableDecoratedBox(
              onTap: () => context.read<FullScreenVisibleCubit>().emit(true),
              child: Stack(
                children: [
                  Builder(
                    builder: (context) => ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: 64,
                        minWidth: 128,
                      ),
                      child: MarkdownBody(
                        data: message.thumbImage?.postLengthOptimize() ??
                            message.content!.postOptimize(),
                        extensionSet: ExtensionSet.gitHubWeb,
                        styleSheet: markdownStyleSheet(context),
                        imageBuilder: (_, __, ___) => const SizedBox(),
                        onTapLink: (String text, String? href, String title) {
                          if (href?.isEmpty ?? true) return;

                          openUri(context, href!);
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      decoration: _decoration,
                      alignment: Alignment.center,
                      child: SvgPicture.asset(
                        Resources.assetsImagesPostDetailSvg,
                        width: 20,
                        height: 20,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      decoration: _decoration,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      child: MessageDatetimeAndStatus(
                        isCurrentUser: isCurrentUser,
                        createdAt: message.createdAt,
                        color: const Color.fromRGBO(255, 255, 255, 1),
                        status: message.status,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            portalBuilder: (BuildContext context) =>
                PostPreview(message: message),
          ),
        ),
      );
}

class PostPreview extends StatelessWidget {
  const PostPreview({
    Key? key,
    required this.message,
  }) : super(key: key);

  final MessageItem message;

  @override
  Widget build(BuildContext context) => InteractableDecoratedBox(
        decoration: BoxDecoration(
          color: BrightnessData.themeOf(context).background,
        ),
        onTap: () {
          context.read<FullScreenVisibleCubit>().emit(false);
        },
        child: Padding(
          padding: const EdgeInsets.only(top: 32),
          child: Markdown(
            data: message.thumbImage ?? message.content!,
            extensionSet: ExtensionSet.gitHubWeb,
            styleSheet: markdownStyleSheet(context),
            selectable: true,
            onTapLink: (String text, String? href, String title) =>
                openUri(context, href!),
          ),
        ),
      );
}
