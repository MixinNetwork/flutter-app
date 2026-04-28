import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../utils/extension/extension.dart';
import '../../../widgets/action_button.dart';
import '../../../widgets/interactive_decorated_box.dart';
import '../../../widgets/menu.dart';

enum AiDraftAction {
  polish,
  shorten,
  polite,
  translate,
  replyWithContext,
}

enum AiDraftAssistPhase { idle, loading, result, error }

class AiDraftAssistViewState {
  const AiDraftAssistViewState({
    this.phase = AiDraftAssistPhase.idle,
    this.action,
    this.original = '',
    this.result,
    this.error,
  });

  final AiDraftAssistPhase phase;
  final AiDraftAction? action;
  final String original;
  final String? result;
  final String? error;

  bool get isIdle => phase == AiDraftAssistPhase.idle;
  bool get isLoading => phase == AiDraftAssistPhase.loading;
  static const idle = AiDraftAssistViewState();
}

class AiDraftAssistButton extends HookConsumerWidget {
  const AiDraftAssistButton({
    required this.enabled,
    required this.textEditingController,
    required this.viewState,
    required this.onSelected,
    required this.onStop,
    super.key,
  });

  final bool enabled;
  final TextEditingController textEditingController;
  final AiDraftAssistViewState viewState;
  final ValueChanged<AiDraftAction> onSelected;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draftValue = useValueListenable(textEditingController);
    final hasDraft = draftValue.text.trim().isNotEmpty;
    final visible = useState(false);
    final hovering = useState(false);

    void closePanel() {
      visible.value = false;
    }

    useEffect(() {
      if (viewState.phase != AiDraftAssistPhase.idle) {
        visible.value = false;
      }
      return null;
    }, [viewState.phase]);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: enabled ? 1 : 0.45,
      child: Barrier(
        visible: enabled && visible.value,
        onClose: closePanel,
        duration: const Duration(milliseconds: 160),
        child: PortalTarget(
          visible: enabled && visible.value,
          closeDuration: const Duration(milliseconds: 160),
          anchor: const Aligned(
            follower: Alignment.bottomRight,
            target: Alignment.topRight,
          ),
          portalFollower: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            tween: Tween(begin: 0, end: visible.value ? 1 : 0),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _AiDraftAssistActionPanel(
                hasDraft: hasDraft,
                onSelected: (action) {
                  closePanel();
                  onSelected(action);
                },
              ),
            ),
            builder: (context, progress, child) => Opacity(
              opacity: progress,
              child: Transform.translate(
                offset: Offset(0, 8 * (1 - progress)),
                child: child,
              ),
            ),
          ),
          child: IgnorePointer(
            ignoring: !enabled,
            child: MouseRegion(
              onEnter: (_) => hovering.value = true,
              onExit: (_) => hovering.value = false,
              child: ActionButton(
                onTap: () {
                  if (viewState.isLoading) {
                    onStop();
                    return;
                  }
                  if (visible.value) {
                    closePanel();
                    return;
                  }
                  visible.value = true;
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  ),
                  child: _AiDraftAssistButtonIcon(
                    key: ValueKey('${viewState.phase}-${hovering.value}'),
                    viewState: viewState,
                    hovering: hovering.value,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AiDraftAssistButtonIcon extends StatelessWidget {
  const _AiDraftAssistButtonIcon({
    required this.viewState,
    required this.hovering,
    super.key,
  });

  final AiDraftAssistViewState viewState;
  final bool hovering;

  @override
  Widget build(BuildContext context) {
    if (viewState.isLoading) {
      if (hovering) {
        return Icon(
          Icons.stop_rounded,
          size: 18,
          color: context.theme.red,
        );
      }
      return SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: context.theme.accent,
        ),
      );
    }
    if (viewState.phase == AiDraftAssistPhase.result) {
      return Icon(
        Icons.auto_awesome_rounded,
        size: 20,
        color: context.theme.accent,
      );
    }
    if (viewState.phase == AiDraftAssistPhase.error) {
      return Icon(
        Icons.error_outline_rounded,
        size: 20,
        color: context.theme.red,
      );
    }
    return Icon(
      Icons.auto_awesome_rounded,
      size: 20,
      color: context.theme.icon,
    );
  }
}

class _AiDraftAssistActionPanel extends StatelessWidget {
  const _AiDraftAssistActionPanel({
    required this.hasDraft,
    required this.onSelected,
  });

  final bool hasDraft;
  final ValueChanged<AiDraftAction> onSelected;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 320),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: context.theme.popUp,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.12),
            offset: Offset(0, 8),
            blurRadius: 28,
          ),
        ],
        border: Border.all(
          color: context.dynamicColor(
            const Color.fromRGBO(0, 0, 0, 0.05),
            darkColor: const Color.fromRGBO(255, 255, 255, 0.06),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AiDraftAssistGroup(
              title: 'Draft',
              children: [
                _AiDraftAssistActionTile(
                  title: 'Polish',
                  subtitle: 'Clearer and more natural',
                  icon: Icons.auto_fix_high_rounded,
                  enabled: hasDraft,
                  onTap: () => onSelected(AiDraftAction.polish),
                ),
                _AiDraftAssistActionTile(
                  title: 'Make shorter',
                  subtitle: 'Cut extra words',
                  icon: Icons.short_text_rounded,
                  enabled: hasDraft,
                  onTap: () => onSelected(AiDraftAction.shorten),
                ),
                _AiDraftAssistActionTile(
                  title: 'Make polite',
                  subtitle: 'Softer tone',
                  icon: Icons.favorite_border_rounded,
                  enabled: hasDraft,
                  onTap: () => onSelected(AiDraftAction.polite),
                ),
                _AiDraftAssistActionTile(
                  title: 'Translate draft',
                  subtitle: 'Translate current input',
                  icon: Icons.translate_rounded,
                  enabled: hasDraft,
                  onTap: () => onSelected(AiDraftAction.translate),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _AiDraftAssistGroup(
              title: 'Conversation',
              children: [
                _AiDraftAssistActionTile(
                  title: 'Reply with context',
                  subtitle: 'Generate from recent messages',
                  icon: Icons.reply_rounded,
                  enabled: true,
                  onTap: () => onSelected(AiDraftAction.replyWithContext),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class AiDraftAssistInlineCandidate extends StatelessWidget {
  const AiDraftAssistInlineCandidate({
    required this.viewState,
    required this.onDismiss,
    required this.onCopy,
    required this.onAppend,
    required this.onReplace,
    super.key,
  });

  final AiDraftAssistViewState viewState;
  final VoidCallback onDismiss;
  final VoidCallback onCopy;
  final VoidCallback onAppend;
  final VoidCallback onReplace;

  @override
  Widget build(BuildContext context) {
    if (viewState.isIdle || viewState.phase == AiDraftAssistPhase.loading) {
      return const SizedBox.shrink();
    }

    final accent = context.theme.accent;
    final background = context.dynamicColor(
      const Color.fromRGBO(245, 247, 250, 1),
      darkColor: const Color.fromRGBO(255, 255, 255, 0.08),
    );
    final border = context.dynamicColor(
      accent.withValues(alpha: 0.22),
      darkColor: accent.withValues(alpha: 0.28),
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: Container(
        key: ValueKey(
          '${viewState.phase}-${viewState.result}-${viewState.error}',
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          border: Border.all(color: border),
        ),
        child: switch (viewState.phase) {
          AiDraftAssistPhase.result => _AiDraftAssistInlineResult(
            action: viewState.action,
            result: viewState.result ?? '',
            onDismiss: onDismiss,
            onCopy: onCopy,
            onAppend: onAppend,
            onReplace: onReplace,
          ),
          AiDraftAssistPhase.error => _AiDraftAssistInlineError(
            error: viewState.error ?? 'Unknown error',
            onDismiss: onDismiss,
          ),
          AiDraftAssistPhase.loading ||
          AiDraftAssistPhase.idle => const SizedBox.shrink(),
        },
      ),
    );
  }
}

class _AiDraftAssistInlineResult extends StatelessWidget {
  const _AiDraftAssistInlineResult({
    required this.action,
    required this.result,
    required this.onDismiss,
    required this.onCopy,
    required this.onAppend,
    required this.onReplace,
  });

  final AiDraftAction? action;
  final String result;
  final VoidCallback onDismiss;
  final VoidCallback onCopy;
  final VoidCallback onAppend;
  final VoidCallback onReplace;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              aiDraftActionTitle(action ?? AiDraftAction.polish),
              style: TextStyle(
                color: context.theme.text,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _AiDraftInlineIconButton(
            icon: Icons.close_rounded,
            color: context.theme.secondaryText,
            onTap: onDismiss,
          ),
        ],
      ),
      const SizedBox(height: 8),
      ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 160),
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: true),
          child: SingleChildScrollView(
            child: SelectableText(
              result,
              style: TextStyle(
                color: context.theme.text,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _AiDraftInlineTextButton(
            title: 'Copy',
            onTap: onCopy,
            secondary: true,
          ),
          _AiDraftInlineTextButton(
            title: 'Append',
            onTap: onAppend,
            secondary: true,
          ),
          _AiDraftInlineTextButton(
            title: 'Replace Draft',
            onTap: onReplace,
          ),
        ],
      ),
    ],
  );
}

class _AiDraftAssistInlineError extends StatelessWidget {
  const _AiDraftAssistInlineError({
    required this.error,
    required this.onDismiss,
  });

  final String error;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(
        Icons.error_outline_rounded,
        size: 16,
        color: context.theme.red,
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          error,
          style: TextStyle(
            color: context.theme.red,
            fontSize: 12,
            height: 1.35,
          ),
        ),
      ),
      _AiDraftInlineIconButton(
        icon: Icons.close_rounded,
        color: context.theme.secondaryText,
        onTap: onDismiss,
      ),
    ],
  );
}

class _AiDraftAssistGroup extends StatelessWidget {
  const _AiDraftAssistGroup({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(
          color: context.theme.secondaryText,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 8),
      ...children.expand((child) => [child, const SizedBox(height: 8)]).toList()
        ..removeLast(),
    ],
  );
}

class _AiDraftAssistActionTile extends StatelessWidget {
  const _AiDraftAssistActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = context.dynamicColor(
      const Color.fromRGBO(245, 247, 250, 1),
      darkColor: const Color.fromRGBO(255, 255, 255, 0.06),
    );
    final accentColor = context.theme.accent;
    final iconColor = enabled ? accentColor : context.theme.secondaryText;

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: IgnorePointer(
        ignoring: !enabled,
        child: InteractiveDecoratedBox.color(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            border: Border.all(
              color: context.dynamicColor(
                const Color.fromRGBO(0, 0, 0, 0.04),
                darkColor: const Color.fromRGBO(255, 255, 255, 0.05),
              ),
            ),
          ),
          hoveringColor: accentColor.withValues(alpha: 0.08),
          tapDowningColor: accentColor.withValues(alpha: 0.12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 16, color: iconColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: context.theme.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: context.theme.secondaryText,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
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

class _AiDraftInlineIconButton extends StatelessWidget {
  const _AiDraftInlineIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ActionButton(
    size: 16,
    padding: const EdgeInsets.all(4),
    onTap: onTap,
    child: Icon(icon, size: 16, color: color),
  );
}

class _AiDraftInlineTextButton extends StatelessWidget {
  const _AiDraftInlineTextButton({
    required this.title,
    required this.onTap,
    this.secondary = false,
  });

  final String title;
  final VoidCallback onTap;
  final bool secondary;

  @override
  Widget build(BuildContext context) => InteractiveDecoratedBox.color(
    decoration: BoxDecoration(
      color: secondary
          ? context.dynamicColor(
              const Color.fromRGBO(245, 247, 250, 1),
              darkColor: const Color.fromRGBO(255, 255, 255, 0.06),
            )
          : context.theme.accent,
      borderRadius: const BorderRadius.all(Radius.circular(8)),
    ),
    hoveringColor: secondary
        ? context.dynamicColor(
            const Color.fromRGBO(235, 238, 242, 1),
            darkColor: const Color.fromRGBO(255, 255, 255, 0.1),
          )
        : context.theme.accent.withValues(alpha: 0.88),
    tapDowningColor: secondary
        ? context.dynamicColor(
            const Color.fromRGBO(225, 229, 235, 1),
            darkColor: const Color.fromRGBO(255, 255, 255, 0.12),
          )
        : context.theme.accent.withValues(alpha: 0.8),
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          color: secondary
              ? context.theme.text
              : context.dynamicColor(const Color.fromRGBO(255, 255, 255, 1)),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

void applyAiDraftAssistResult(
  TextEditingController controller,
  String text, {
  required bool replace,
}) {
  if (replace) {
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    return;
  }

  final current = controller.text;
  final separator = current.trim().isEmpty ? '' : '\n';
  final next = '$current$separator$text';
  controller.value = TextEditingValue(
    text: next,
    selection: TextSelection.collapsed(offset: next.length),
  );
}

String aiDraftActionTitle(AiDraftAction action) => switch (action) {
  AiDraftAction.polish => 'Polish',
  AiDraftAction.shorten => 'Make shorter',
  AiDraftAction.polite => 'Make polite',
  AiDraftAction.translate => 'Translate draft',
  AiDraftAction.replyWithContext => 'Reply with context',
};
