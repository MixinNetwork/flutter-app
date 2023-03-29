import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:mixin_logger/mixin_logger.dart';

import '../../constants/resources.dart';
import '../../utils/device_transfer/transfer_conversation_data.dart';
import '../../utils/device_transfer/transfer_data.dart';
import '../../utils/device_transfer/transfer_data_json_wrapper.dart';
import '../../utils/device_transfer/transfer_message_data.dart';
import '../../utils/extension/extension.dart';
import '../../utils/hook.dart';
import '../../utils/system/package_info.dart';
import '../../utils/uri_utils.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/cell.dart';

class AboutPage extends HookWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final info = useMemoizedFuture(getPackageInfo, null).data;
    return Scaffold(
      backgroundColor: context.theme.background,
      appBar: MixinAppBar(
        title: Text(context.l10n.about),
      ),
      body: SingleChildScrollView(
        child: Container(
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 40),
          child: Column(
            children: [
              Image.asset(
                Resources.assetsImagesAboutLogoPng,
                width: 60,
                height: 60,
              ),
              const SizedBox(height: 24),
              Text(
                context.l10n.mixinMessengerDesktop,
                style: TextStyle(
                  color: context.theme.text,
                  fontSize: 18,
                ),
              ),
              // SignalDatabase.get
              const SizedBox(height: 8),
              SelectableText(
                info?.versionAndBuildNumber ?? '',
                style: TextStyle(
                  color: context.theme.secondaryText,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 50),
              CellGroup(
                cellBackgroundColor: context.dynamicColor(
                  Colors.white,
                  darkColor: const Color.fromRGBO(255, 255, 255, 0.06),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CellItem(
                      title: Text(context.l10n.followUsOnTwitter),
                      onTap: () => openUri(
                          context, 'https://twitter.com/MixinMessenger'),
                    ),
                    CellItem(
                      title: Text(context.l10n.followUsOnFacebook),
                      onTap: () =>
                          openUri(context, 'https://fb.com/MixinMessenger'),
                    ),
                    CellItem(
                      title: Text(context.l10n.helpCenter),
                      onTap: () => openUri(
                          context, 'https://mixinmessenger.zendesk.com'),
                    ),
                    CellItem(
                      title: Text(context.l10n.termsOfService),
                      onTap: () =>
                          openUri(context, 'https://mixin.one/pages/terms'),
                    ),
                    CellItem(
                      title: Text(context.l10n.privacyPolicy),
                      onTap: () =>
                          openUri(context, 'https://mixin.one/pages/privacy'),
                    ),
                    CellItem(
                      title: Text(context.l10n.checkNewVersion),
                      onTap: () => openCheckUpdate(context),
                    ),
                    const _BackupItem(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void openCheckUpdate(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.linux) {
      openUri(context, 'https://mixin.one/messenger');
    } else if (defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      openUri(
          context, 'https://apps.apple.com/app/mixin-messenger/id1571128582');
    } else if (defaultTargetPlatform == TargetPlatform.windows) {
      openUri(context,
          'https://apps.microsoft.com/store/detail/mixin-desktop/9NQ6HF99B8NJ');
    }
  }
}

class _BackupItem extends HookWidget {
  const _BackupItem();

  @override
  Widget build(BuildContext context) {
    final serverSocketRef = useRef<ServerSocket?>(null);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CellItem(
          title: const Text('backup'),
          onTap: () async {
            // 创建服务器
            final serverSocket =
                await ServerSocket.bind(InternetAddress.anyIPv4, 8888);
            if (serverSocketRef.value == null) {
              serverSocketRef.value = serverSocket;
              i('server: transfer server start');
            }
            serverSocket.listen((socket) async {
              i('client connected: ${socket.remoteAddress.address}:${socket.remotePort}');

              // 监听客户端发来的消息
              socket.listen((data) async {
                i('server: message from client ${utf8.decode(data).trim()}');
              }, onError: (error) {
                i('server: error: $error');
                socket.destroy();
              }, onDone: () {
                i('server: done');
                socket.destroy();
              });

              // send conversation list
              final conversations =
                  await context.database.conversationDao.getConversations();
              for (final conversation in conversations) {
                await socket.addConversation(
                  TransferConversationData.fromDbConversation(conversation),
                );
              }

              // send messages
              for (final conversation in conversations) {
                final messages = await context.database.messageDao
                    .getMessagesByConversationId(conversation.conversationId);
                for (final message in messages) {
                  await socket
                      .addMessage(TransferMessageData.fromDbMessage(message));
                }
              }
            });
          },
        ),
        CellItem(
          title: const Text('read'),
          onTap: () async {
            const host = '192.168.98.118';
            // const host = 'localhost';
            final socket = await Socket.connect(host, 8888);
            i('client: connected to server');

            socket.transform(const TransferProtocolTransform()).listen(
                (data) async {
              if (data is TransferJsonPacket) {
                _handleJsonMessage(data.json);
              } else if (data is TransferAttachmentPacket) {
                _handleAttachmentMessage(data);
              }
            }, onError: (error) {
              i('client: error $error');
              socket.destroy();
            }, onDone: () {
              i('client: done');
              socket.destroy();
            });
          },
        ),
      ],
    );
  }
}

void _handleAttachmentMessage(TransferAttachmentPacket packet) {
  d('client: attachment: ${packet.messageId} ${packet.path}');
}

void _handleJsonMessage(TransferDataJsonWrapper data) {
  i('client: message: ${data.data}');
  return;
  switch (data.type) {
    case kTypeConversation:
      final conversation = TransferConversationData.fromJson(data.data);
      i('client: conversation: $conversation');
      break;
    case kTypeMessage:
      final message = TransferMessageData.fromJson(data.data);
      i('client: message: $message');
      break;
    default:
      throw Exception('unknown type: ${data.type}');
  }
}
