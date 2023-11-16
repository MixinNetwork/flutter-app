import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../db/dao/sticker_dao.dart';
import '../../../db/mixin_database.dart';
import '../../../enum/encrypt_category.dart';

import '../../../ui/provider/conversation_provider.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/hook.dart';
import '../../../utils/load_balancer_utils.dart';
import '../../../utils/logger.dart';
import '../../app_bar.dart';
import '../../buttons.dart';
import '../../cache_image.dart';
import '../../dialog.dart';
import '../../sticker_page/sticker_item.dart';
import '../../toast.dart';
import '../../user_selector/conversation_selector.dart';
import '../item/action_card/action_card_data.dart';
import '../item/action_card/action_message.dart';
import '../item/contact_message_widget.dart';
import '../item/post_message.dart';
import '../message.dart';
import '../message_bubble.dart';
import 'send_image_data.dart';

enum _Category {
  text,
  image,
  sticker,
  contact,
  post,
  // ignore: constant_identifier_names
  app_card,
}

extension _CategoriesExtension on String {
  _Category? get category => _Category.values.byName(toLowerCase());
}

Future<bool> showSendDialog(
  BuildContext context,
  String? category,
  String? conversationId,
  String? data,
  App? app,
) async {
  final _category = category?.category;
  if (_category == null || data == null || data.isEmpty) return false;

  final _conversationId =
      context.providerContainer.read(currentConversationIdProvider) ==
              conversationId
          ? conversationId
          : null;

  dynamic result;
  try {
    final _data =
        await utf8DecodeWithIsolate(await base64DecodeWithIsolate(data));

    switch (_category) {
      case _Category.image:
        {
          final json =
              await jsonDecodeWithIsolate(_data) as Map<String, dynamic>;
          result = SendImageData.fromJson(json);
        }
      case _Category.contact:
        {
          final json =
              await jsonDecodeWithIsolate(_data) as Map<String, dynamic>;
          if (json['user_id'] == null || (json['user_id'] as String).isEmpty) {
            return false;
          }
          result = json['user_id'];
        }
      case _Category.sticker:
        {
          if (!Uuid.isValidUUID(fromString: _data)) {
            w('Invalid sticker id: $_data');
            return false;
          }
          result = _data;
        }
      case _Category.app_card:
        {
          final json =
              await jsonDecodeWithIsolate(_data) as Map<String, dynamic>;
          result = AppCardData.fromJson(json);
        }
      // ignore: no_default_cases
      default:
        result = _data;
        break;
    }
  } catch (e, s) {
    w('showSendDialog error: $e, $s');
    return false;
  }

  await showMixinDialog(
    context: context,
    child: _SendPage(_category, _conversationId, result, app),
  );

  return true;
}

class _SendPage extends HookConsumerWidget {
  const _SendPage(this.category, this.conversationId, this.data, this.app);

  final _Category category;
  final String? conversationId;
  final dynamic data;
  final App? app;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = useMemoized(() {
      String _category;
      switch (category) {
        case _Category.text:
          _category = context.l10n.text;
        case _Category.image:
          _category = context.l10n.image;
        case _Category.sticker:
          _category = context.l10n.sticker;
        case _Category.contact:
          _category = context.l10n.contact;
        case _Category.post:
          _category = context.l10n.post;
        case _Category.app_card:
          _category = context.l10n.card;
      }
      if (app != null) {
        return context.l10n.shareMessageDescription(
            '${app?.name}(${app?.appNumber})', _category);
      }
      return context.l10n.shareMessageDescriptionEmpty(_category);
    }, [category, app]);

    final child = useMemoized(() {
      if (category == _Category.text) return _Text(data as String);
      if (category == _Category.image) return _Image(data as SendImageData);
      if (category == _Category.sticker) return _Sticker(data as String);
      if (category == _Category.contact) return _Contact(data as String);
      if (category == _Category.post) return _Post(data as String);
      if (category == _Category.app_card) return _AppCard(data as AppCardData);

      return _Text(data as String);
    }, [category, data]);

    Future<void> sendMessage() async {
      EncryptCategory? encryptCategory;
      var _conversationId = conversationId;
      if (_conversationId == null) {
        final result = await showConversationSelector(
          context: context,
          singleSelect: true,
          title: context.l10n.forward,
          onlyContact: false,
        );
        _conversationId = result?.firstOrNull?.conversationId;
        encryptCategory = result?.firstOrNull?.encryptCategory;
      }
      if (encryptCategory == null && _conversationId != null) {
        final conversation = await context.database.conversationDao
            .conversationItem(_conversationId)
            .getSingleOrNull();
        final ownerId = conversation?.ownerId;
        final isBotConversation = conversation?.isBotConversation;
        if (ownerId == null || isBotConversation == null) return;
        encryptCategory = await context.database.conversationDao
            .getEncryptCategory(ownerId, isBotConversation);
      }

      if (_conversationId == null || encryptCategory == null) return;

      await _sendMessage(
          context, _conversationId, encryptCategory, category, data);
      Navigator.pop(context);
    }

    return SizedBox(
      width: 480,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MixinAppBar(
            title: Text(title),
            actions: const [MixinCloseButton()],
            leading: const SizedBox(),
            backgroundColor: context.theme.popUp,
          ),
          const SizedBox(height: 12),
          Container(
            width: 340,
            height: 340,
            decoration: BoxDecoration(
              color: context.dynamicColor(
                const Color.fromRGBO(245, 247, 250, 1),
                darkColor: const Color.fromRGBO(255, 255, 255, 0.08),
              ),
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.all(34),
            child: child,
          ),
          const SizedBox(height: 54),
          MixinButton(
            onTap: sendMessage,
            child: Text(
              (conversationId != null)
                  ? context.l10n.send
                  : context.l10n.forward,
            ),
          ),
          const SizedBox(height: 56),
        ],
      ),
    );
  }
}

Future<void> _sendMessage(BuildContext context, String conversationId,
    EncryptCategory encryptCategory, _Category category, dynamic data) async {
  if (category == _Category.text) {
    return context.accountServer.sendTextMessage(
        data as String, encryptCategory,
        conversationId: conversationId);
  }
  if (category == _Category.post) {
    return context.accountServer.sendPostMessage(
        data as String, encryptCategory,
        conversationId: conversationId);
  }
  if (category == _Category.sticker) {
    return context.accountServer.sendStickerMessage(
        data as String, null, encryptCategory,
        conversationId: conversationId);
  }
  if (category == _Category.contact) {
    return context.accountServer.sendContactMessage(
        data as String, null, encryptCategory,
        conversationId: conversationId);
  }
  if (category == _Category.app_card) {
    return context.accountServer.sendAppCardMessage(
      data: data as AppCardData,
      conversationId: conversationId,
    );
  }
  if (category == _Category.image) {
    final sendImageData = data as SendImageData;
    await runWithLoading(
      () => context.accountServer.sendImageMessageByUrl(
        encryptCategory,
        sendImageData.url,
        sendImageData.url,
        conversationId: conversationId,
        defaultGifMimeType: false,
      ),
    );
  }
}

final _bubbleClipper = BubbleClipper(
  currentUser: false,
  showNip: false,
  nipPadding: false,
);

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.child,
    // ignore: unused_element
    this.padding = const EdgeInsets.all(8),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: BubblePainter(
          color: context.dynamicColor(lightOtherBubble,
              darkColor: darkOtherBubble),
          clipper: _bubbleClipper,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: child,
        ),
      );
}

class _Text extends StatelessWidget {
  const _Text(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => _MessageBubble(
        child: Text(
          text,
          style: TextStyle(
            fontSize: MessageItemWidget.primaryFontSize,
            color: context.theme.text,
          ),
        ),
      );
}

class _Image extends HookConsumerWidget {
  const _Image(this.image);

  final SendImageData image;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playing = useImagePlaying(context);

    return CacheImage(
      image.url,
      controller: playing,
      placeholder: () => ColoredBox(color: context.theme.secondaryText),
    );
  }
}

class _Sticker extends HookConsumerWidget {
  const _Sticker(this.stickerId);

  final String stickerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sticker = useMemoizedFuture(() async {
      final sticker = await context.database.stickerDao
          .sticker(stickerId)
          .getSingleOrNull();

      if (sticker != null) return sticker;

      final s = await context.accountServer.client.accountApi
          .getStickerById(stickerId);
      await context.database.stickerDao.insert(s.data.asStickersCompanion);

      return context.database.stickerDao.sticker(stickerId).getSingle();
    }, null, keys: [stickerId]).data;

    if (sticker == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(45),
      child: StickerItem(
        assetUrl: sticker.assetUrl,
        assetType: sticker.assetType,
      ),
    );
  }
}

class _Contact extends HookConsumerWidget {
  const _Contact(this.userId);

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = useMemoizedFuture(() async {
      final list = await context.accountServer.refreshUsers([userId]);
      return (list != null && list.isNotEmpty) ? list.first : null;
    }, null, keys: [userId]).data;

    if (user == null) return const SizedBox();

    return _MessageBubble(
      child: ContactItem(
        avatarUrl: user.avatarUrl,
        userId: user.userId,
        fullName: user.fullName,
        isVerified: user.isVerified,
        appId: user.appId,
        identityNumber: user.identityNumber,
      ),
    );
  }
}

class _Post extends StatelessWidget {
  const _Post(this.content);

  final String content;

  @override
  Widget build(BuildContext context) => SizedBox.expand(
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: _MessageBubble(
            child: MessagePost(
              showStatus: false,
              content: content,
            ),
          ),
        ),
      );
}

class _AppCard extends StatelessWidget {
  const _AppCard(this.data);

  final AppCardData data;

  @override
  Widget build(BuildContext context) => _MessageBubble(
        child: AppCardItem(data: data),
      );
}
