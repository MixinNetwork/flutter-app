import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../db/mixin_database.dart' hide Offset;
import 'chat_jump_trace.dart';

enum ChatScrollRestoreDirection { towardOlder, towardNewer }

class MessageGlobalKey extends GlobalObjectKey<State<StatefulWidget>> {
  const MessageGlobalKey(String super.value);

  String get messageId => value as String;
}

class ChatRenderedMessage extends StatefulWidget {
  const ChatRenderedMessage({
    required this.coordinator,
    required this.messageId,
    required this.child,
    super.key,
  });

  final ChatScrollCoordinator coordinator;
  final String messageId;
  final Widget child;

  @override
  State<ChatRenderedMessage> createState() => _ChatRenderedMessageState();
}

class _ChatRenderedMessageState extends State<ChatRenderedMessage> {
  @override
  void initState() {
    super.initState();
    widget.coordinator.registerRenderedMessageId(widget.messageId);
  }

  @override
  void didUpdateWidget(covariant ChatRenderedMessage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.messageId == widget.messageId &&
        oldWidget.coordinator == widget.coordinator) {
      return;
    }
    oldWidget.coordinator.unregisterRenderedMessageId(oldWidget.messageId);
    widget.coordinator.registerRenderedMessageId(widget.messageId);
  }

  @override
  void dispose() {
    widget.coordinator.unregisterRenderedMessageId(widget.messageId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class ChatScrollCoordinator {
  ChatScrollCoordinator() {
    scrollController.addListener(_scheduleScrollPositionUpdate);
  }

  static const _tailFollowThreshold = 50.0;
  static const _showJumpToLatestThreshold = 96.0;
  static const _jumpButtonFreezeUpdateCount = 1;
  static const _preloadViewportCount = 3.0;
  static const _jumpToTolerance = 0.5;
  static const _jumpAnimationDuration = Duration(milliseconds: 300);
  static const _jumpAnimationCurve = Curves.easeOutCubic;
  static const _maxAnimatedJumpViewportCount = 3.0;
  static const _maxAnimatedJumpDistance = 800.0;
  static const messageFocusAnchor = 0.2;
  static const unreadSeparatorAnchor = messageFocusAnchor;
  static const loadedJumpViewportCount = 2.0;

  final scrollController = ScrollController();
  final visibleDateTime = ValueNotifier<DateTime?>(null);
  final showJumpToLatest = ValueNotifier<bool>(false);

  _ChatRestoreRequest? _restoreRequest;
  String? _animatedRestoreMessageId;
  VoidCallback? _animatedRestoreComplete;
  List<MessageItem> _messages = const [];
  Map<String, MessageItem> _messagesById = const {};
  Map<String, GlobalKey> _keysByMessageId = const {};
  GlobalKey? _viewportKey;
  final _renderedMessageIds = <String>{};
  bool _tailFollowEligible = true;
  _TailFollowAnchorSnapshot? _tailFollowAnchorSnapshot;
  bool _animateNextRestore = false;
  ChatScrollRestoreDirection? _animatedRestoreDirection;
  bool _restoreScheduled = false;
  bool _viewportStateUpdateScheduled = false;
  bool _viewportStateUpdateIncludesVisibleDate = false;
  bool _blockPreloadUntilUserScroll = false;
  bool _disposed = false;
  int _programmaticScrollDepth = 0;
  int _jumpButtonFrozenUpdates = 0;

  void captureViewportState(
    List<MessageItem> messages,
    Map<String, GlobalKey> keysByMessageId,
  ) {
    if (!scrollController.hasClients) return;
    _setMessages(messages, keysByMessageId);
    _tailFollowEligible = _isTailFollowEligible();
    _tailFollowAnchorSnapshot = _tailFollowEligible
        ? _tailFollowAnchorSnapshotFromViewport()
        : null;
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
    VoidCallback? onComplete,
  }) {
    _animatedRestoreMessageId = messageId;
    _animatedRestoreDirection = direction;
    _animatedRestoreComplete = onComplete;
  }

  void animateNextRestore({ChatScrollRestoreDirection? direction}) {
    _animateNextRestore = true;
    _animatedRestoreDirection = direction;
  }

  void registerRenderedMessageId(String messageId) {
    _renderedMessageIds.add(messageId);
  }

  void unregisterRenderedMessageId(String messageId) {
    _renderedMessageIds.remove(messageId);
  }

  GlobalKey get viewportKey =>
      _viewportKey ??= GlobalKey(debugLabel: 'chat scroll viewport');

  set viewportKey(GlobalKey key) => _viewportKey = key;

  void detachViewportKey(GlobalKey key) {
    if (_viewportKey == key) {
      _viewportKey = null;
    }
  }

  void scheduleRestore({
    required List<MessageItem> messages,
    required Map<String, GlobalKey> keysByMessageId,
    required bool reset,
    required bool isLatest,
    bool hasCenteredAnchor = false,
    bool animateLatestReset = false,
    String? centerMessageId,
    String? traceTargetMessageId,
  }) {
    final animatedMessageId = reset ? _animatedRestoreMessageId : null;
    final animatedRestoreDirection = reset ? _animatedRestoreDirection : null;
    final animatedRestoreComplete = reset ? _animatedRestoreComplete : null;
    final animated =
        reset &&
        (animatedMessageId != null ||
            _animateNextRestore ||
            animateLatestReset);
    if (reset) {
      _animatedRestoreMessageId = null;
      _animatedRestoreDirection = null;
      _animatedRestoreComplete = null;
      _animateNextRestore = false;
      _blockPreloadUntilUserScroll = true;
      if (!animated && (hasCenteredAnchor || centerMessageId != null)) {
        _resetCenteredOffsetBeforePaint();
      }
    }
    _setMessages(messages, keysByMessageId);
    _restoreRequest = _ChatRestoreRequest(
      messages: messages,
      keysByMessageId: keysByMessageId,
      reset: reset,
      isLatest: isLatest,
      centerMessageId: centerMessageId,
      animatedMessageId: animatedMessageId,
      animatedRestoreDirection: animatedRestoreDirection,
      animatedRestoreComplete: animatedRestoreComplete,
      animated: animated,
      hasCenteredAnchor: hasCenteredAnchor,
      traceTargetMessageId: traceTargetMessageId,
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

  void _resetCenteredOffsetBeforePaint() {
    if (!scrollController.hasClients) return;
    if (scrollController.offset.abs() <= _jumpToTolerance) return;
    traceChatJump(
      'restore prepaint-zero '
      '${formatScrollMetrics(scrollController.position)}',
    );
    scrollController.position.correctPixels(0);
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
    _unlockPreloadOnUserScrollIntent(notification);
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
    if (_blockPreloadUntilUserScroll) {
      if (notification.dragDetails == null) {
        traceChatJump(
          'preload blocked delta=${formatDouble(scrollDelta)} '
          '${formatScrollMetrics(notification.metrics)}',
        );
        return false;
      }
      traceChatJump(
        'preload unblocked by drag update '
        '${formatScrollMetrics(notification.metrics)}',
      );
      _blockPreloadUntilUserScroll = false;
    }

    final threshold =
        notification.metrics.viewportDimension * _preloadViewportCount;
    if (scrollDelta > 0) {
      if (notification.metrics.maxScrollExtent - notification.metrics.pixels <=
          threshold) {
        traceChatJump(
          'preload after delta=${formatDouble(scrollDelta)} '
          'threshold=${formatDouble(threshold)} '
          '${formatScrollMetrics(notification.metrics)}',
        );
        loadAfter();
      }
    } else {
      if ((notification.metrics.minScrollExtent - notification.metrics.pixels)
              .abs() <=
          threshold) {
        traceChatJump(
          'preload before delta=${formatDouble(scrollDelta)} '
          'threshold=${formatDouble(threshold)} '
          '${formatScrollMetrics(notification.metrics)}',
        );
        loadBefore();
      }
    }
    return false;
  }

  void _unlockPreloadOnUserScrollIntent(ScrollNotification notification) {
    if (!_blockPreloadUntilUserScroll || _programmaticScrollDepth > 0) return;
    if (notification is UserScrollNotification &&
        notification.direction != ScrollDirection.idle) {
      traceChatJump(
        'preload unblocked by user direction=${notification.direction}',
      );
      _blockPreloadUntilUserScroll = false;
      return;
    }
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      traceChatJump('preload unblocked by drag start');
      _blockPreloadUntilUserScroll = false;
    }
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
      'centerAnchor=${request.hasCenteredAnchor} '
      'traceTarget=${shortMessageId(request.traceTargetMessageId)} '
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
            onComplete: request.animatedRestoreComplete,
          )) {
        return;
      }
      if (request.hasCenteredAnchor) {
        _traceTargetAfterRestore(request);
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
      _traceTargetAfterRestore(request);
      return;
    }

    if (scrollController.position.isScrollingNotifier.value) return;

    if (_tailFollowEligible) {
      unawaited(
        _jumpToBottom(
          animated: true,
          prepareAnimationStart: _restoreTailFollowAnimationStart,
        ),
      );
    }
  }

  bool _jumpToMessage(
    String messageId,
    Map<String, GlobalKey> keysByMessageId, {
    bool animated = false,
    ChatScrollRestoreDirection? animatedDirection,
    VoidCallback? onComplete,
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
      ).whenComplete(() {
        _traceTargetAfterLayout(
          'restore-after',
          messageId,
          keysByMessageId,
        );
        onComplete?.call();
      }),
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
        scrollController.position.viewportDimension * messageFocusAnchor;
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
    VoidCallback? prepareAnimationStart,
  }) {
    _clearJumpButtonFreeze();
    return _jumpToClamped(
      scrollController.position.maxScrollExtent,
      animated: animated,
      animationDirection: animated ? animationDirection : null,
      prepareAnimationStart: prepareAnimationStart,
    );
  }

  Future<void> _jumpToClamped(
    double value, {
    bool animated = false,
    bool stageDistant = true,
    ChatScrollRestoreDirection? animationDirection,
    VoidCallback? prepareAnimationStart,
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
    if (!animated) {
      if ((target - position.pixels).abs() <= _jumpToTolerance) {
        return Future<void>.value();
      }
      scrollController.jumpTo(target);
      _scheduleViewportStateUpdate();
      return Future<void>.value();
    }
    return _runProgrammaticScroll(
      () {
        prepareAnimationStart?.call();
        final position = scrollController.position;
        final maxAnimatedDistance = _maxAnimatedDistance(position);
        if (maxAnimatedDistance <= 0) {
          scrollController.jumpTo(target);
          return Future<void>.value();
        }
        final distance = target - position.pixels;
        if (animationDirection == null && distance.abs() <= _jumpToTolerance) {
          return scrollController.animateTo(
            target,
            duration: _jumpAnimationDuration,
            curve: _jumpAnimationCurve,
          );
        }
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

  bool _isTailFollowEligible() => _distanceToBottom() <= _tailFollowThreshold;

  bool _shouldShowJumpToLatest() =>
      _distanceToBottom() > _showJumpToLatestThreshold;

  double _distanceToBottom() {
    if (!scrollController.hasClients) return 0;
    final position = scrollController.position;
    if (!position.hasContentDimensions) return 0;
    return math.max(0, position.maxScrollExtent - position.pixels);
  }

  String? _firstVisibleMessageId() {
    String? firstVisibleMessageId;
    double? firstVisibleTop;

    for (final messageId in _currentRenderedMessageIds()) {
      final geometry = _messageTargetGeometry(messageId, _keysByMessageId);
      if (geometry == null || geometry.bottom <= 0) continue;
      if (firstVisibleTop == null || geometry.top < firstVisibleTop) {
        firstVisibleMessageId = messageId;
        firstVisibleTop = geometry.top;
      }
    }

    return firstVisibleMessageId;
  }

  _TailFollowAnchorSnapshot? _tailFollowAnchorSnapshotFromViewport() {
    _TailFollowAnchorSnapshot? snapshot;
    final viewportHeight = scrollController.position.viewportDimension;
    for (final messageId in _currentRenderedMessageIds()) {
      final geometry = _messageTargetGeometry(messageId, _keysByMessageId);
      if (geometry == null ||
          geometry.bottom <= 0 ||
          geometry.top >= viewportHeight) {
        continue;
      }
      if (snapshot == null || geometry.bottom > snapshot.bottom) {
        snapshot = _TailFollowAnchorSnapshot(
          messageId: messageId,
          bottom: geometry.bottom,
        );
      }
    }
    return snapshot;
  }

  void _restoreTailFollowAnimationStart() {
    final snapshot = _tailFollowAnchorSnapshot;
    _tailFollowAnchorSnapshot = null;
    if (snapshot == null || !scrollController.hasClients) return;
    final geometry = _messageTargetGeometry(
      snapshot.messageId,
      _keysByMessageId,
    );
    if (geometry == null) return;

    final delta = geometry.bottom - snapshot.bottom;
    if (delta.abs() <= _jumpToTolerance) return;
    final position = scrollController.position;
    final start = (position.pixels + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if ((start - position.pixels).abs() <= _jumpToTolerance) return;
    traceChatJump(
      'tail-follow start anchor=${shortMessageId(snapshot.messageId)} '
      'delta=${formatDouble(delta)} start=${formatDouble(start)} '
      '${formatScrollMetrics(position)}',
    );
    scrollController.jumpTo(start);
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
    if (_jumpButtonFrozenUpdates <= 0) {
      final nextShowJumpToLatest = _shouldShowJumpToLatest();
      if (showJumpToLatest.value != nextShowJumpToLatest) {
        showJumpToLatest.value = nextShowJumpToLatest;
      }
    } else {
      _jumpButtonFrozenUpdates--;
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
    Map<String, GlobalKey> keysByMessageId,
  ) {
    final messageWindowChanged = !_hasSameMessageIds(messages);
    if (!identical(_messages, messages)) {
      _messages = messages;
      _messagesById = {
        for (final message in messages) message.messageId: message,
      };
      _renderedMessageIds.removeWhere((id) => !_messagesById.containsKey(id));
    }
    if (messageWindowChanged) {
      _freezeJumpButton();
    }
    _keysByMessageId = keysByMessageId;
  }

  bool _hasSameMessageIds(List<MessageItem> messages) {
    if (identical(_messages, messages)) return true;
    if (_messages.length != messages.length) return false;
    for (var i = 0; i < messages.length; i++) {
      if (_messages[i].messageId != messages[i].messageId) return false;
    }
    return true;
  }

  void _freezeJumpButton() {
    if (_disposed) return;
    _jumpButtonFrozenUpdates = _jumpButtonFreezeUpdateCount;
  }

  void _clearJumpButtonFreeze() {
    _jumpButtonFrozenUpdates = 0;
  }

  Iterable<String> _currentRenderedMessageIds() sync* {
    for (final messageId in _renderedMessageIds) {
      if (_keysByMessageId[messageId]?.currentContext != null) {
        yield messageId;
      }
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
    final object = _viewportKey?.currentContext?.findRenderObject();
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
      final viewportDimension = scrollController.position.viewportDimension;
      final focusY = viewportDimension * messageFocusAnchor;
      final unreadY = viewportDimension * unreadSeparatorAnchor;
      traceChatJump(
        '$phase $step target=${shortMessageId(messageId)} '
        'rendered=${geometry != null} '
        '${geometry?.format() ?? ''} '
        'focusY=${formatDouble(focusY)} '
        'topDelta=${formatDouble(
          geometry == null ? null : geometry.top - focusY,
        )} '
        'unreadY=${formatDouble(unreadY)} '
        'bottomDelta=${formatDouble(
          geometry == null ? null : geometry.bottom - unreadY,
        )} '
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

  void _traceTargetAfterRestore(_ChatRestoreRequest request) {
    final traceTargetMessageId = request.traceTargetMessageId;
    if (traceTargetMessageId == null) return;
    _traceTargetAfterLayout(
      'restore-anchor-after',
      traceTargetMessageId,
      request.keysByMessageId,
    );
  }
}

class _TailFollowAnchorSnapshot {
  const _TailFollowAnchorSnapshot({
    required this.messageId,
    required this.bottom,
  });

  final String messageId;
  final double bottom;
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
    required this.hasCenteredAnchor,
    this.centerMessageId,
    this.animatedMessageId,
    this.animatedRestoreDirection,
    this.animatedRestoreComplete,
    this.traceTargetMessageId,
  });

  final List<MessageItem> messages;
  final Map<String, GlobalKey> keysByMessageId;
  final bool reset;
  final bool isLatest;
  final bool animated;
  final bool hasCenteredAnchor;
  final String? centerMessageId;
  final String? animatedMessageId;
  final ChatScrollRestoreDirection? animatedRestoreDirection;
  final VoidCallback? animatedRestoreComplete;
  final String? traceTargetMessageId;
}
