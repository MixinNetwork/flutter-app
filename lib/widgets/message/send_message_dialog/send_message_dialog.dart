import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:uuid/uuid.dart';

import '../../../crypto/uuid/uuid.dart';
import '../../../db/dao/sticker_dao.dart';
import '../../../db/mixin_database.dart';
import '../../../enum/encrypt_category.dart';
import '../../../ui/provider/account_server_provider.dart';
import '../../../ui/provider/conversation_provider.dart';
import '../../../ui/provider/database_provider.dart';
import '../../../ui/provider/ui_context_providers.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/hook.dart';
import '../../../utils/load_balancer_utils.dart';
import '../../../utils/logger.dart';
import '../../app_bar.dart';
import '../../buttons.dart';
import '../../dialog.dart';
import '../../mixin_image.dart';
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
  _Category? get category => _Category.values.byName(toLowerCase());
}

Future<bool> showSendDialog(
  BuildContext context,
  String? category,
  String? conversationId,
  String? data,
  App? app,
  String? user,
  ProviderContainer container,
) async {
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
    w('showSendDialog error: $e, $s');
    return false;
  }

  if (user != null) {
    return _sendMessageToUserId(context, user, _category, result, container);
  }
  if (conversationId == null) {
    final currentConversation = container.read(conversationProvider);
    if (currentConversation != null) {
      await _sendMessage(
        container,
        currentConversation.conversationId,
        currentConversation.encryptCategory,
        _category,
        result,
      );
      return true;
    }
  }

  await showMixinDialog(
    context: context,
    child: _SendPage(_category, conversationId, result, app),
  );

  return true;
}

Future<bool> _sendMessageToUserId(
  BuildContext context,
  String userId,
  _Category category,
  dynamic data,
  ProviderContainer container,
) async {
  final accountServer = container.read(accountServerProvider).requireValue;
  if (!Uuid.isValidUUID(fromString: userId)) {
    return false;
  }

  showToastLoading();
  try {
    final users = await accountServer.refreshUsers([userId]);
    if (users == null || users.isEmpty) {
      return false;
    }
  } finally {
    Toast.dismiss();
  }

  final conversationId = generateConversationId(
    accountServer.userId,
    userId,
  );
  await ConversationStateNotifier.selectUser(container, context, userId);
  final conversation = container.read(conversationProvider);
  if (conversation == null) {
    return false;
  }
  await _sendMessage(
    container,
    conversationId,
    conversation.encryptCategory,
    category,
    data,
    recipientId: userId,
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
    final database = ref.read(databaseProvider).requireValue;
    final theme = ref.watch(brightnessThemeDataProvider);
    final l10n = ref.watch(localizationProvider);
    final dynamicSurface = ref.watch(
      dynamicColorProvider(
        const (
          color: Color.fromRGBO(245, 247, 250, 1),
          darkColor: Color.fromRGBO(255, 255, 255, 0.08),
        ),
      ),
    );
    final title = useMemoized(() {
      String _category;
      switch (category) {
        case _Category.text:
          _category = l10n.text;
        case _Category.image:
          _category = l10n.image;
        case _Category.sticker:
          _category = l10n.sticker;
        case _Category.contact:
          _category = l10n.contact;
        case _Category.post:
          _category = l10n.post;
        case _Category.app_card:
          _category = l10n.card;
      }
      if (app != null) {
        return l10n.shareMessageDescription(
          '${app?.name}(${app?.appNumber})',
          _category,
        );
      }
      return l10n.shareMessageDescriptionEmpty(_category);
    }, [category, app, l10n]);

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
          title: l10n.forward,
          onlyContact: false,
        );
        _conversationId = result?.firstOrNull?.conversationId;
        encryptCategory = result?.firstOrNull?.encryptCategory;
      }
      if (encryptCategory == null && _conversationId != null) {
        final conversation = await database.conversationDao
            .conversationItem(_conversationId)
            .getSingleOrNull();
        final ownerId = conversation?.ownerId;
        final isBotConversation = conversation?.isBotConversation;
        if (ownerId == null || isBotConversation == null) return;
        encryptCategory = await database.conversationDao.getEncryptCategory(
          ownerId,
          isBotConversation,
        );
      }

      if (_conversationId == null || encryptCategory == null) return;

      await _sendMessage(
        ref.container,
        _conversationId,
        encryptCategory,
        category,
        data,
      );
      Navigator.pop(context);
    }

    return MessageStyleScope(
      child: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MixinAppBar(
              title: Text(title),
              actions: const [MixinCloseButton()],
              leading: const SizedBox(),
              backgroundColor: theme.popUp,
            ),
            const SizedBox(height: 12),
            Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                color: dynamicSurface,
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
              onTap: sendMessage,
              child: Text(
                (conversationId != null) ? l10n.send : l10n.forward,
              ),
            ),
            const SizedBox(height: 56),
          ],
        ),
      ),
    );
  }
}

Future<void> _sendMessage(
  ProviderContainer container,
  String conversationId,
  EncryptCategory encryptCategory,
  _Category category,
  dynamic data, {
  String? recipientId,
}) async {
  final accountServer = container.read(accountServerProvider).requireValue;
  if (category == _Category.text) {
    return accountServer.sendTextMessage(
      data as String,
      encryptCategory,
      conversationId: conversationId,
      recipientId: recipientId,
    );
  }
  if (category == _Category.post) {
    return accountServer.sendPostMessage(
      data as String,
      encryptCategory,
      conversationId: conversationId,
      recipientId: recipientId,
    );
  }
  if (category == _Category.sticker) {
    return accountServer.sendStickerMessage(
      data as String,
      null,
      encryptCategory,
      conversationId: conversationId,
      recipientId: recipientId,
    );
  }
  if (category == _Category.contact) {
    return accountServer.sendContactMessage(
      data as String,
      null,
      encryptCategory,
      conversationId: conversationId,
      recipientId: recipientId,
    );
  }
  if (category == _Category.app_card) {
    return accountServer.sendAppCardMessage(
      data: data as AppCardData,
      conversationId: conversationId,
      recipientId: recipientId,
    );
  }
  if (category == _Category.image) {
    final sendImageData = data as SendImageData;
    await runWithLoading(
      () => accountServer.sendImageMessageByUrl(
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

class _MessageBubble extends ConsumerWidget {
  const _MessageBubble({
    required this.child,
    this.padding = const EdgeInsets.all(8),
    this.clip = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool clip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget child = Padding(padding: padding, child: this.child);
    if (clip) {
      child = ClipPath(
        clipper: _bubbleClipper,
        child: RepaintBoundary(child: child),
      );
    }
    return CustomPaint(
      painter: BubblePainter(
        color: ref.watch(
          dynamicColorProvider((
            color: lightOtherBubble,
            darkColor: darkOtherBubble,
          )),
        ),
        clipper: _bubbleClipper,
      ),
      child: child,
    );
  }
}

class _Text extends ConsumerWidget {
  const _Text(this.text);

  final String text;

  @override
  Widget build(BuildContext context, WidgetRef ref) => _MessageBubble(
    child: Text(
      text,
      style: TextStyle(
        fontSize: MessageItemWidget.primaryFontSize,
        color: ref.watch(brightnessThemeDataProvider).text,
      ),
    ),
  );
}

class _Image extends HookConsumerWidget {
  const _Image(this.image);

  final SendImageData image;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    return MixinImage.network(
      image.url,
      placeholder: () => ColoredBox(color: theme.secondaryText),
    );
  }
}

class _Sticker extends HookConsumerWidget {
  const _Sticker(this.stickerId);

  final String stickerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountServer = ref.read(accountServerProvider).requireValue;
    final database = ref.read(databaseProvider).requireValue;
    final sticker = useMemoizedFuture(
      () async {
        final sticker = await database.stickerDao
            .sticker(stickerId)
            .getSingleOrNull();

        if (sticker != null) return sticker;

        final s = await accountServer.client.accountApi.getStickerById(
          stickerId,
        );
        await accountServer.upsertSticker(s.data.asStickersCompanion);

        return database.stickerDao.sticker(stickerId).getSingle();
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
    final accountServer = ref.read(accountServerProvider).requireValue;
    final user = useMemoizedFuture(
      () async {
        final list = await accountServer.refreshUsers([userId]);
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
        child: MessagePost(showStatus: false, content: content),
      ),
    ),
  );
}

class _AppCard extends ConsumerWidget {
  const _AppCard(this.data);

  final AppCardData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                color: ref.watch(brightnessThemeDataProvider).text,
                fontSize: context.messageStyle.primaryFontSize,
              ),
            ),
          ),
        ),
      );
    }
  }
}
