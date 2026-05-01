import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../db/database.dart';
import '../../db/mixin_database.dart';
import '../../ui/home/bloc/blink_cubit.dart';
import '../../ui/home/bloc/message_bloc.dart';
import '../../ui/provider/ai_context_attachment_provider.dart';
import '../../ui/provider/conversation_provider.dart';
import '../extension/extension.dart';

class MixinMcpBridge {
  MixinMcpBridge._();

  static final MixinMcpBridge instance = MixinMcpBridge._();

  BuildContext? _rootContext;
  String? _inputConversationId;
  TextEditingController? _inputController;

  String? get activeInputConversationId => _inputConversationId;

  set rootContext(BuildContext context) {
    _rootContext = context;
  }

  void bindInputController(
    String conversationId,
    TextEditingController controller,
  ) {
    _inputConversationId = conversationId;
    _inputController = controller;
  }

  void unbindInputController(
    String conversationId,
    TextEditingController controller,
  ) {
    if (_inputConversationId != conversationId ||
        _inputController != controller) {
      return;
    }
    _inputConversationId = null;
    _inputController = null;
  }

  Future<void> openConversation(String conversationId) async {
    final context = _requireContext();
    await ConversationStateNotifier.selectConversation(context, conversationId);
  }

  Future<void> revealMessage({
    required String conversationId,
    required String messageId,
  }) async {
    final context = _requireContext();
    await ConversationStateNotifier.selectConversation(
      context,
      conversationId,
      initIndexMessageId: messageId,
    );
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 120), () {
        try {
          context.read<MessageBloc>().scrollTo(messageId);
          context.read<BlinkCubit>().blinkByMessageId(messageId);
        } catch (_) {}
      }),
    );
  }

  Future<String> getDraft(Database database, String conversationId) async {
    final controller = _controllerFor(conversationId);
    if (controller != null) return controller.text;
    final conversation = await database.conversationDao
        .conversationItem(conversationId)
        .getSingleOrNull();
    return conversation?.draft ?? '';
  }

  Future<void> setDraft(
    Database database,
    String conversationId,
    String text,
  ) async {
    final controller = _controllerFor(conversationId);
    if (controller != null) {
      controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
    await database.conversationDao.updateDraft(conversationId, text);
  }

  Future<void> insertText(
    Database database,
    String conversationId,
    String text,
  ) async {
    final controller = _controllerFor(conversationId);
    if (controller == null) {
      final current = await getDraft(database, conversationId);
      await setDraft(database, conversationId, '$current$text');
      return;
    }
    final value = controller.value;
    final selection = value.selection;
    final start = selection.isValid ? selection.start : value.text.length;
    final end = selection.isValid ? selection.end : value.text.length;
    final next = value.text.replaceRange(start, end, text);
    final offset = start + text.length;
    controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: offset),
    );
    await database.conversationDao.updateDraft(conversationId, next);
  }

  Future<void> attachMessage({
    required String conversationId,
    required MessageItem message,
  }) async {
    final context = _requireContext();
    context.providerContainer
        .read(aiContextAttachmentProvider(conversationId).notifier)
        .attachMessages([message]);
  }

  TextEditingController? _controllerFor(String conversationId) {
    if (_inputConversationId != conversationId) return null;
    return _inputController;
  }

  BuildContext _requireContext() {
    final context = _rootContext;
    if (context == null || !context.mounted) {
      throw StateError('Mixin UI is unavailable');
    }
    return context;
  }
}
