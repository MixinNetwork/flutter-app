import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../utils/extension/extension.dart';
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
    showGeneralDialog(
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
  EdgeInsetsGeometry? padding,
  Color? backgroundColor,
}) =>
    _showDialog(
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
            backgroundColor: backgroundColor,
            child: child,
          ),
        ),
      ),
    );

class AlertDialogLayout extends StatelessWidget {
  const AlertDialogLayout({
    Key? key,
    this.title,
    this.titleMarginBottom = 48,
    required this.content,
    this.actions = const [],
    this.minWidth = 400,
    this.minHeight = 210,
    this.padding = const EdgeInsets.all(30),
  }) : super(key: key);

  final Widget? title;
  final double titleMarginBottom;
  final Widget content;
  final List<Widget> actions;
  final double minWidth;
  final double minHeight;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: minWidth,
            minHeight: minHeight,
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
                    DefaultTextStyle(
                      style: TextStyle(
                        fontSize: 16,
                        color: context.theme.text,
                      ),
                      child: title!,
                    ),
                  if (title != null) const SizedBox(height: 48),
                  DefaultTextStyle(
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
    Key? key,
    required this.child,
    this.padding,
    this.backgroundColor,
  }) : super(key: key);

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding ?? EdgeInsets.zero,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: const Color.fromRGBO(255, 255, 255, 0.08),
            ),
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
            color: backgroundColor ?? context.theme.popUp,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: child,
          ),
        ),
      );
}

/// default onTap is Navigator.pop
abstract class DialogInteracterEntry<T> extends StatelessWidget {
  const DialogInteracterEntry({
    Key? key,
    this.value,
  }) : super(key: key);

  final T? value;

  void handleTap(BuildContext context) => Navigator.pop<T>(context, value);
}

/// default onTap is Navigator.pop
class MixinButton<T> extends DialogInteracterEntry<T> {
  const MixinButton({
    Key? key,
    T? value,
    this.backgroundTransparent = false,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(
      vertical: 8,
      horizontal: 16,
    ),
    this.disable = false,
    this.backgroundColor,
  }) : super(
          key: key,
          value: value,
        );

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
            borderRadius: BorderRadius.circular(5),
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
        child: DefaultTextStyle(
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

class DialogTextField extends HookWidget {
  const DialogTextField({
    Key? key,
    required this.textEditingController,
    required this.hintText,
    this.inputFormatters,
  }) : super(key: key);

  final TextEditingController textEditingController;
  final String hintText;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) => Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: context.theme.background,
          borderRadius: BorderRadius.circular(5),
        ),
        alignment: Alignment.center,
        child: TextField(
          autofocus: true,
          controller: textEditingController,
          style: TextStyle(
            color: context.theme.text,
          ),
          scrollPadding: EdgeInsets.zero,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.zero,
            isDense: true,
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.08)),
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
          ),
          inputFormatters: inputFormatters,
        ),
      );
}

Future<bool> showConfirmMixinDialog(
  BuildContext context,
  String content, {
  String? description,
}) async =>
    await showMixinDialog<bool>(
      context: context,
      child: Builder(
        builder: (context) => AlertDialogLayout(
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
            MixinButton(
                backgroundTransparent: true,
                onTap: () => Navigator.pop(context, false),
                child: Text(context.l10n.cancel)),
            MixinButton(
              onTap: () => Navigator.pop(context, true),
              child: Text(context.l10n.confirm),
            ),
          ],
        ),
      ),
    ) ??
    false;

class EditDialog extends HookWidget {
  const EditDialog({
    Key? key,
    required this.title,
    this.editText = '',
    this.hintText = '',
    this.positiveAction,
  }) : super(key: key);

  final Widget title;
  final String editText;
  final String hintText;

  /// Positive action text. null to use default "Create"
  final String? positiveAction;

  @override
  Widget build(BuildContext context) {
    final textEditingController = useTextEditingController(text: editText);
    final textEditingValue = useValueListenable(textEditingController);
    return AlertDialogLayout(
      title: title,
      content: DialogTextField(
        textEditingController: textEditingController,
        hintText: hintText,
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
    Key? key,
    required this.onTap,
    required this.title,
  }) : super(key: key);

  final VoidCallback onTap;
  final Widget title;

  @override
  Widget build(BuildContext context) => TextButton(
        style: TextButton.styleFrom(
          backgroundColor: context.theme.statusBackground,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: onTap,
        child: DefaultTextStyle(
          style: TextStyle(fontSize: 12, color: context.theme.accent),
          child: title,
        ),
      );
}
