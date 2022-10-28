import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../../../constants/constants.dart';
import '../../../constants/resources.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/hook.dart';
import '../../../utils/logger.dart';
import '../../../utils/uri_utils.dart';
import '../../../widgets/app_bar.dart';
import '../../../widgets/buttons.dart';
import '../../../widgets/cell.dart';
import '../../../widgets/dialog.dart';
import '../../../widgets/high_light_text.dart';
import '../../../widgets/interactive_decorated_box.dart';
import '../../../widgets/menu.dart';
import '../../../widgets/toast.dart';
import '../bloc/conversation_cubit.dart';

class DisappearMessagePage extends StatelessWidget {
  const DisappearMessagePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: context.theme.primary,
        appBar: MixinAppBar(
          title: Text(context.l10n.disappearingMessage),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 30),
              SvgPicture.asset(
                Resources.assetsImagesDisappearingMessageSvg,
                width: 70,
                height: 70,
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: HighlightStarLinkText(
                  context.l10n.disappearingMessageHint,
                  style: TextStyle(
                    color: context.theme.secondaryText,
                    height: 1.5,
                    fontSize: 14,
                  ),
                  highlightStyle: TextStyle(
                    color: context.theme.accent,
                  ),
                  links: const [mixinDisappearingMessageHelpUrl],
                  onLinkClick: (url) => openUri(context, url),
                ),
              ),
              const SizedBox(height: 40),
              const _Options(),
            ],
          ),
        ),
      );
}

class _Options extends HookWidget {
  const _Options();

  @override
  Widget build(BuildContext context) {
    final conversationId = useMemoized(() {
      final conversationId =
          context.read<ConversationCubit>().state?.conversationId;
      assert(conversationId != null);
      return conversationId!;
    });
    final conversation = useBlocState<ConversationCubit, ConversationState?>(
      when: (state) =>
          state?.isLoaded == true && state?.conversationId == conversationId,
    )!;

    final expireIn = conversation.conversation?.expireDuration ?? Duration.zero;

    return CellGroup(
      child: Column(
        children: [
          CellItem(
            title: Text(context.l10n.close),
            trailing: expireIn < const Duration(seconds: 1)
                ? SvgPicture.asset(
                    Resources.assetsImagesCheckedSvg,
                    width: 24,
                    height: 24,
                  )
                : null,
            onTap: () {
              if (expireIn < const Duration(seconds: 1)) {
                return;
              }
              _updateConversationExpireDuration(
                context,
                duration: Duration.zero,
                conversationId: conversationId,
              );
            },
          ),
          _DurationOptionItem(
            label: '30 ${context.l10n.unitSecond(30)}',
            duration: const Duration(seconds: 30),
            current: expireIn,
          ),
          _DurationOptionItem(
            label: '10 ${context.l10n.unitMinute(10)}',
            duration: const Duration(minutes: 10),
            current: expireIn,
          ),
          _DurationOptionItem(
            label: '2 ${context.l10n.unitHour(2)}',
            duration: const Duration(hours: 2),
            current: expireIn,
          ),
          _DurationOptionItem(
            label: '1 ${context.l10n.unitDay(1)}',
            duration: const Duration(days: 1),
            current: expireIn,
          ),
          _DurationOptionItem(
            label: '1 ${context.l10n.unitWeek(1)}',
            duration: const Duration(days: 7),
            current: expireIn,
          ),
          CellItem(
            title: Text(context.l10n.customTime),
            onTap: () {
              showMixinDialog(
                context: context,
                child: _CustomExpireTimeDialog(conversationId: conversationId),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DurationOptionItem extends HookWidget {
  const _DurationOptionItem({
    required this.duration,
    required this.current,
    required this.label,
  });

  final Duration duration;
  final Duration current;
  final String label;

  @override
  Widget build(BuildContext context) {
    final conversationId = useMemoized(() {
      final conversationId =
          context.read<ConversationCubit>().state?.conversationId;
      assert(conversationId != null);
      return conversationId!;
    });
    return CellItem(
      title: Text(label),
      trailing: duration == current
          ? SvgPicture.asset(
              Resources.assetsImagesCheckedSvg,
              width: 24,
              height: 24,
            )
          : null,
      onTap: () {
        if (current == duration) {
          return;
        }
        _updateConversationExpireDuration(
          context,
          duration: duration,
          conversationId: conversationId,
        );
      },
    );
  }
}

// duration: zero to turn off disappearing messages.
Future<void> _updateConversationExpireDuration(
  BuildContext context, {
  required Duration duration,
  required String conversationId,
}) async {
  final api = context.accountServer.client.conversationApi;
  try {
    final response = await api.disappear(
      conversationId,
      DisappearRequest(duration: duration.inSeconds),
    );
    await context.database.conversationDao.updateConversation(
      response.data,
      context.accountServer.userId,
    );
  } catch (error, stackTrace) {
    e('update conversation expire duration failed $error $stackTrace');
    showToastFailed(error);
  }
}

enum _CustomExpireTimeUnit { second, minute, hour, day, week }

extension _CustomExpireTimeUnitExtension on _CustomExpireTimeUnit {
  int get maxValue {
    switch (this) {
      case _CustomExpireTimeUnit.second:
        return 59;
      case _CustomExpireTimeUnit.minute:
        return 59;
      case _CustomExpireTimeUnit.hour:
        return 23;
      case _CustomExpireTimeUnit.day:
        return 6;
      case _CustomExpireTimeUnit.week:
        return 4;
    }
  }

  Duration toDuration(int value) {
    switch (this) {
      case _CustomExpireTimeUnit.second:
        return Duration(seconds: value);
      case _CustomExpireTimeUnit.minute:
        return Duration(minutes: value);
      case _CustomExpireTimeUnit.hour:
        return Duration(hours: value);
      case _CustomExpireTimeUnit.day:
        return Duration(days: value);
      case _CustomExpireTimeUnit.week:
        return Duration(days: value * 7);
    }
  }
}

class _CustomExpireTimeDialog extends HookWidget {
  const _CustomExpireTimeDialog({
    required this.conversationId,
  });

  final String conversationId;

  @override
  Widget build(BuildContext context) {
    final inputController = useTextEditingController();
    final unit = useState(_CustomExpireTimeUnit.second);
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MixinAppBar(
              leading: const SizedBox(),
              title: Text(context.l10n.customTime),
              actions: const [MixinCloseButton()],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Spacer(),
                SizedBox(
                  width: 64,
                  child: TextField(
                    controller: inputController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    textAlign: TextAlign.center,
                    maxLength: 2,
                    style: TextStyle(
                      color: context.theme.text,
                      fontSize: 16,
                    ),
                    buildCounter: (
                      BuildContext context, {
                      required int currentLength,
                      required int? maxLength,
                      required bool isFocused,
                    }) =>
                        null,
                    decoration: InputDecoration(
                      fillColor: context.theme.sidebarSelected,
                      filled: true,
                      hintStyle: TextStyle(
                        fontSize: 16,
                        color: context.theme.secondaryText,
                      ),
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide.none,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 17),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 160,
                  child: _CustomExpireUnitSelection(unit: unit),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 28),
            MixinButton(
              child: Text(context.l10n.set),
              onTap: () async {
                if (inputController.text.isEmpty) {
                  return;
                }
                final value = int.tryParse(inputController.text);
                if (value == null) {
                  return;
                }
                final duration = unit.value.toDuration(value);
                if (duration.inSeconds <= 0) {
                  return;
                }
                if (value > unit.value.maxValue) {
                  showToastFailed(
                    ToastError(context.l10n.disappearingCustomTimeMaxWarning(
                        unit.value
                            .toDuration(unit.value.maxValue)
                            .formatAsConversationExpireIn(
                                localization: context.l10n))),
                  );
                  return;
                }
                showToastLoading();
                await _updateConversationExpireDuration(context,
                    duration: duration, conversationId: conversationId);
                Toast.dismiss();
                await Navigator.of(context).maybePop();
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _CustomExpireUnitSelection extends StatelessWidget {
  const _CustomExpireUnitSelection({
    required this.unit,
  });

  final ValueNotifier<_CustomExpireTimeUnit> unit;

  @override
  Widget build(BuildContext context) {
    final String text;
    switch (unit.value) {
      case _CustomExpireTimeUnit.second:
        text = context.l10n.unitSecond(1);
        break;
      case _CustomExpireTimeUnit.minute:
        text = context.l10n.unitMinute(1);
        break;
      case _CustomExpireTimeUnit.hour:
        text = context.l10n.unitHour(1);
        break;
      case _CustomExpireTimeUnit.day:
        text = context.l10n.unitDay(1);
        break;
      case _CustomExpireTimeUnit.week:
        text = context.l10n.unitWeek(1);
        break;
    }
    return ContextMenuPortalEntry(
      buildMenus: () => [
        ContextMenu(
          title: context.l10n.unitSecond(1),
          onTap: () => unit.value = _CustomExpireTimeUnit.second,
        ),
        ContextMenu(
          title: context.l10n.unitMinute(1),
          onTap: () => unit.value = _CustomExpireTimeUnit.minute,
        ),
        ContextMenu(
          title: context.l10n.unitHour(1),
          onTap: () => unit.value = _CustomExpireTimeUnit.hour,
        ),
        ContextMenu(
          title: context.l10n.unitDay(1),
          onTap: () => unit.value = _CustomExpireTimeUnit.day,
        ),
        ContextMenu(
          title: context.l10n.unitWeek(1),
          onTap: () => unit.value = _CustomExpireTimeUnit.week,
        ),
      ],
      child: Builder(
          builder: (context) => Material(
                color: context.theme.sidebarSelected,
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                child: InteractiveDecoratedBox.color(
                  onTapUp: (details) =>
                      context.sendMenuPosition(details.globalPosition),
                  child: SizedBox(
                    height: 46,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            text,
                            style: TextStyle(
                              fontSize: 16,
                              color: context.theme.text,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        RotatedBox(
                          quarterTurns: 9,
                          child: SvgPicture.asset(
                            Resources.assetsImagesIcArrowRightSvg,
                            width: 30,
                            height: 30,
                            color: context.theme.secondaryText,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ),
              )),
    );
  }
}
