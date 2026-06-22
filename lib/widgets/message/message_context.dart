import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../../db/mixin_database.dart' hide Message;

class _MessageContext with EquatableMixin {
  _MessageContext({
    required this.isTranscriptPage,
    required this.isPinnedPage,
    required this.showNip,
    required this.isCurrentUser,
    required this.highlightEnabled,
    required this.menuHighlighted,
    required this.message,
  });

  final bool isTranscriptPage;
  final bool isPinnedPage;
  final bool showNip;
  final bool isCurrentUser;
  final bool highlightEnabled;
  final bool menuHighlighted;
  final MessageItem message;

  @override
  List<Object?> get props => [
    isTranscriptPage,
    isPinnedPage,
    showNip,
    isCurrentUser,
    highlightEnabled,
    menuHighlighted,
    message,
  ];
}

bool useIsTranscriptPage() =>
    _useMessageContextConverter((state) => state.isTranscriptPage);

bool useIsPinnedPage() =>
    _useMessageContextConverter((state) => state.isPinnedPage);

bool useShowNip() => _useMessageContextConverter((state) => state.showNip);

bool useIsCurrentUser() =>
    _useMessageContextConverter((state) => state.isCurrentUser);

bool useMessageHighlightEnabled() =>
    _useMessageContextConverter((state) => state.highlightEnabled);

bool useMessageMenuHighlighted() =>
    _useMessageContextConverter((state) => state.menuHighlighted);

T useMessageConverter<T>({required T Function(MessageItem) converter}) =>
    _useMessageContextConverter((state) => converter(state.message));

T _useMessageContextConverter<T>(T Function(_MessageContext) converter) {
  final context = useContext();
  return converter(_MessageContextScope.watch(context));
}

extension MessageContextExtension on BuildContext {
  _MessageContext get _messageContext => _MessageContextScope.read(this);

  MessageItem get message => _messageContext.message;

  bool get isPinnedPage => _messageContext.isPinnedPage;

  bool get isTranscriptPage => _messageContext.isTranscriptPage;
}

class MessageContext extends StatelessWidget {
  const MessageContext({
    required this.isTranscriptPage,
    required this.isPinnedPage,
    required this.showNip,
    required this.isCurrentUser,
    required this.message,
    required this.child,
    super.key,
    this.highlightEnabled = true,
    this.menuHighlighted = false,
  });

  MessageContext.fromMessageItem({
    required this.message,
    required this.child,
    super.key,
    this.isTranscriptPage = false,
    this.isPinnedPage = false,
    this.showNip = false,
    this.highlightEnabled = true,
    this.menuHighlighted = false,
  }) : isCurrentUser = message.relationship == UserRelationship.me;

  final bool isTranscriptPage;
  final bool isPinnedPage;
  final bool showNip;
  final bool isCurrentUser;
  final bool highlightEnabled;
  final bool menuHighlighted;
  final MessageItem message;
  final Widget child;

  @override
  Widget build(BuildContext context) => _MessageContextScope(
    value: _MessageContext(
      isTranscriptPage: isTranscriptPage,
      isPinnedPage: isPinnedPage,
      showNip: showNip,
      isCurrentUser: isCurrentUser,
      highlightEnabled: highlightEnabled,
      menuHighlighted: menuHighlighted,
      message: message,
    ),
    child: child,
  );
}

class _MessageContextScope extends InheritedWidget {
  const _MessageContextScope({
    required this.value,
    required super.child,
  });

  final _MessageContext value;

  static _MessageContext watch(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_MessageContextScope>();
    assert(scope != null, 'No MessageContext found in widget tree.');
    return scope!.value;
  }

  static _MessageContext read(BuildContext context) {
    final scope =
        context
                .getElementForInheritedWidgetOfExactType<_MessageContextScope>()
                ?.widget
            as _MessageContextScope?;
    assert(scope != null, 'No MessageContext found in widget tree.');
    return scope!.value;
  }

  @override
  bool updateShouldNotify(_MessageContextScope oldWidget) =>
      value != oldWidget.value;
}
