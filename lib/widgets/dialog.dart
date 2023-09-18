import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../utils/extension/extension.dart';
import '../utils/hook.dart';
import '../utils/system/text_input.dart';
import 'disable.dart';
import 'interactive_decorated_box.dart';

Future<T?> _showDialog<T>({
  required BuildContext context,
  bool barrierDismissible = true,
  Color barrierColor = const Color(0x80000000),
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  required RoutePageBuilder pageBuilder,
}) =>
    showGeneralDialog<T>(
      context: context,
      pageBuilder: (BuildContext buildContext, Animation<double> animation,
              Animation<double> secondaryAnimation) =>
          InheritedTheme.capture(
                  from: context,
                  to: Navigator.of(context, rootNavigator: useRootNavigator)
                      .context)
              .wrap(
        Builder(
          builder: (context) =>
              pageBuilder(context, animation, secondaryAnimation),
        ),
      ),
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: barrierColor,
      transitionDuration: const Duration(milliseconds: 80),
      useRootNavigator: useRootNavigator,
      routeSettings: routeSettings,
    );

Future<T?> showMixinDialog<T>({
  required BuildContext context,
  RouteSettings? routeSettings,
  required Widget child,
  EdgeInsets? padding = const EdgeInsets.all(32),
  BoxConstraints? constraints = const BoxConstraints(
    maxWidth: 600,
  ),
  Color? backgroundColor,
  bool barrierDismissible = true,
}) =>
    _showDialog<T>(
      barrierDismissible: barrierDismissible,
      context: context,
      routeSettings: routeSettings,
      pageBuilder: (BuildContext buildContext, Animation<double> animation,
              Animation<double> secondaryAnimation) =>
          InheritedTheme.capture(
                  from: context,
                  to: Navigator.of(context, rootNavigator: true).context)
              .wrap(
        Center(
          child: _DialogPage(
            padding: padding,
            constraints: constraints,
            backgroundColor: backgroundColor,
            child: child,
          ),
        ),
      ),
    );

class AlertDialogLayout extends StatelessWidget {
  const AlertDialogLayout({
    super.key,
    this.title,
    this.titleMarginBottom = 48,
    required this.content,
    this.actions = const [],
    this.minWidth = 400,
    this.minHeight = 210,
    this.padding = const EdgeInsets.all(30),
    this.maxWidth,
  });

  final Widget? title;
  final double titleMarginBottom;
  final Widget content;
  final List<Widget> actions;
  final double minWidth;
  final double minHeight;
  final EdgeInsetsGeometry padding;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: minWidth,
            minHeight: minHeight,
            maxWidth: maxWidth ?? double.infinity,
          ),
          child: Padding(
            padding: padding,
            child: IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (title != null)
                    DefaultTextStyle.merge(
                      style: TextStyle(
                        fontSize: 16,
                        color: context.theme.text,
                      ),
                      child: title!,
                    ),
                  if (title != null) SizedBox(height: titleMarginBottom),
                  DefaultTextStyle.merge(
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: context.theme.text,
                    ),
                    child: content,
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: actions.joinList(const SizedBox(width: 4)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _DialogPage extends StatelessWidget {
  const _DialogPage({
    required this.child,
    this.padding,
    this.constraints,
    this.backgroundColor,
  });

  final Widget child;
  final EdgeInsets? padding;
  final BoxConstraints? constraints;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final effectivePadding =
        MediaQuery.viewInsetsOf(context) + (padding ?? EdgeInsets.zero);
    return Padding(
      padding: effectivePadding,
      child: ConstrainedBox(
        constraints: constraints ?? const BoxConstraints(),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(11)),
            boxShadow: [
              const BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.15),
                offset: Offset(0, 8),
                blurRadius: 40,
              ),
              BoxShadow(
                color: const Color.fromRGBO(0, 0, 0, 0.07),
                offset: const Offset(0, 4),
                blurRadius: lerpDouble(16, 6, context.brightnessValue)!,
              ),
            ],
          ),
          child: Material(
            color: backgroundColor ?? context.theme.popUp,
            borderRadius: const BorderRadius.all(Radius.circular(11)),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// default onTap is Navigator.pop
abstract class DialogInteracterEntry<T> extends StatelessWidget {
  const DialogInteracterEntry({
    super.key,
    this.value,
  });

  final T? value;

  void handleTap(BuildContext context) => Navigator.pop<T>(context, value);
}

/// default onTap is Navigator.pop
class MixinButton<T> extends DialogInteracterEntry<T> {
  const MixinButton({
    super.key,
    super.value,
    this.backgroundTransparent = false,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(
      vertical: 8,
      horizontal: 16,
    ),
    this.disable = false,
    this.backgroundColor,
  });

  final bool backgroundTransparent;
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final bool disable;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final boxDecoration = backgroundTransparent
        ? const BoxDecoration()
        : BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(5)),
            color: backgroundColor ?? context.theme.accent,
          );
    final textColor = backgroundTransparent
        ? context.theme.accent
        : context.dynamicColor(
            const Color.fromRGBO(255, 255, 255, 1),
          );
    return Disable(
      disable: disable,
      child: InteractiveDecoratedBox.color(
        decoration: boxDecoration,
        onTap: () => onTap != null ? onTap?.call() : handleTap(context),
        child: DefaultTextStyle.merge(
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: textColor,
          ),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

class DialogTextField extends HookConsumerWidget {
  const DialogTextField({
    super.key,
    required this.textEditingController,
    required this.hintText,
    this.inputFormatters,
    this.maxLines = 1,
    this.maxLength,
  });

  final TextEditingController textEditingController;
  final String hintText;
  final List<TextInputFormatter>? inputFormatters;

  final int? maxLines;
  final int? maxLength;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textStream = useValueNotifierConvertSteam(textEditingController);
    final hasText = useMemoizedStream(
          () => textStream.map((event) => event.text.isNotEmpty).distinct(),
        ).data ??
        textEditingController.text.isNotEmpty;
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: context.theme.background,
        borderRadius: const BorderRadius.all(Radius.circular(5)),
      ),
      alignment: Alignment.center,
      child: Stack(
        children: [
          TextField(
            autofocus: true,
            controller: textEditingController,
            style: TextStyle(
              color: context.theme.text,
            ),
            maxLines: maxLines ?? 1,
            minLines: 1,
            maxLength: maxLength,
            scrollPadding: EdgeInsets.zero,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.zero,
              isDense: true,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              counterStyle: TextStyle(
                fontSize: 14,
                color: context.theme.secondaryText,
              ),
            ),
            inputFormatters: inputFormatters,
            selectionHeightStyle: BoxHeightStyle.includeLineSpacingMiddle,
          ),
          if (hintText.isNotEmpty && !hasText)
            IgnorePointer(
              child: Text(
                hintText,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.08),
                  height: 1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}

enum DialogEvent {
  positive,
  neutral,
}

Future<DialogEvent?> showConfirmMixinDialog(
  BuildContext context,
  String content, {
  String? description,
  double? maxWidth,
  bool barrierDismissible = true,
  String? positiveText,
  String? negativeText,
  String? neutralText,
}) =>
    showMixinDialog<DialogEvent>(
      context: context,
      barrierDismissible: barrierDismissible,
      child: Builder(
        builder: (context) => AlertDialogLayout(
          maxWidth: maxWidth,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(content),
              if (description != null)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    description,
                    style: TextStyle(
                      color: context.theme.text,
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            if (neutralText != null) ...[
              MixinButton(
                onTap: () => Navigator.pop(context, DialogEvent.neutral),
                child: Text(neutralText),
              ),
              const Spacer(),
            ],
            MixinButton(
              backgroundTransparent: true,
              onTap: () => Navigator.pop(context, null),
              child: Text(negativeText ?? context.l10n.cancel),
            ),
            MixinButton(
              onTap: () => Navigator.pop(context, DialogEvent.positive),
              child: Text(positiveText ?? context.l10n.confirm),
            ),
          ],
        ),
      ),
    );

class EditDialog extends HookConsumerWidget {
  const EditDialog({
    super.key,
    required this.title,
    this.editText = '',
    this.hintText = '',
    this.positiveAction,
    this.maxLines,
    this.maxLength,
  });

  final Widget title;
  final String editText;
  final String hintText;

  /// Positive action text. null to use default "Create"
  final String? positiveAction;

  final int? maxLines;

  final int? maxLength;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textEditingController = useMemoized(
      () => EmojiTextEditingController(text: editText),
    );
    final textEditingValue = useValueListenable(textEditingController);
    return AlertDialogLayout(
      title: title,
      content: DialogTextField(
        textEditingController: textEditingController,
        hintText: hintText,
        maxLines: maxLines,
        maxLength: maxLength,
      ),
      actions: [
        MixinButton(
            backgroundTransparent: true,
            onTap: () => Navigator.pop(context),
            child: Text(context.l10n.cancel)),
        MixinButton(
          disable: textEditingValue.text.isEmpty,
          onTap: () => Navigator.pop(context, textEditingController.text),
          child: Text(positiveAction ?? context.l10n.create),
        ),
      ],
    );
  }
}

class DialogAddOrJoinButton extends StatelessWidget {
  const DialogAddOrJoinButton({
    super.key,
    required this.onTap,
    required this.title,
  });

  final VoidCallback onTap;
  final Widget title;

  @override
  Widget build(BuildContext context) => TextButton(
        style: TextButton.styleFrom(
          backgroundColor: context.theme.statusBackground,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(15)),
          ),
        ),
        onPressed: onTap,
        child: DefaultTextStyle.merge(
          style: TextStyle(fontSize: 12, color: context.theme.accent),
          child: title,
        ),
      );
}
