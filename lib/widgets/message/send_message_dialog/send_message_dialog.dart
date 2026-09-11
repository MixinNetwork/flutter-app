import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:uuid/uuid.dart';

import '../../../crypto/uuid/uuid.dart';
import '../../../db/dao/sticker_dao.dart';
import '../../../db/mixin_database.dart';
import '../../../enum/encrypt_category.dart';
import '../../../ui/home/conversation/conversation_focus.dart';
import '../../../ui/provider/account_server_provider.dart';
import '../../../ui/provider/conversation_provider.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/hook.dart';
import '../../../utils/load_balancer_utils.dart';
import '../../../utils/logger.dart';
import '../../app_bar.dart';
import '../../auth.dart';
import '../../buttons.dart';
import '../../dialog.dart';
import '../../sticker_page/sticker_item.dart';
import '../../toast.dart';
import '../../user_selector/conversation_selector.dart';
import '../item/action_card/action_card_data.dart';
import '../item/action_card/action_message.dart';
import '../item/action_card/actions_card.dart';
import '../item/contact_message_widget.dart';
import '../item/post_message.dart';
import '../message.dart';
import '../message_bubble.dart';
import '../message_style.dart';
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
  _Category? get category => _Category.values
      .where((value) => value.name == toLowerCase())
      .firstOrNull;
}

Future<bool> showSendDialog(
  BuildContext context,
  String? category,
  String? conversationId,
  String? data,
  App? app,
  String? user, {
  bool isExplicitSendAction = false,
}) async {
  final container = context.providerContainer;
  if (container.read(appLockedProvider)) return false;
  final sendingAccount = context.accountServer;
  final currentConversation = container.read(conversationProvider);
  final _category = category?.category;
  if (_category == null || data == null || data.isEmpty) return false;

  dynamic result;
  try {
    final _data = await utf8DecodeWithIsolate(decodeBase64(data));

    switch (_category) {
      case _Category.image:
        {
          final json =
              await jsonDecodeWithIsolate(_data) as Map<String, dynamic>;
          result = SendImageData.fromJson(json);
          final url = Uri.tryParse((result as SendImageData).url);
          if (url == null ||
              !url.hasAuthority ||
              url.host.isEmpty ||
              (url.scheme != 'http' && url.scheme != 'https')) {
            return false;
          }
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
    }
  } catch (e, s) {
    w('showSendDialog error: ${e.runtimeType}, $s');
    return false;
  }

  var targetId = conversationId;
  var recipientId = user;
  String? targetName;
  EncryptCategory? encryptCategory;
  final directAction =
      isExplicitSendAction &&
      (user != null ||
          (conversationId == null &&
              _category == _Category.text &&
              currentConversation != null));
  if (recipientId == null && targetId == null && _category == _Category.text) {
    targetId = currentConversation?.conversationId;
    recipientId = currentConversation?.userId;
  }
  if (recipientId == null && targetId == null) {
    final selected = (await showConversationSelector(
      context: context,
      singleSelect: true,
      title: context.l10n.forward,
      onlyContact: false,
    ))?.firstOrNull;
    if (selected == null) return false;
    targetId = selected.conversationId;
    recipientId = selected.userId;
  }
  if (recipientId != null) {
    if (!Uuid.isValidUUID(fromString: recipientId)) return false;
    final users = await context.accountServer.refreshUsers([recipientId]);
    if (users == null || users.isEmpty) return false;
    final targetUser = users.first;
    targetName =
        '${targetUser.fullName ?? recipientId} (${targetUser.identityNumber})';
    targetId = generateConversationId(
      context.accountServer.userId,
      recipientId,
    );
    encryptCategory = await context.database.conversationDao.getEncryptCategory(
      recipientId,
      targetUser.isBot,
    );
  } else if (targetId != null) {
    final conversation = await context.database.conversationDao
        .conversationItem(targetId)
        .getSingleOrNull();
    if (conversation == null || conversation.ownerId == null) return false;
    targetName = conversation.validName;
    encryptCategory = conversation.isGroupConversation
        ? EncryptCategory.signal
        : await context.database.conversationDao.getEncryptCategory(
            conversation.ownerId!,
            conversation.isBotConversation,
          );
  }
  if (targetId == null ||
      targetName == null ||
      encryptCategory == null ||
      !context.mounted ||
      container.read(appLockedProvider)) {
    return false;
  }

  final destination = targetId;
  final encryption = encryptCategory;
  Future<void> send() async {
    if (!context.mounted ||
        container.read(appLockedProvider) ||
        !identical(
          container.read(accountServerProvider).valueOrNull,
          sendingAccount,
        )) {
      return;
    }
    await _sendMessage(
      context,
      destination,
      encryption,
      _category,
      result,
      recipientId: recipientId,
    );
  }

  if (directAction) {
    if (user != null) await ConversationFocus.selectUser(context, user);
    await send();
  } else {
    await showMixinDialog<void>(
      context: context,
      child: _SendPage(_category, result, app, targetName, send),
    );
  }
  return true;
}

class _SendPage extends HookConsumerWidget {
  const _SendPage(
    this.category,
    this.data,
    this.app,
    this.targetName,
    this.onSend,
  );

  final _Category category;
  final String targetName;
  final Future<void> Function() onSend;
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
          '${app?.name}(${app?.appNumber})',
          _category,
        );
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

    final sending = useState(false);
    Future<void> sendMessage() async {
      if (sending.value || ref.read(appLockedProvider)) return;
      sending.value = true;
      try {
        await onSend();
        if (context.mounted) Navigator.pop(context);
      } finally {
        if (context.mounted) sending.value = false;
      }
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
          Text(targetName, textAlign: TextAlign.center),
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
            padding: category == _Category.app_card
                ? null
                : const EdgeInsets.all(34),
            child: child,
          ),
          const SizedBox(height: 54),
          MixinButton(
            onTap: sending.value ? null : sendMessage,
            child: Text(context.l10n.send),
          ),
          const SizedBox(height: 56),
        ],
      ),
    );
  }
}

Future<void> _sendMessage(
  BuildContext context,
  String conversationId,
  EncryptCategory encryptCategory,
  _Category category,
  dynamic data, {
  String? recipientId,
}) async {
  if (category == _Category.text) {
    return context.accountServer.sendTextMessage(
      data as String,
      encryptCategory,
      conversationId: conversationId,
      recipientId: recipientId,
    );
  }
  if (category == _Category.post) {
    return context.accountServer.sendPostMessage(
      data as String,
      encryptCategory,
      conversationId: conversationId,
      recipientId: recipientId,
    );
  }
  if (category == _Category.sticker) {
    return context.accountServer.sendStickerMessage(
      data as String,
      null,
      encryptCategory,
      conversationId: conversationId,
      recipientId: recipientId,
    );
  }
  if (category == _Category.contact) {
    return context.accountServer.sendContactMessage(
      data as String,
      null,
      encryptCategory,
      conversationId: conversationId,
      recipientId: recipientId,
    );
  }
  if (category == _Category.app_card) {
    return context.accountServer.sendAppCardMessage(
      data: data as AppCardData,
      conversationId: conversationId,
      recipientId: recipientId,
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
        recipientId: recipientId,
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
    this.padding = const EdgeInsets.all(8),
    this.clip = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    Widget child = Padding(padding: padding, child: this.child);
    if (clip) {
      child = ClipPath(
        clipper: _bubbleClipper,
        child: RepaintBoundary(child: child),
      );
    }
    return CustomPaint(
      painter: BubblePainter(
        color: context.dynamicColor(
          lightOtherBubble,
          darkColor: darkOtherBubble,
        ),
        clipper: _bubbleClipper,
      ),
      child: child,
    );
  }
}

class _Text extends StatelessWidget {
  const _Text(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: _MessageBubble(
      child: Text(
        text,
        style: TextStyle(
          fontSize: MessageItemWidget.primaryFontSize,
          color: context.theme.text,
        ),
      ),
    ),
  );
}

class _Image extends HookConsumerWidget {
  const _Image(this.image);

  final SendImageData image;

  @override
  Widget build(BuildContext context, WidgetRef ref) => SingleChildScrollView(
    child: SelectableText(
      image.url,
      style: TextStyle(color: context.theme.text),
    ),
  );
}

class _Sticker extends HookConsumerWidget {
  const _Sticker(this.stickerId);

  final String stickerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sticker = useMemoizedFuture(
      () async {
        final sticker = await context.database.stickerDao
            .sticker(stickerId)
            .getSingleOrNull();

        if (sticker != null) return sticker;

        final s = await context.accountServer.client.accountApi.getStickerById(
          stickerId,
        );
        await context.database.stickerDao.insert(
          s.data.asStickersCompanion,
        );

        return context.database.stickerDao.sticker(stickerId).getSingle();
      },
      null,
      keys: [stickerId],
    ).data;

    if (sticker == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(45),
      child: StickerItem(
        stickerId: sticker.stickerId,
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
    final user = useMemoizedFuture(
      () async {
        final list = await context.accountServer.refreshUsers([userId]);
        return (list != null && list.isNotEmpty) ? list.first : null;
      },
      null,
      keys: [userId],
    ).data;

    if (user == null) return const SizedBox();

    return _MessageBubble(
      child: ContactItem(
        avatarUrl: user.avatarUrl,
        userId: user.userId,
        fullName: user.fullName,
        isVerified: user.isVerified ?? false,
        appId: user.appId,
        identityNumber: user.identityNumber,
        membership: user.membership,
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
          clickable: false,
        ),
      ),
    ),
  );
}

class _AppCard extends StatelessWidget {
  const _AppCard(this.data);

  final AppCardData data;

  @override
  Widget build(BuildContext context) {
    if (!data.isActionsCard) {
      return _MessageBubble(
        child: Padding(
          padding: const EdgeInsets.all(34),
          child: AppCardItem(data: data),
        ),
      );
    } else {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: _MessageBubble(
          padding: EdgeInsets.zero,
          clip: true,
          child: ActionsCardBody(
            data: data,
            description: Text(
              data.description,
              style: TextStyle(
                color: context.theme.text,
                fontSize: context.messageStyle.primaryFontSize,
              ),
            ),
          ),
        ),
      );
    }
  }
}
