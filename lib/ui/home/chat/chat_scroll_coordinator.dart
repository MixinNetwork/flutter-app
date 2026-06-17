import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../db/mixin_database.dart' hide Offset;
import 'chat_jump_trace.dart';

enum ChatScrollRestoreDirection { towardOlder, towardNewer }

class MessageGlobalKey extends GlobalObjectKey<State<StatefulWidget>> {
  const MessageGlobalKey(String super.value);

  String get messageId => value as String;
}

class ChatScrollCoordinator {
  ChatScrollCoordinator() {
    scrollController.addListener(_scheduleScrollPositionUpdate);
  }

  static const _jumpLatestThreshold = 40.0;
  static const _preloadViewportCount = 3.0;
  static const _jumpToTolerance = 0.5;
  static const _jumpAnimationDuration = Duration(milliseconds: 300);
  static const _jumpAnimationCurve = Curves.easeOutCubic;
  static const _maxAnimatedJumpViewportCount = 3.0;
  static const _maxAnimatedJumpDistance = 800.0;
  static const loadedJumpViewportCount = 2.0;

  final scrollController = ScrollController();
  final viewportKey = GlobalKey(debugLabel: 'chat scroll viewport');
  final topSliverKey = GlobalKey(debugLabel: 'chat top sliver');
  final bottomSliverKey = GlobalKey(debugLabel: 'chat bottom sliver');
  final visibleDateTime = ValueNotifier<DateTime?>(null);
  final showJumpToLatest = ValueNotifier<bool>(false);

  _ChatRestoreRequest? _restoreRequest;
  String? _animatedRestoreMessageId;
  List<MessageItem> _messages = const [];
  Map<String, MessageItem> _messagesById = const {};
  Map<String, GlobalKey> _keysByMessageId = const {};
  String? _centerMessageId;
  bool _pinnedToBottom = true;
  bool _animateNextRestore = false;
  ChatScrollRestoreDirection? _animatedRestoreDirection;
  bool _restoreScheduled = false;
  bool _viewportStateUpdateScheduled = false;
  bool _viewportStateUpdateIncludesVisibleDate = false;
  bool _disposed = false;
  int _programmaticScrollDepth = 0;

  void captureViewportState(
    List<MessageItem> messages,
    Map<String, GlobalKey> keysByMessageId,
  ) {
    if (!scrollController.hasClients) return;
    _setMessages(messages, keysByMessageId);
    _pinnedToBottom = _isPinnedToBottom();
  }

  void updateMessages(
    List<MessageItem> messages,
    Map<String, GlobalKey> keysByMessageId,
  ) {
    _setMessages(messages, keysByMessageId);
    _scheduleViewportStateUpdate();
  }

  set nextAnimatedRestoreMessageId(String messageId) {
    animateNextMessageRestore(messageId);
  }

  void animateNextMessageRestore(
    String messageId, {
    ChatScrollRestoreDirection? direction,
  }) {
    _animatedRestoreMessageId = messageId;
    _animatedRestoreDirection = direction;
  }

  void animateNextRestore({ChatScrollRestoreDirection? direction}) {
    _animateNextRestore = true;
    _animatedRestoreDirection = direction;
  }

  void scheduleRestore({
    required List<MessageItem> messages,
    required Map<String, GlobalKey> keysByMessageId,
    required bool reset,
    required bool isLatest,
    String? centerMessageId,
  }) {
    final animatedMessageId = reset ? _animatedRestoreMessageId : null;
    final animatedRestoreDirection = reset ? _animatedRestoreDirection : null;
    final animated =
        reset && (animatedMessageId != null || _animateNextRestore);
    if (reset) {
      _animatedRestoreMessageId = null;
      _animatedRestoreDirection = null;
      _animateNextRestore = false;
    }
    _setMessages(
      messages,
      keysByMessageId,
      updateCenterMessageId: true,
      centerMessageId: centerMessageId,
    );
    _restoreRequest = _ChatRestoreRequest(
      messages: messages,
      keysByMessageId: keysByMessageId,
      reset: reset,
      isLatest: isLatest,
      centerMessageId: centerMessageId,
      animatedMessageId: animatedMessageId,
      animatedRestoreDirection: animatedRestoreDirection,
      animated: animated,
    );
    if (_restoreScheduled) return;
    _restoreScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreScheduled = false;
      if (_disposed) return;
      final request = _restoreRequest;
      _restoreRequest = null;
      if (request == null || !scrollController.hasClients) return;
      _restore(request);
      _updateViewportState();
    });
  }

  bool handleScrollNotification(
    ScrollNotification notification, {
    required List<MessageItem> messages,
    required Map<String, GlobalKey> keysByMessageId,
    required VoidCallback loadBefore,
    required VoidCallback loadAfter,
  }) {
    _setMessages(messages, keysByMessageId);
    _scheduleViewportStateUpdate(
      updateVisibleDate: notification is ScrollEndNotification,
    );
    if (notification is! ScrollUpdateNotification) return false;
    if (_programmaticScrollDepth > 0) {
      traceChatJump(
        'ignore programmatic scroll delta='
        '${formatDouble(notification.scrollDelta)} '
        '${formatScrollMetrics(notification.metrics)}',
      );
      return false;
    }
    final scrollDelta = notification.scrollDelta;
    if (scrollDelta == null || scrollDelta == 0) return false;

    final threshold =
        notification.metrics.viewportDimension * _preloadViewportCount;
    if (scrollDelta > 0) {
      if (notification.metrics.maxScrollExtent - notification.metrics.pixels <=
          threshold) {
        loadAfter();
      }
    } else {
      if ((notification.metrics.minScrollExtent - notification.metrics.pixels)
              .abs() <=
          threshold) {
        loadBefore();
      }
    }
    return false;
  }

  Future<void> scrollToBottom({bool animated = false}) {
    if (!scrollController.hasClients) return Future<void>.value();
    final future = _jumpToBottom(animated: animated);
    _scheduleViewportStateUpdate();
    return future;
  }

  Future<bool> scrollToBottomIfInLoadedWindow({bool animated = false}) async {
    if (!scrollController.hasClients) return false;
    final target = scrollController.position.maxScrollExtent;
    if (!_isTargetInLoadedJumpWindow(target)) return false;
    await _jumpToBottom(animated: animated);
    _scheduleViewportStateUpdate();
    return true;
  }

  Future<bool> scrollToMessageIfInLoadedWindow(
    String messageId, {
    bool animated = false,
  }) async {
    if (!scrollController.hasClients) return false;
    final geometry = _messageTargetGeometry(messageId, _keysByMessageId);
    if (geometry == null) {
      traceChatJump(
        'near missing-render target=${shortMessageId(messageId)} '
        'messages=${_messages.length} keys=${_keysByMessageId.length} '
        '${formatScrollMetrics(scrollController.position)}',
      );
      return false;
    }
    final target = geometry.target;
    final inWindow = _isTargetInLoadedJumpWindow(target);
    traceChatJump(
      'near target=${shortMessageId(messageId)} inWindow=$inWindow '
      'target=${formatDouble(target)} ${geometry.format()} '
      '${formatScrollMetrics(scrollController.position)}',
    );
    if (!inWindow) return false;
    await _jumpToClamped(target, animated: animated, stageDistant: false);
    _traceTargetAfterLayout('near-after', messageId, _keysByMessageId);
    _scheduleViewportStateUpdate();
    return true;
  }

  void dispose() {
    _disposed = true;
    scrollController
      ..removeListener(_scheduleScrollPositionUpdate)
      ..dispose();
    visibleDateTime.dispose();
    showJumpToLatest.dispose();
  }

  void _restore(_ChatRestoreRequest request) {
    traceChatJump(
      'restore reset=${request.reset} latest=${request.isLatest} '
      'center=${shortMessageId(request.centerMessageId)} '
      'animated=${request.animated} '
      'animatedMessage=${shortMessageId(request.animatedMessageId)} '
      'messages=${request.messages.length} '
      '${formatScrollMetrics(scrollController.position)}',
    );
    if (request.reset) {
      if (request.centerMessageId != null &&
          _jumpToMessage(
            request.centerMessageId!,
            request.keysByMessageId,
            animated: request.animatedMessageId == request.centerMessageId,
            animatedDirection: request.animatedRestoreDirection,
          )) {
        return;
      }
      if (request.isLatest) {
        unawaited(
          _jumpToBottom(
            animated: request.animated,
            animationDirection: request.animatedRestoreDirection,
          ),
        );
      }
      return;
    }

    if (scrollController.position.isScrollingNotifier.value) return;

    if (_pinnedToBottom) {
      unawaited(_jumpToBottom());
    }
  }

  bool _jumpToMessage(
    String messageId,
    Map<String, GlobalKey> keysByMessageId, {
    bool animated = false,
    ChatScrollRestoreDirection? animatedDirection,
  }) {
    final geometry = _messageTargetGeometry(messageId, keysByMessageId);
    if (geometry == null) {
      traceChatJump(
        'restore missing-render target=${shortMessageId(messageId)} '
        'keys=${keysByMessageId.length} '
        '${formatScrollMetrics(scrollController.position)}',
      );
      return false;
    }
    final target = geometry.target;
    traceChatJump(
      'restore jump target=${shortMessageId(messageId)} '
      'animated=$animated target=${formatDouble(target)} '
      '${geometry.format()} '
      '${formatScrollMetrics(scrollController.position)}',
    );
    unawaited(
      _jumpToClamped(
        target,
        animated: animated,
        stageDistant: false,
        animationDirection: animated ? animatedDirection : null,
      ).whenComplete(
        () => _traceTargetAfterLayout(
          'restore-after',
          messageId,
          keysByMessageId,
        ),
      ),
    );
    return true;
  }

  _MessageTargetGeometry? _messageTargetGeometry(
    String messageId,
    Map<String, GlobalKey> keysByMessageId,
  ) {
    final render = _messageRender(messageId, keysByMessageId);
    final viewport = _viewportRender;
    if (render == null || viewport == null) return null;

    final viewportTop = viewport.localToGlobal(Offset.zero).dy;
    final top = render.localToGlobal(Offset.zero).dy - viewportTop;
    final height = render.size.height;
    final target =
        scrollController.offset +
        top -
        scrollController.position.viewportDimension * 0.3;
    return _MessageTargetGeometry(
      target: target,
      top: top,
      bottom: top + height,
      height: height,
    );
  }

  bool _isTargetInLoadedJumpWindow(double target) {
    if (!scrollController.hasClients) return false;
    final position = scrollController.position;
    final clampedTarget = target.clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (!clampedTarget.isFinite) return false;
    return (clampedTarget - position.pixels).abs() <=
        _loadedJumpDistance(position);
  }

  double _loadedJumpDistance(ScrollPosition position) {
    final viewportDimension = position.viewportDimension;
    if (!viewportDimension.isFinite || viewportDimension <= 0) return 0;
    return viewportDimension * loadedJumpViewportCount;
  }

  Future<void> _jumpToBottom({
    bool animated = false,
    ChatScrollRestoreDirection? animationDirection,
  }) => _jumpToClamped(
    scrollController.position.maxScrollExtent,
    animated: animated,
    animationDirection: animated ? animationDirection : null,
  );

  Future<void> _jumpToClamped(
    double value, {
    bool animated = false,
    bool stageDistant = true,
    ChatScrollRestoreDirection? animationDirection,
  }) {
    if (!scrollController.hasClients) return Future<void>.value();
    final position = scrollController.position;
    final target = value.clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (!target.isFinite) return Future<void>.value();
    traceChatJump(
      'jump start animated=$animated stage=$stageDistant '
      'direction=$animationDirection '
      'target=${formatDouble(target)} '
      'distance=${formatDouble(target - position.pixels)} '
      '${formatScrollMetrics(position)}',
    );
    if (animationDirection == null &&
        (target - position.pixels).abs() <= _jumpToTolerance) {
      if (animated) {
        return _runProgrammaticScroll(
          () => scrollController.animateTo(
            target,
            duration: _jumpAnimationDuration,
            curve: _jumpAnimationCurve,
          ),
        );
      }
      return Future<void>.value();
    }
    if (animated) {
      return _runProgrammaticScroll(
        () {
          final maxAnimatedDistance = _maxAnimatedDistance(position);
          if (maxAnimatedDistance <= 0) {
            scrollController.jumpTo(target);
            return Future<void>.value();
          }
          final distance = target - position.pixels;
          if (animationDirection != null) {
            _jumpToDirectionalAnimationStart(
              target,
              animationDirection,
              position,
            );
            return scrollController.animateTo(
              target,
              duration: _jumpAnimationDuration,
              curve: _jumpAnimationCurve,
            );
          }
          if (stageDistant && distance.abs() > maxAnimatedDistance) {
            final stagedTarget = target - maxAnimatedDistance * distance.sign;
            traceChatJump(
              'jump staged target=${formatDouble(stagedTarget)} '
              'final=${formatDouble(target)} '
              'maxAnimated=${formatDouble(maxAnimatedDistance)}',
            );
            scrollController.jumpTo(
              stagedTarget.clamp(
                position.minScrollExtent,
                position.maxScrollExtent,
              ),
            );
          }
          return scrollController.animateTo(
            target,
            duration: _jumpAnimationDuration,
            curve: _jumpAnimationCurve,
          );
        },
      );
    }
    scrollController.jumpTo(target);
    _scheduleViewportStateUpdate();
    return Future<void>.value();
  }

  Future<void> _runProgrammaticScroll(Future<void> Function() scroll) async {
    _programmaticScrollDepth++;
    try {
      await scroll();
    } finally {
      _programmaticScrollDepth--;
      if (scrollController.hasClients) {
        traceChatJump(
          'jump done ${formatScrollMetrics(scrollController.position)}',
        );
      }
      _scheduleViewportStateUpdate();
    }
  }

  double _maxAnimatedDistance(ScrollPosition position) {
    final viewportDimension = position.viewportDimension;
    if (!viewportDimension.isFinite || viewportDimension <= 0) return 0;
    return math.min(
      viewportDimension * _maxAnimatedJumpViewportCount,
      _maxAnimatedJumpDistance,
    );
  }

  void _jumpToDirectionalAnimationStart(
    double target,
    ChatScrollRestoreDirection direction,
    ScrollPosition position,
  ) {
    final startDistance = _restoreAnimationStartDistance(position);
    if (startDistance <= 0) return;

    final currentDistance = position.pixels - target;
    final hasCorrectSide = switch (direction) {
      ChatScrollRestoreDirection.towardOlder =>
        currentDistance > _jumpToTolerance,
      ChatScrollRestoreDirection.towardNewer =>
        currentDistance < -_jumpToTolerance,
    };
    final shouldReposition =
        !hasCorrectSide || currentDistance.abs() > startDistance;
    if (!shouldReposition) return;

    final start = switch (direction) {
      ChatScrollRestoreDirection.towardOlder => target + startDistance,
      ChatScrollRestoreDirection.towardNewer => target - startDistance,
    }.clamp(position.minScrollExtent, position.maxScrollExtent);
    if ((start - target).abs() <= _jumpToTolerance) return;

    traceChatJump(
      'jump directional-start direction=$direction '
      'start=${formatDouble(start)} final=${formatDouble(target)} '
      'distance=${formatDouble(start - target)}',
    );
    scrollController.jumpTo(start);
  }

  double _restoreAnimationStartDistance(ScrollPosition position) {
    final viewportDimension = position.viewportDimension;
    if (!viewportDimension.isFinite || viewportDimension <= 0) return 0;
    final maxAnimatedDistance = _maxAnimatedDistance(position);
    if (maxAnimatedDistance <= 0) return 0;
    return math.min(viewportDimension * 0.75, maxAnimatedDistance);
  }

  bool _isPinnedToBottom() {
    if (!scrollController.hasClients) return true;
    final position = scrollController.position;
    if (!position.hasContentDimensions) return true;
    return position.maxScrollExtent - position.pixels <= _jumpLatestThreshold;
  }

  String? _firstVisibleMessageId() {
    String? firstVisibleMessageId;
    double? firstVisibleTop;

    for (final messageId in _renderedMessageIds()) {
      final geometry = _messageTargetGeometry(messageId, _keysByMessageId);
      if (geometry == null || geometry.bottom <= 0) continue;
      if (firstVisibleTop == null || geometry.top < firstVisibleTop) {
        firstVisibleMessageId = messageId;
        firstVisibleTop = geometry.top;
      }
    }

    return firstVisibleMessageId;
  }

  void _scheduleScrollPositionUpdate() {
    _scheduleViewportStateUpdate(updateVisibleDate: false);
  }

  void _scheduleViewportStateUpdate({bool updateVisibleDate = true}) {
    if (_disposed) return;
    _viewportStateUpdateIncludesVisibleDate =
        _viewportStateUpdateIncludesVisibleDate || updateVisibleDate;
    if (_viewportStateUpdateScheduled) return;
    _viewportStateUpdateScheduled = true;
    scheduleMicrotask(() {
      final updateVisibleDate = _viewportStateUpdateIncludesVisibleDate;
      _viewportStateUpdateScheduled = false;
      _viewportStateUpdateIncludesVisibleDate = false;
      if (_disposed) return;
      _updateViewportState(updateVisibleDate: updateVisibleDate);
    });
  }

  void _updateViewportState({bool updateVisibleDate = true}) {
    if (!scrollController.hasClients) return;
    final nextShowJumpToLatest = !_isPinnedToBottom();
    if (showJumpToLatest.value != nextShowJumpToLatest) {
      showJumpToLatest.value = nextShowJumpToLatest;
    }

    if (!updateVisibleDate) return;
    final firstVisibleMessageId = _firstVisibleMessageId();
    final nextDateTime = firstVisibleMessageId == null
        ? null
        : _messagesById[firstVisibleMessageId]?.createdAt;
    if (visibleDateTime.value != nextDateTime) {
      visibleDateTime.value = nextDateTime;
    }
  }

  void _setMessages(
    List<MessageItem> messages,
    Map<String, GlobalKey> keysByMessageId, {
    bool updateCenterMessageId = false,
    String? centerMessageId,
  }) {
    if (!identical(_messages, messages)) {
      _messages = messages;
      _messagesById = {
        for (final message in messages) message.messageId: message,
      };
    }
    _keysByMessageId = keysByMessageId;
    if (updateCenterMessageId) {
      _centerMessageId = centerMessageId;
    }
  }

  Iterable<String> _renderedMessageIds() sync* {
    yield* _messageIdsInSliver(topSliverKey);
    final centerMessageId = _centerMessageId;
    if (centerMessageId != null) yield centerMessageId;
    yield* _messageIdsInSliver(bottomSliverKey);
  }

  Iterable<String> _messageIdsInSliver(GlobalKey sliverKey) sync* {
    final context = sliverKey.currentContext;
    if (context is! Element) return;

    final messageIds = <String>[];
    context.visitChildElements((element) {
      final key = _messageGlobalKeyInSubtree(element);
      if (key != null) messageIds.add(key.messageId);
    });
    yield* messageIds;
  }

  MessageGlobalKey? _messageGlobalKeyInSubtree(Element element) {
    final key = element.widget.key;
    if (key is MessageGlobalKey) return key;

    MessageGlobalKey? result;
    element.visitChildElements((child) {
      result ??= _messageGlobalKeyInSubtree(child);
    });
    return result;
  }

  RenderBox? _messageRender(
    String messageId,
    Map<String, GlobalKey> keysByMessageId,
  ) {
    final object = keysByMessageId[messageId]?.currentContext
        ?.findRenderObject();
    return object is RenderBox ? object : null;
  }

  RenderBox? get _viewportRender {
    final object = viewportKey.currentContext?.findRenderObject();
    return object is RenderBox ? object : null;
  }

  void _traceTargetAfterLayout(
    String phase,
    String messageId,
    Map<String, GlobalKey> keysByMessageId,
  ) {
    if (!chatJumpTraceEnabled) return;
    void trace(String step) {
      if (_disposed || !scrollController.hasClients) return;
      final geometry = _messageTargetGeometry(messageId, keysByMessageId);
      traceChatJump(
        '$phase $step target=${shortMessageId(messageId)} '
        'rendered=${geometry != null} '
        '${geometry?.format() ?? ''} '
        '${formatScrollMetrics(scrollController.position)}',
      );
    }

    trace('after-await');
    WidgetsBinding.instance.addPostFrameCallback((_) => trace('post-frame'));
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 250), () {
        trace('250ms');
      }),
    );
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 800), () {
        trace('800ms');
      }),
    );
  }
}

class _MessageTargetGeometry {
  const _MessageTargetGeometry({
    required this.target,
    required this.top,
    required this.bottom,
    required this.height,
  });

  final double target;
  final double top;
  final double bottom;
  final double height;

  String format() =>
      'top=${formatDouble(top)} bottom=${formatDouble(bottom)} '
      'height=${formatDouble(height)}';
}

class _ChatRestoreRequest {
  const _ChatRestoreRequest({
    required this.messages,
    required this.keysByMessageId,
    required this.reset,
    required this.isLatest,
    required this.animated,
    this.centerMessageId,
    this.animatedMessageId,
    this.animatedRestoreDirection,
  });

  final List<MessageItem> messages;
  final Map<String, GlobalKey> keysByMessageId;
  final bool reset;
  final bool isLatest;
  final bool animated;
  final String? centerMessageId;
  final String? animatedMessageId;
  final ChatScrollRestoreDirection? animatedRestoreDirection;
}
