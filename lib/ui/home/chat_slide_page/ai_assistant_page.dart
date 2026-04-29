import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:super_context_menu/super_context_menu.dart';

import '../../../ai/ai_chat_controller.dart';
import '../../../ai/model/ai_provider_config.dart';
import '../../../constants/constants.dart';
import '../../../constants/icon_fonts.dart';
import '../../../constants/resources.dart';
import '../../../db/ai_database.dart';
import '../../../db/mixin_database.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/hook.dart';
import '../../../widgets/action_button.dart';
import '../../../widgets/app_bar.dart';
import '../../../widgets/buttons.dart';
import '../../../widgets/dialog.dart';
import '../../../widgets/empty.dart';
import '../../../widgets/menu.dart';
import '../../../widgets/toast.dart';
import '../../provider/ai_context_attachment_provider.dart';
import '../../provider/ai_input_mode_provider.dart';
import '../../provider/conversation_provider.dart';
import '../bloc/blink_cubit.dart';
import '../bloc/message_bloc.dart';
import '../chat/chat_page.dart';
import 'ai_assistant/composer.dart';
import 'ai_assistant/constants.dart';
import 'ai_assistant/helpers.dart';
import 'ai_assistant/message_list.dart';

const _newAiAssistantThreadId = '';

final aiAssistantThreadIdProvider = StateProvider.autoDispose
    .family<String?, String>((ref, conversationId) => null);

class AiAssistantPage extends HookConsumerWidget {
  const AiAssistantPage(this.conversationState, {super.key});

  final ConversationState conversationState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useListenable(context.database.settingProperties);

    final conversationId = conversationState.conversationId;
    final attachedMessages = ref.watch(
      aiContextAttachmentProvider(conversationId),
    );
    final attachedMessagesNotifier = ref.read(
      aiContextAttachmentProvider(conversationId).notifier,
    );
    final aiModeState = ref.watch(aiInputModeProvider(conversationId));
    final aiModeNotifier = ref.read(
      aiInputModeProvider(conversationId).notifier,
    );
    final enabledAiProviders = context.database.settingProperties.aiProviders
        .whereType<AiProviderConfig>()
        .where((item) => item.enabled && item.model.trim().isNotEmpty)
        .toList(growable: false);
    final aiProvider = resolveAiAssistantProvider(
      selectedAiProvider: context.database.settingProperties.selectedAiProvider,
      enabledAiProviders: enabledAiProviders,
      providerId: aiModeState.providerId,
      selectedModel: aiModeState.model,
    );
    final threads =
        useMemoizedStream(
          () => context.database.aiChatMessageDao.watchThreads(conversationId),
          keys: [conversationId],
          initialData: const <AiChatThread>[],
        ).data ??
        const <AiChatThread>[];
    final activeThreadId = ref.watch(
      aiAssistantThreadIdProvider(conversationId),
    );
    final activeThreadNotifier = ref.read(
      aiAssistantThreadIdProvider(conversationId).notifier,
    );
    final isNewThreadPage =
        activeThreadId == _newAiAssistantThreadId || threads.isEmpty;
    final activeThread = threads.firstWhereOrNull(
      (item) => item.id == activeThreadId,
    );
    final fallbackThread = threads.firstOrNull;
    final currentThread = isNewThreadPage
        ? null
        : activeThread ?? fallbackThread;
    final latestMessages =
        useMemoizedStream(
          () => currentThread == null
              ? Stream.value(const <AiChatMessage>[])
              : context.database.aiChatMessageDao.watchLatestThreadMessages(
                  currentThread.id,
                  aiAssistantMessagePageLimit,
                ),
          keys: [currentThread?.id],
          initialData: const <AiChatMessage>[],
        ).data ??
        const <AiChatMessage>[];
    final requestInFlight = latestMessages.any(isActivePendingAiMessage);
    final textEditingController = useMemoized(
      TextEditingController.new,
      [conversationId],
    );
    final focusNode = useFocusNode();

    useEffect(() {
      if (!context.textFieldAutoGainFocus) {
        focusNode.unfocus();
        return null;
      }
      focusNode.requestFocus();
      return null;
    }, [conversationId]);

    Future<void> send() async {
      final text = textEditingController.text.trim();
      if (text.isEmpty) return;
      if (text.length > kMaxTextLength) {
        showToastFailed(ToastError(context.l10n.contentTooLong));
        return;
      }
      if (aiProvider == null) {
        showToastFailed(ToastError(aiAssistantUnavailable));
        return;
      }

      try {
        final threadId = await AiChatController(context.database).send(
          conversationId: conversationId,
          threadId: currentThread?.id,
          input: text,
          language: currentLanguageTag(context),
          provider: aiProvider,
          attachedMessages: attachedMessages,
          onInputAccepted: () {
            textEditingController.clear();
            attachedMessagesNotifier.clear();
          },
        );
        activeThreadNotifier.state = threadId;
      } catch (error, _) {
        showToastFailed(error);
      }
    }

    void openNewThreadPage() {
      if (isNewThreadPage) return;
      activeThreadNotifier.state = _newAiAssistantThreadId;
    }

    return Scaffold(
      backgroundColor: context.theme.primary,
      appBar: MixinAppBar(
        title: Text(_threadTitle(currentThread, threads)),
        actions: [
          _AiAssistantActions(
            addEnabled: !isNewThreadPage,
            onOpenThreads: () => context.read<ChatSideCubit>().pushPage(
              ChatSideCubit.aiAssistantThreadsPage,
            ),
            onNewThread: openNewThreadPage,
          ),
          if (!Navigator.of(context).canPop())
            MixinCloseButton(
              onTap: () => context.read<ChatSideCubit>().onPopPage(),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: AiAssistantMessageList(
              conversationId: conversationId,
              threadId: currentThread?.id,
              latestMessages: latestMessages,
            ),
          ),
          AiAssistantComposer(
            focusNode: focusNode,
            textEditingController: textEditingController,
            enabled: aiProvider != null,
            provider: aiProvider,
            attachedMessages: attachedMessages,
            enabledAiProviders: enabledAiProviders,
            requestInFlight: requestInFlight,
            onSend: send,
            onStop: () => AiChatController(
              context.database,
            ).stop(conversationId, threadId: currentThread?.id),
            onTapAttachment: (message) =>
                _jumpToAttachedMessage(context, message),
            onRemoveAttachment: attachedMessagesNotifier.remove,
            onProviderSelected: (value) => aiModeNotifier.updateProvider(
              providerId: value.id,
              model: value.model,
            ),
            onModelSelected: aiModeNotifier.updateModel,
          ),
        ],
      ),
    );
  }
}

void _jumpToAttachedMessage(BuildContext context, MessageItem message) {
  context.read<MessageBloc>().scrollTo(message.messageId);
  context.read<BlinkCubit>().blinkByMessageId(message.messageId);

  final chatSideCubit = context.read<ChatSideCubit>();
  if (chatSideCubit.state.routeMode) {
    chatSideCubit.pop();
  }
}

class AiAssistantThreadsPage extends HookConsumerWidget {
  const AiAssistantThreadsPage(this.conversationState, {super.key});

  final ConversationState conversationState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationId = conversationState.conversationId;
    final threads =
        useMemoizedStream(
          () => context.database.aiChatMessageDao.watchThreads(conversationId),
          keys: [conversationId],
          initialData: const <AiChatThread>[],
        ).data ??
        const <AiChatThread>[];
    final activeThreadId = ref.watch(
      aiAssistantThreadIdProvider(conversationId),
    );
    final activeThreadNotifier = ref.read(
      aiAssistantThreadIdProvider(conversationId).notifier,
    );
    final hasSelectedThread = threads.any((item) => item.id == activeThreadId);

    return Scaffold(
      backgroundColor: context.theme.primary,
      appBar: MixinAppBar(
        title: const Text(aiAssistantThreads),
        actions: [
          if (!Navigator.of(context).canPop())
            MixinCloseButton(
              onTap: () => context.read<ChatSideCubit>().onPopPage(),
            ),
        ],
      ),
      body: threads.isEmpty
          ? const Empty(text: aiAssistantEmpty)
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 20),
              itemBuilder: (context, index) {
                final thread = threads[index];
                final selected =
                    activeThreadId == thread.id ||
                    ((activeThreadId == null || !hasSelectedThread) &&
                        index == 0);
                return _AiAssistantThreadTile(
                  thread: thread,
                  title: _threadTitle(thread, threads),
                  selected: selected,
                  onDelete: () async {
                    final result = await showConfirmMixinDialog(
                      context,
                      aiAssistantDeleteThread,
                      description: aiAssistantDeleteThreadDescription,
                    );
                    if (result != DialogEvent.positive) return;
                    await context.database.aiChatMessageDao.deleteThread(
                      thread.id,
                    );
                    if (activeThreadId == thread.id) {
                      activeThreadNotifier.state = null;
                    }
                  },
                  onTap: () {
                    activeThreadNotifier.state = thread.id;
                    context.read<ChatSideCubit>().pop();
                  },
                );
              },
              separatorBuilder: (context, index) => const SizedBox(height: 6),
              itemCount: threads.length,
            ),
    );
  }
}

class _AiAssistantActions extends StatelessWidget {
  const _AiAssistantActions({
    required this.addEnabled,
    required this.onOpenThreads,
    required this.onNewThread,
  });

  final bool addEnabled;
  final VoidCallback onOpenThreads;
  final VoidCallback onNewThread;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      ActionButton(
        onTap: onOpenThreads,
        child: Icon(Icons.history_rounded, color: context.theme.icon, size: 22),
      ),
      ActionButton(
        name: Resources.assetsImagesIcAddSvg,
        color: addEnabled ? context.theme.icon : context.theme.secondaryText,
        interactive: addEnabled,
        onTap: onNewThread,
      ),
    ],
  );
}

class _AiAssistantThreadTile extends StatelessWidget {
  const _AiAssistantThreadTile({
    required this.thread,
    required this.title,
    required this.selected,
    required this.onTap,
    required this.onDelete,
  });

  final AiChatThread thread;
  final String title;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final preview = thread.lastMessagePreview?.trim();
    final backgroundColor = selected
        ? context.dynamicColor(
            const Color.fromRGBO(0, 0, 0, 0.06),
            darkColor: const Color.fromRGBO(255, 255, 255, 0.08),
          )
        : Colors.transparent;

    return CustomContextMenuWidget(
      desktopMenuWidgetBuilder: CustomDesktopMenuWidgetBuilder(),
      menuProvider: (_) => MenusWithSeparator(
        childrens: [
          [
            MenuAction(
              attributes: const MenuActionAttributes(destructive: true),
              image: MenuImage.icon(IconFonts.delete),
              title: aiAssistantDeleteThread,
              callback: onDelete,
            ),
          ],
        ],
      ),
      child: Material(
        color: backgroundColor,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.theme.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        preview?.isNotEmpty == true
                            ? preview!
                            : aiAssistantEmpty,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.theme.secondaryText,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${thread.messageCount}',
                  style: TextStyle(
                    color: context.theme.secondaryText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _threadTitle(AiChatThread? thread, List<AiChatThread> threads) {
  if (thread == null) {
    return aiAssistantNewThread;
  }
  final title = thread.title?.trim();
  if (title != null && title.isNotEmpty) {
    return title;
  }
  final index = threads.indexWhere((item) => item.id == thread.id);
  return index < 0 ? aiAssistantUntitledThread : 'Chat ${index + 1}';
}
