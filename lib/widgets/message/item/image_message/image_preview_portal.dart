import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_app/bloc/paging/paging_bloc.dart';
import 'package:flutter_app/constants/resources.dart';
import 'package:flutter_app/db/dao/messages_dao.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/widgets/avatar_view/avatar_view.dart';
import 'package:flutter_app/widgets/message/item/image_message/preview_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../../action_button.dart';
import '../../../brightness_observer.dart';

class ImagePreviewPortal extends StatelessWidget {
  const ImagePreviewPortal({
    Key? key,
    required this.conversationId,
    required this.messagesDao,
    required this.index,
  }) : super(key: key);

  final String conversationId;
  final MessagesDao messagesDao;
  final int index;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider<PageController>(
        create: (BuildContext context) => PageController(),
        child: Builder(
          builder: (context) => BlocProvider(
            create: (BuildContext context) => PreviewBloc(
              conversationId: conversationId,
              messagesDao: messagesDao,
              index: index,
              pageController: context.read<PageController>(),
            ),
            child: Builder(
              builder: (context) => Column(
                children: [
                  const SizedBox(height: 70),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: BrightnessData.themeOf(context).primary,
                    ),
                    child: Selector<PageController, MessageItem>(
                      selector: (context, pageController) => context
                          .read<PreviewBloc>()
                          .state
                          .map[pageController.page!.round()]!,
                      builder: (context, message, child) => Row(
                        children: [
                          const SizedBox(width: 100),
                          AvatarWidget(
                            name: message.userFullName!,
                            size: 36,
                            avatarUrl: message.avatarUrl,
                            userId: message.userId,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            children: [
                              Text(
                                message.userFullName!,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: BrightnessData.themeOf(context).text,
                                ),
                              ),
                              Text(
                                message.userId,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 16,
                                  color: BrightnessData.themeOf(context)
                                      .secondaryText,
                                ),
                              ),
                            ],
                            mainAxisSize: MainAxisSize.min,
                          ),
                          const Spacer(),
                          ActionButton(
                            name: Resources.assetsImagesZoomInSvg,
                            onTap: () {},
                          ),
                          ActionButton(
                            name: Resources.assetsImagesZoomOutSvg,
                            onTap: () {},
                          ),
                          ActionButton(
                            name: Resources.assetsImagesShareSvg,
                            onTap: () {},
                          ),
                          ActionButton(
                            name: Resources.assetsImagesCopySvg,
                            onTap: () {},
                          ),
                          ActionButton(
                            name: Resources.assetsImagesAttachmentDownloadSvg,
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                  Stack(
                    children: [
                      const ColoredBox(
                        color: Color.fromRGBO(62,65,72,0.9),
                      ),
                      PageView.builder(
                        itemBuilder: (BuildContext context, int index) {
                          final messageItem =
                              context.read<PreviewBloc>().state.map[index];
                          if (messageItem == null) return const SizedBox();
                          return _Item(
                            message: messageItem,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _Item extends StatelessWidget {
  const _Item({
    Key? key,
    required this.message,
  }) : super(key: key);
  final MessageItem message;

  @override
  Widget build(BuildContext context) {
    return Image.file(
      File(message.mediaUrl!),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Image.memory(
        base64Decode(message.thumbImage!),
        fit: BoxFit.cover,
      ),
    );
  }
}
