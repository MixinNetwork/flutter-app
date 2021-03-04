import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/bloc/bloc_converter.dart';
import 'package:flutter_app/bloc/paging/paging_bloc.dart';
import 'package:flutter_app/bloc/simple_cubit.dart';
import 'package:flutter_app/constants/resources.dart';
import 'package:flutter_app/db/dao/messages_dao.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/generated/l10n.dart';
import 'package:flutter_app/widgets/avatar_view/avatar_view.dart';
import 'package:flutter_app/widgets/message/item/image_message/preview_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';

import '../../../action_button.dart';
import '../../../brightness_observer.dart';
import '../../../full_screen_portal.dart';
import '../../../interacter_decorated_box.dart';

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
  Widget build(BuildContext context) => BlocProvider(
        create: (BuildContext context) => IntCubit(index),
        child: Builder(
          builder: (context) => BlocProvider(
            create: (BuildContext context) => PreviewBloc(
              conversationId: conversationId,
              messagesDao: messagesDao,
              index: index,
              intCubit: context.read<IntCubit>(),
            ),
            child: Builder(
              builder: (context) =>
                  BlocBuilder<PreviewBloc, PagingState<MessageItem>>(
                builder: (context, state) => Column(
                  children: [
                    Container(
                      height: 70,
                      decoration: BoxDecoration(
                        color: BrightnessData.themeOf(context).primary,
                      ),
                      child: Builder(
                        builder: (context) {
                          if (state.map.isEmpty) return const SizedBox();
                          return Row(
                            children: [
                              const SizedBox(width: 100),
                              Expanded(
                                child:
                                    BlocConverter<IntCubit, int, MessageItem?>(
                                  converter: (index) => state
                                      .map[index.clamp(0, state.count - 1)],
                                  builder: (context, message) {
                                    if (message == null)
                                      return const SizedBox();
                                    return _Bar(message: message);
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          if (state.map.isEmpty) return const SizedBox();
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              InteractableDecoratedBox.color(
                                decoration: const BoxDecoration(
                                  color: Color.fromRGBO(62, 65, 72, 0.9),
                                ),
                                child: const SizedBox(),
                                onTap: () =>
                                    FullScreenPortal.of(context).emit(false),
                              ),
                              BlocConverter<IntCubit, int, MessageItem?>(
                                converter: (index) =>
                                    state.map[index.clamp(0, state.count - 1)],
                                builder: (context, message) {
                                  if (message == null) return const SizedBox();
                                  return _Item(message: message);
                                },
                              ),
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 30),
                                  child: BlocBuilder<IntCubit, int>(
                                    builder: (context, index) => Row(
                                      children: [
                                        if (index < state.count - 1)
                                          InteractableDecoratedBox(
                                            child: SvgPicture.asset(
                                                Resources.assetsImagesNextSvg),
                                            onTap: () => context
                                                .read<IntCubit>()
                                                .emit((index + 1)
                                                    .clamp(0, state.count - 1)),
                                          ),
                                        const Spacer(),
                                        if (index > 0)
                                          InteractableDecoratedBox(
                                            child: SvgPicture.asset(
                                                Resources.assetsImagesPrevSvg),
                                            onTap: () => context
                                                .read<IntCubit>()
                                                .emit((index - 1)
                                                    .clamp(0, state.count - 1)),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class _Bar extends StatelessWidget {
  const _Bar({
    Key? key,
    required this.message,
  }) : super(key: key);

  final MessageItem message;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AvatarWidget(
          name: message.userFullName!,
          size: 36,
          avatarUrl: message.avatarUrl,
          userId: message.userId,
        ),
        const SizedBox(width: 10),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.userFullName!,
              style: TextStyle(
                fontSize: 16,
                color: BrightnessData.themeOf(context).text,
              ),
            ),
            Text(
              message.userIdentityNumber,
              style: TextStyle(
                fontSize: 14,
                color: BrightnessData.themeOf(context).secondaryText,
              ),
            ),
          ],
        ),
        const Spacer(),
        ActionButton(
          name: Resources.assetsImagesZoomInSvg,
          size: 20,
          onTap: () {},
        ),
        const SizedBox(width: 12),
        ActionButton(
          name: Resources.assetsImagesZoomOutSvg,
          size: 20,
          onTap: () {},
        ),
        const SizedBox(width: 12),
        ActionButton(
          name: Resources.assetsImagesShareSvg,
          size: 20,
          onTap: () {},
        ),
        const SizedBox(width: 12),
        ActionButton(
          name: Resources.assetsImagesCopySvg,
          size: 20,
          onTap: () {},
        ),
        const SizedBox(width: 12),
        ActionButton(
          name: Resources.assetsImagesAttachmentDownloadSvg,
          size: 20,
          onTap: () async {
            // TODO toast
            if (message.mediaUrl?.isEmpty ?? true) return;
            final directory = await getDirectoryPath(
                confirmButtonText: Localization.of(context).save);
            await File(message.mediaUrl!)
                .copy('$directory${Platform.pathSeparator}${basename(message.mediaUrl!)}');
          },
        ),
        const SizedBox(width: 24),
      ],
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    Key? key,
    required this.message,
  }) : super(key: key);
  final MessageItem message;

  @override
  Widget build(BuildContext context) => InteractableDecoratedBox.color(
        child: Image.file(
          File(message.mediaUrl ?? ''),
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Image.memory(
            base64Decode(message.thumbImage!),
            fit: BoxFit.contain,
          ),
        ),
        onTap: () => FullScreenPortal.of(context).emit(false),
      );
}
