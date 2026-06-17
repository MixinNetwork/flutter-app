import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../db/mixin_database.dart' hide Offset;
import 'chat_jump_trace.dart';

class ChatScrollCoordinator {
  ChatScrollCoordinator() {
    scrollController.addListener(_scheduleViewportStateUpdate);
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
  final visibleDateTime = ValueNotifier<DateTime?>(null);
  final showJumpToLatest = ValueNotifier<bool>(false);

  _ChatRestoreRequest? _restoreRequest;
  String? _animatedRestoreMessageId;
  List<MessageItem> _messages = const [];
  Map<String, GlobalKey> _keysByMessageId = const {};
  bool _pinnedToBottom = true;
  bool _animateNextRestore = false;
  bool _restoreScheduled = false;
  bool _viewportStateUpdateScheduled = false;
  bool _disposed = false;
  int _programmaticScrollDepth = 0;

  void captureViewportState(
    List<MessageItem> messages,
    Map<String, GlobalKey> keysByMessageId,
  ) {
    if (!scrollController.hasClients) return;
    _messages = messages;
    _keysByMessageId = keysByMessageId;
    _pinnedToBottom = _isPinnedToBottom();
  }

  void updateMessages(
    List<MessageItem> messages,
    Map<String, GlobalKey> keysByMessageId,
  ) {
    _messages = messages;
    _keysByMessageId = keysByMessageId;
    _scheduleViewportStateUpdate();
  }

  set nextAnimatedRestoreMessageId(String messageId) {
    _animatedRestoreMessageId = messageId;
  }

  void animateNextRestore() {
    _animateNextRestore = true;
  }

  void scheduleRestore({
    required List<MessageItem> messages,
    required Map<String, GlobalKey> keysByMessageId,
    required bool reset,
    required bool isLatest,
    String? centerMessageId,
  }) {
    final animatedMessageId = reset ? _animatedRestoreMessageId : null;
    final animated =
        reset && (animatedMessageId != null || _animateNextRestore);
    if (reset) {
      _animatedRestoreMessageId = null;
      _animateNextRestore = false;
    }
    _messages = messages;
    _keysByMessageId = keysByMessageId;
    _restoreRequest = _ChatRestoreRequest(
      messages: messages,
      keysByMessageId: keysByMessageId,
      reset: reset,
      isLatest: isLatest,
      centerMessageId: centerMessageId,
      animatedMessageId: animatedMessageId,
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
      _updateViewportState(request.messages, request.keysByMessageId);
    });
  }

  bool handleScrollNotification(
    ScrollNotification notification, {
    required List<MessageItem> messages,
    required Map<String, GlobalKey> keysByMessageId,
    required VoidCallback loadBefore,
    required VoidCallback loadAfter,
  }) {
    updateMessages(messages, keysByMessageId);
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
      ..removeListener(_scheduleViewportStateUpdate)
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
          )) {
        return;
      }
      if (request.isLatest) {
        unawaited(_jumpToBottom(animated: request.animated));
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
      _jumpToClamped(target, animated: animated).whenComplete(
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

  Future<void> _jumpToBottom({bool animated = false}) => _jumpToClamped(
    scrollController.position.maxScrollExtent,
    animated: animated,
  );

  Future<void> _jumpToClamped(
    double value, {
    bool animated = false,
    bool stageDistant = true,
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
      'target=${formatDouble(target)} '
      'distance=${formatDouble(target - position.pixels)} '
      '${formatScrollMetrics(position)}',
    );
    if ((target - position.pixels).abs() <= _jumpToTolerance) {
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

  bool _isPinnedToBottom() {
    if (!scrollController.hasClients) return true;
    final position = scrollController.position;
    if (!position.hasContentDimensions) return true;
    return position.maxScrollExtent - position.pixels <= _jumpLatestThreshold;
  }

  String? _firstVisibleMessageId(
    List<MessageItem> messages,
    Map<String, GlobalKey> keysByMessageId,
  ) {
    final viewport = _viewportRender;
    if (viewport == null) return null;
    final viewportTop = viewport.localToGlobal(Offset.zero).dy;

    for (final message in messages) {
      final render = _messageRender(message.messageId, keysByMessageId);
      if (render == null) continue;
      final itemTop = render.localToGlobal(Offset.zero).dy - viewportTop;
      final itemBottom = itemTop + render.size.height;
      if (itemBottom > 0) {
        return message.messageId;
      }
    }
    return null;
  }

  void _scheduleViewportStateUpdate() {
    if (_viewportStateUpdateScheduled || _disposed) return;
    _viewportStateUpdateScheduled = true;
    scheduleMicrotask(() {
      _viewportStateUpdateScheduled = false;
      if (_disposed) return;
      _updateViewportState(_messages, _keysByMessageId);
    });
  }

  void _updateViewportState(
    List<MessageItem> messages,
    Map<String, GlobalKey> keysByMessageId,
  ) {
    if (!scrollController.hasClients) return;
    final nextShowJumpToLatest = !_isPinnedToBottom();
    if (showJumpToLatest.value != nextShowJumpToLatest) {
      showJumpToLatest.value = nextShowJumpToLatest;
    }

    final firstVisibleMessageId = _firstVisibleMessageId(
      messages,
      keysByMessageId,
    );
    DateTime? nextDateTime;
    if (firstVisibleMessageId != null) {
      for (final message in messages) {
        if (message.messageId == firstVisibleMessageId) {
          nextDateTime = message.createdAt;
          break;
        }
      }
    }
    if (visibleDateTime.value != nextDateTime) {
      visibleDateTime.value = nextDateTime;
    }
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
  });

  final List<MessageItem> messages;
  final Map<String, GlobalKey> keysByMessageId;
  final bool reset;
  final bool isLatest;
  final bool animated;
  final String? centerMessageId;
  final String? animatedMessageId;
}
