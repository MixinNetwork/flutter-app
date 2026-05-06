import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart'
    show CircleConversationRequest;

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

  Future<void> createCircle({
    required String name,
    required List<CircleConversationRequest> conversations,
  }) async {
    final context = _requireContext();
    await context.accountServer.createCircle(name, conversations);
  }

  Future<void> renameCircle({
    required String circleId,
    required String name,
  }) async {
    final context = _requireContext();
    await context.accountServer.updateCircle(circleId, name);
  }

  Future<void> deleteCircle(String circleId) async {
    final context = _requireContext();
    await context.accountServer.deleteCircle(circleId);
  }

  Future<void> addConversationsToCircle({
    required String circleId,
    required List<CircleConversationRequest> conversations,
  }) async {
    final context = _requireContext();
    await context.accountServer.editCircleConversation(circleId, conversations);
  }

  Future<void> removeConversationsFromCircle({
    required String circleId,
    required List<String> conversationIds,
  }) async {
    final context = _requireContext();
    for (final conversationId in conversationIds) {
      await context.accountServer.circleRemoveConversation(
        circleId,
        conversationId,
      );
    }
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
