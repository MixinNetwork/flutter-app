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
import '../message_datetime.dart';
import '../message_status.dart';

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

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => MessageBubble(
          showNip: showNip,
          isCurrentUser: isCurrentUser,
          child: FullScreenPortal(
            builder: (context) => InteractableDecoratedBox(
              onTap: () => context.read<FullScreenVisibleCubit>().emit(true),
              child: Stack(
                children: [
                  Builder(
                    builder: (context) => MarkdownBody(
                      data: message.thumbImage?.postLengthOptimize() ??
                          message.content!.postOptimize(),
                      extensionSet: ExtensionSet.gitHubWeb,
                      styleSheet: markdownStyleSheet(context),
                      imageBuilder: (_, __, ___) => const SizedBox(),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: SvgPicture.asset(
                      Resources.assetsImagesPostDetailSvg,
                      width: 20,
                      height: 20,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: const Color.fromRGBO(0, 0, 0, 0.16),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MessageDatetime(
                            dateTime: message.createdAt,
                            color: const Color.fromRGBO(255, 255, 255, 1),
                          ),
                          if (isCurrentUser)
                            MessageStatusWidget(status: message.status),
                        ],
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
            onTapLink: (String text, String? href, String title) =>
                openUri(href!),
          ),
        ),
      );
}
