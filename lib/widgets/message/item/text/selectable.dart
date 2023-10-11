// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: avoid-unused-parameters

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide SelectableRegionState;
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

const Set<PointerDeviceKind> _kLongPressSelectionDevices = <PointerDeviceKind>{
  PointerDeviceKind.touch,
  PointerDeviceKind.stylus,
  PointerDeviceKind.invertedStylus,
};

typedef SelectableRegionContextMenuBuilder = Widget Function(
  BuildContext context,
  SelectableRegionState selectableRegionState,
);

class SelectableRegion extends StatefulWidget {
  const SelectableRegion({
    super.key,
    this.contextMenuBuilder,
    required this.focusNode,
    required this.selectionControls,
    required this.child,
    this.magnifierConfiguration = TextMagnifierConfiguration.disabled,
    this.onSelectionChanged,
  });

  final TextMagnifierConfiguration magnifierConfiguration;

  final FocusNode focusNode;

  final Widget child;

  final SelectableRegionContextMenuBuilder? contextMenuBuilder;

  final TextSelectionControls selectionControls;

  final ValueChanged<SelectedContent?>? onSelectionChanged;

  static List<ContextMenuButtonItem> getSelectableButtonItems({
    required SelectionGeometry selectionGeometry,
    required VoidCallback onCopy,
    required VoidCallback onSelectAll,
  }) {
    final canCopy = selectionGeometry.status == SelectionStatus.uncollapsed;
    final canSelectAll = selectionGeometry.hasContent;

    return <ContextMenuButtonItem>[
      if (canCopy)
        ContextMenuButtonItem(
          onPressed: onCopy,
          type: ContextMenuButtonType.copy,
        ),
      if (canSelectAll)
        ContextMenuButtonItem(
          onPressed: onSelectAll,
          type: ContextMenuButtonType.selectAll,
        ),
    ];
  }

  @override
  State<StatefulWidget> createState() => SelectableRegionState();
}

/// State for a [SelectableRegion].
class SelectableRegionState extends State<SelectableRegion>
    with TextSelectionDelegate
    implements SelectionRegistrar {
  late final Map<Type, Action<Intent>> _actions = <Type, Action<Intent>>{
    SelectAllTextIntent: _makeOverridable(_SelectAllAction(this)),
    CopySelectionTextIntent: _makeOverridable(_CopySelectionAction(this)),
    ExtendSelectionToNextWordBoundaryOrCaretLocationIntent: _makeOverridable(
        _GranularlyExtendSelectionAction<
                ExtendSelectionToNextWordBoundaryOrCaretLocationIntent>(this,
            granularity: TextGranularity.word)),
    ExpandSelectionToDocumentBoundaryIntent: _makeOverridable(
        _GranularlyExtendSelectionAction<
                ExpandSelectionToDocumentBoundaryIntent>(this,
            granularity: TextGranularity.document)),
    ExpandSelectionToLineBreakIntent: _makeOverridable(
        _GranularlyExtendSelectionAction<ExpandSelectionToLineBreakIntent>(this,
            granularity: TextGranularity.line)),
    ExtendSelectionByCharacterIntent: _makeOverridable(
        _GranularlyExtendCaretSelectionAction<ExtendSelectionByCharacterIntent>(
            this,
            granularity: TextGranularity.character)),
    ExtendSelectionToNextWordBoundaryIntent: _makeOverridable(
        _GranularlyExtendCaretSelectionAction<
                ExtendSelectionToNextWordBoundaryIntent>(this,
            granularity: TextGranularity.word)),
    ExtendSelectionToLineBreakIntent: _makeOverridable(
        _GranularlyExtendCaretSelectionAction<ExtendSelectionToLineBreakIntent>(
            this,
            granularity: TextGranularity.line)),
    ExtendSelectionVerticallyToAdjacentLineIntent: _makeOverridable(
        _DirectionallyExtendCaretSelectionAction<
            ExtendSelectionVerticallyToAdjacentLineIntent>(this)),
    ExtendSelectionToDocumentBoundaryIntent: _makeOverridable(
        _GranularlyExtendCaretSelectionAction<
                ExtendSelectionToDocumentBoundaryIntent>(this,
            granularity: TextGranularity.document)),
  };

  final Map<Type, GestureRecognizerFactory> _gestureRecognizers =
      <Type, GestureRecognizerFactory>{};
  SelectionOverlay? _selectionOverlay;
  final LayerLink _startHandleLayerLink = LayerLink();
  final LayerLink _endHandleLayerLink = LayerLink();
  final LayerLink _toolbarLayerLink = LayerLink();
  final _SelectableRegionContainerDelegate _selectionDelegate =
      _SelectableRegionContainerDelegate();

  // there should only ever be one selectable, which is the SelectionContainer.
  Selectable? /**/ _selectable;

  bool get _hasSelectionOverlayGeometry =>
      _selectionDelegate.value.startSelectionPoint != null ||
      _selectionDelegate.value.endSelectionPoint != null;

  Orientation? _lastOrientation;
  SelectedContent? _lastSelectedContent;

  /// {@macro flutter.rendering.RenderEditable.lastSecondaryTapDownPosition}
  Offset? lastSecondaryTapDownPosition;

  /// The [SelectionOverlay] that is currently visible on the screen.
  ///
  /// Can be null if there is no visible [SelectionOverlay].
  @visibleForTesting
  SelectionOverlay? get selectionOverlay => _selectionOverlay;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleFocusChanged);
    _initMouseGestureRecognizer();
    _initTouchGestureRecognizer();
    // Taps and right clicks.
    _gestureRecognizers[TapGestureRecognizer] =
        GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
      () => TapGestureRecognizer(debugOwner: this),
      (TapGestureRecognizer instance) {
        instance.onTapUp = (TapUpDetails details) {
          if (defaultTargetPlatform == TargetPlatform.iOS &&
              _positionIsOnActiveSelection(
                  globalPosition: details.globalPosition)) {
            // On iOS when the tap occurs on the previous selection, instead of
            // moving the selection, the context menu will be toggled.
            final toolbarIsVisible =
                _selectionOverlay?.toolbarIsVisible ?? false;
            if (toolbarIsVisible) {
              hideToolbar(false);
            } else {
              _showToolbar(location: details.globalPosition);
            }
          } else {
            hideToolbar();
            _collapseSelectionAt(offset: details.globalPosition);
          }
        };
        // ..onSecondaryTapDown = _handleRightClickDown;
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        break;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return;
    }

    // Hide the text selection toolbar on mobile when orientation changes.
    final orientation = MediaQuery.orientationOf(context);
    if (_lastOrientation == null) {
      _lastOrientation = orientation;
      return;
    }
    if (orientation != _lastOrientation) {
      _lastOrientation = orientation;
      hideToolbar(defaultTargetPlatform == TargetPlatform.android);
    }
  }

  @override
  void didUpdateWidget(SelectableRegion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocusChanged);
      widget.focusNode.addListener(_handleFocusChanged);
      if (widget.focusNode.hasFocus != oldWidget.focusNode.hasFocus) {
        _handleFocusChanged();
      }
    }
  }

  Action<T> _makeOverridable<T extends Intent>(Action<T> defaultAction) =>
      Action<T>.overridable(context: context, defaultAction: defaultAction);

  void _handleFocusChanged() {
    if (!widget.focusNode.hasFocus) {
      if (kIsWeb) {
        PlatformSelectableRegionContextMenu.detach(_selectionDelegate);
      }
      _clearSelection();
    }
    if (kIsWeb) {
      PlatformSelectableRegionContextMenu.attach(_selectionDelegate);
    }
  }

  void _updateSelectionStatus() {
    // final TextSelection selection;
    // final geometry = _selectionDelegate.value;
    // switch (geometry.status) {
    //   case SelectionStatus.uncollapsed:
    //   case SelectionStatus.collapsed:
    //     selection = const TextSelection(baseOffset: 0, extentOffset: 1);
    //   case SelectionStatus.none:
    //     selection = const TextSelection.collapsed(offset: 1);
    // }
    // textEditingValue = TextEditingValue(text: '__', selection: selection);
    if (_hasSelectionOverlayGeometry) {
      _updateSelectionOverlay();
    } else {
      _selectionOverlay?.dispose();
      _selectionOverlay = null;
    }
  }

  // gestures.

  // Converts the details.consecutiveTapCount from a TapAndDrag*Details object,
  // which can grow to be infinitely large, to a value between 1 and the supported
  // max consecutive tap count. The value that the raw count is converted to is
  // based on the default observed behavior on the native platforms.
  //
  // This method should be used in all instances when details.consecutiveTapCount
  // would be used.
  static int _getEffectiveConsecutiveTapCount(int rawCount) {
    const maxConsecutiveTap = 2;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
        // From observation, these platforms reset their tap count to 0 when
        // the number of consecutive taps exceeds the max consecutive tap supported.
        // For example on Debian Linux with GTK, when going past a triple click,
        // on the fourth click the selection is moved to the precise click
        // position, on the fifth click the word at the position is selected, and
        // on the sixth click the paragraph at the position is selected.
        return rawCount <= maxConsecutiveTap
            ? rawCount
            : (rawCount % maxConsecutiveTap == 0
                ? maxConsecutiveTap
                : rawCount % maxConsecutiveTap);
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        // From observation, these platforms either hold their tap count at the max
        // consecutive tap supported. For example on macOS, when going past a triple
        // click, the selection should be retained at the paragraph that was first
        // selected on triple click.
        return min(rawCount, maxConsecutiveTap);
    }
  }

  void _initMouseGestureRecognizer() {
    _gestureRecognizers[TapAndPanGestureRecognizer] =
        GestureRecognizerFactoryWithHandlers<TapAndPanGestureRecognizer>(
      () => TapAndPanGestureRecognizer(
          debugOwner: this,
          supportedDevices: <PointerDeviceKind>{PointerDeviceKind.mouse}),
      (TapAndPanGestureRecognizer instance) {
        instance
          ..onTapDown = _startNewMouseSelectionGesture
          ..onTapUp = _handleMouseTapUp
          ..onDragStart = _handleMouseDragStart
          ..onDragUpdate = _handleMouseDragUpdate
          ..onDragEnd = _handleMouseDragEnd
          ..onCancel = _clearSelection
          ..dragStartBehavior = DragStartBehavior.down;
      },
    );
  }

  void _initTouchGestureRecognizer() {
    _gestureRecognizers[LongPressGestureRecognizer] =
        GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
      () => LongPressGestureRecognizer(
          debugOwner: this, supportedDevices: _kLongPressSelectionDevices),
      (LongPressGestureRecognizer instance) {
        instance
          ..onLongPressStart = _handleTouchLongPressStart
          ..onLongPressMoveUpdate = _handleTouchLongPressMoveUpdate
          ..onLongPressEnd = _handleTouchLongPressEnd;
      },
    );
  }

  void _startNewMouseSelectionGesture(TapDragDownDetails details) {
    switch (_getEffectiveConsecutiveTapCount(details.consecutiveTapCount)) {
      case 1:
        widget.focusNode.requestFocus();
        hideToolbar();
        switch (defaultTargetPlatform) {
          case TargetPlatform.android:
          case TargetPlatform.fuchsia:
          case TargetPlatform.iOS:
            // On mobile platforms the selection is set on tap up.
            break;
          case TargetPlatform.macOS:
          case TargetPlatform.linux:
          case TargetPlatform.windows:
            _collapseSelectionAt(offset: details.globalPosition);
        }
      case 2:
        _selectWordAt(offset: details.globalPosition);
    }
    _updateSelectedContentIfNeeded();
  }

  void _handleMouseDragStart(TapDragStartDetails details) {
    switch (_getEffectiveConsecutiveTapCount(details.consecutiveTapCount)) {
      case 1:
        _selectStartTo(offset: details.globalPosition);
    }
    _updateSelectedContentIfNeeded();
  }

  void _handleMouseDragUpdate(TapDragUpdateDetails details) {
    switch (_getEffectiveConsecutiveTapCount(details.consecutiveTapCount)) {
      case 1:
        _selectEndTo(offset: details.globalPosition, continuous: true);
      case 2:
        _selectEndTo(
            offset: details.globalPosition,
            continuous: true,
            textGranularity: TextGranularity.word);
    }
    _updateSelectedContentIfNeeded();
  }

  void _handleMouseDragEnd(TapDragEndDetails details) {
    _finalizeSelection();
    _updateSelectedContentIfNeeded();
  }

  void _handleMouseTapUp(TapDragUpDetails details) {
    switch (_getEffectiveConsecutiveTapCount(details.consecutiveTapCount)) {
      case 1:
        switch (defaultTargetPlatform) {
          case TargetPlatform.android:
          case TargetPlatform.fuchsia:
          case TargetPlatform.iOS:
            _collapseSelectionAt(offset: details.globalPosition);
          case TargetPlatform.macOS:
          case TargetPlatform.linux:
          case TargetPlatform.windows:
            // On desktop platforms the selection is set on tap down.
            break;
        }
    }
    _updateSelectedContentIfNeeded();
  }

  void _updateSelectedContentIfNeeded() {
    if (_lastSelectedContent?.plainText !=
        _selectable?.getSelectedContent()?.plainText) {
      _lastSelectedContent = _selectable?.getSelectedContent();
      widget.onSelectionChanged?.call(_lastSelectedContent);
    }
  }

  void _handleTouchLongPressStart(LongPressStartDetails details) {
    HapticFeedback.selectionClick();
    widget.focusNode.requestFocus();
    _selectWordAt(offset: details.globalPosition);
    // Platforms besides Android will show the text selection handles when
    // the long press is initiated. Android shows the text selection handles when
    // the long press has ended, usually after a pointer up event is received.
    if (defaultTargetPlatform != TargetPlatform.android) {
      _showHandles();
    }
    _updateSelectedContentIfNeeded();
  }

  void _handleTouchLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    _selectEndTo(
        offset: details.globalPosition, textGranularity: TextGranularity.word);
    _updateSelectedContentIfNeeded();
  }

  void _handleTouchLongPressEnd(LongPressEndDetails details) {
    _finalizeSelection();
    _updateSelectedContentIfNeeded();
    _showToolbar();
    if (defaultTargetPlatform == TargetPlatform.android) {
      _showHandles();
    }
  }

  bool _positionIsOnActiveSelection({required Offset globalPosition}) {
    for (final selectionRect in _selectionDelegate.value.selectionRects) {
      final transform = _selectable!.getTransformTo(null);
      final globalRect = MatrixUtils.transformRect(transform, selectionRect);
      if (globalRect.contains(globalPosition)) {
        return true;
      }
    }
    return false;
  }

  // Selection update helper methods.

  Offset? _selectionEndPosition;

  bool get _userDraggingSelectionEnd => _selectionEndPosition != null;
  bool _scheduledSelectionEndEdgeUpdate = false;

  /// Sends end [SelectionEdgeUpdateEvent] to the selectable subtree.
  ///
  /// If the selectable subtree returns a [SelectionResult.pending], this method
  /// continues to send [SelectionEdgeUpdateEvent]s every frame until the result
  /// is not pending or users end their gestures.
  void _triggerSelectionEndEdgeUpdate({TextGranularity? textGranularity}) {
    // This method can be called when the drag is not in progress. This can
    // happen if the child scrollable returns SelectionResult.pending, and
    // the selection area scheduled a selection update for the next frame, but
    // the drag is lifted before the scheduled selection update is run.
    if (_scheduledSelectionEndEdgeUpdate || !_userDraggingSelectionEnd) {
      return;
    }
    if (_selectable?.dispatchSelectionEvent(SelectionEdgeUpdateEvent.forEnd(
            globalPosition: _selectionEndPosition!,
            granularity: textGranularity)) ==
        SelectionResult.pending) {
      _scheduledSelectionEndEdgeUpdate = true;
      SchedulerBinding.instance.addPostFrameCallback((Duration timeStamp) {
        if (!_scheduledSelectionEndEdgeUpdate) {
          return;
        }
        _scheduledSelectionEndEdgeUpdate = false;
        _triggerSelectionEndEdgeUpdate(textGranularity: textGranularity);
      });
      return;
    }
  }

  void _onAnyDragEnd(DragEndDetails details) {
    if (widget.selectionControls is! TextSelectionHandleControls) {
      _selectionOverlay!.hideMagnifier();
      _selectionOverlay!.showToolbar();
    } else {
      _selectionOverlay!.hideMagnifier();
      _selectionOverlay!.showToolbar(
        context: context,
        contextMenuBuilder: (BuildContext context) =>
            widget.contextMenuBuilder!(context, this),
      );
    }
    _stopSelectionStartEdgeUpdate();
    _stopSelectionEndEdgeUpdate();
    _updateSelectedContentIfNeeded();
  }

  void _stopSelectionEndEdgeUpdate() {
    _scheduledSelectionEndEdgeUpdate = false;
    _selectionEndPosition = null;
  }

  Offset? _selectionStartPosition;

  bool get _userDraggingSelectionStart => _selectionStartPosition != null;
  bool _scheduledSelectionStartEdgeUpdate = false;

  /// Sends start [SelectionEdgeUpdateEvent] to the selectable subtree.
  ///
  /// If the selectable subtree returns a [SelectionResult.pending], this method
  /// continues to send [SelectionEdgeUpdateEvent]s every frame until the result
  /// is not pending or users end their gestures.
  void _triggerSelectionStartEdgeUpdate({TextGranularity? textGranularity}) {
    // This method can be called when the drag is not in progress. This can
    // happen if the child scrollable returns SelectionResult.pending, and
    // the selection area scheduled a selection update for the next frame, but
    // the drag is lifted before the scheduled selection update is run.
    if (_scheduledSelectionStartEdgeUpdate || !_userDraggingSelectionStart) {
      return;
    }
    if (_selectable?.dispatchSelectionEvent(SelectionEdgeUpdateEvent.forStart(
            globalPosition: _selectionStartPosition!,
            granularity: textGranularity)) ==
        SelectionResult.pending) {
      _scheduledSelectionStartEdgeUpdate = true;
      SchedulerBinding.instance.addPostFrameCallback((Duration timeStamp) {
        if (!_scheduledSelectionStartEdgeUpdate) {
          return;
        }
        _scheduledSelectionStartEdgeUpdate = false;
        _triggerSelectionStartEdgeUpdate(textGranularity: textGranularity);
      });
      return;
    }
  }

  void _stopSelectionStartEdgeUpdate() {
    _scheduledSelectionStartEdgeUpdate = false;
    _selectionEndPosition = null;
  }

  // SelectionOverlay helper methods.

  late Offset _selectionStartHandleDragPosition;
  late Offset _selectionEndHandleDragPosition;

  void _handleSelectionStartHandleDragStart(DragStartDetails details) {
    assert(_selectionDelegate.value.startSelectionPoint != null);

    final localPosition =
        _selectionDelegate.value.startSelectionPoint!.localPosition;
    final globalTransform = _selectable!.getTransformTo(null);
    _selectionStartHandleDragPosition =
        MatrixUtils.transformPoint(globalTransform, localPosition);

    _selectionOverlay!.showMagnifier(_buildInfoForMagnifier(
      details.globalPosition,
      _selectionDelegate.value.startSelectionPoint!,
    ));
    _updateSelectedContentIfNeeded();
  }

  void _handleSelectionStartHandleDragUpdate(DragUpdateDetails details) {
    _selectionStartHandleDragPosition =
        _selectionStartHandleDragPosition + details.delta;
    // The value corresponds to the paint origin of the selection handle.
    // Offset it to the center of the line to make it feel more natural.
    _selectionStartPosition = _selectionStartHandleDragPosition -
        Offset(0, _selectionDelegate.value.startSelectionPoint!.lineHeight / 2);
    _triggerSelectionStartEdgeUpdate();

    _selectionOverlay!.updateMagnifier(_buildInfoForMagnifier(
      details.globalPosition,
      _selectionDelegate.value.startSelectionPoint!,
    ));
    _updateSelectedContentIfNeeded();
  }

  void _handleSelectionEndHandleDragStart(DragStartDetails details) {
    assert(_selectionDelegate.value.endSelectionPoint != null);
    final localPosition =
        _selectionDelegate.value.endSelectionPoint!.localPosition;
    final globalTransform = _selectable!.getTransformTo(null);
    _selectionEndHandleDragPosition =
        MatrixUtils.transformPoint(globalTransform, localPosition);

    _selectionOverlay!.showMagnifier(_buildInfoForMagnifier(
      details.globalPosition,
      _selectionDelegate.value.endSelectionPoint!,
    ));
    _updateSelectedContentIfNeeded();
  }

  void _handleSelectionEndHandleDragUpdate(DragUpdateDetails details) {
    _selectionEndHandleDragPosition =
        _selectionEndHandleDragPosition + details.delta;
    // The value corresponds to the paint origin of the selection handle.
    // Offset it to the center of the line to make it feel more natural.
    _selectionEndPosition = _selectionEndHandleDragPosition -
        Offset(0, _selectionDelegate.value.endSelectionPoint!.lineHeight / 2);
    _triggerSelectionEndEdgeUpdate();

    _selectionOverlay!.updateMagnifier(_buildInfoForMagnifier(
      details.globalPosition,
      _selectionDelegate.value.endSelectionPoint!,
    ));
    _updateSelectedContentIfNeeded();
  }

  MagnifierInfo _buildInfoForMagnifier(
      Offset globalGesturePosition, SelectionPoint selectionPoint) {
    final globalTransform = _selectable!.getTransformTo(null).getTranslation();
    final globalTransformAsOffset =
        Offset(globalTransform.x, globalTransform.y);
    final globalSelectionPointPosition =
        selectionPoint.localPosition + globalTransformAsOffset;
    final caretRect = Rect.fromLTWH(
        globalSelectionPointPosition.dx,
        globalSelectionPointPosition.dy - selectionPoint.lineHeight,
        0,
        selectionPoint.lineHeight);

    return MagnifierInfo(
      globalGesturePosition: globalGesturePosition,
      caretRect: caretRect,
      fieldBounds: globalTransformAsOffset & _selectable!.size,
      currentLineBoundaries: globalTransformAsOffset & _selectable!.size,
    );
  }

  void _createSelectionOverlay() {
    assert(_hasSelectionOverlayGeometry);
    if (_selectionOverlay != null) {
      return;
    }
    final start = _selectionDelegate.value.startSelectionPoint;
    final end = _selectionDelegate.value.endSelectionPoint;
    _selectionOverlay = SelectionOverlay(
        context: context,
        debugRequiredFor: widget,
        startHandleType: start?.handleType ?? TextSelectionHandleType.left,
        lineHeightAtStart: start?.lineHeight ?? end!.lineHeight,
        onStartHandleDragStart: _handleSelectionStartHandleDragStart,
        onStartHandleDragUpdate: _handleSelectionStartHandleDragUpdate,
        onStartHandleDragEnd: _onAnyDragEnd,
        endHandleType: end?.handleType ?? TextSelectionHandleType.right,
        lineHeightAtEnd: end?.lineHeight ?? start!.lineHeight,
        onEndHandleDragStart: _handleSelectionEndHandleDragStart,
        onEndHandleDragUpdate: _handleSelectionEndHandleDragUpdate,
        onEndHandleDragEnd: _onAnyDragEnd,
        selectionEndpoints: selectionEndpoints,
        selectionControls: widget.selectionControls,
        selectionDelegate: this,
        clipboardStatus: null,
        startHandleLayerLink: _startHandleLayerLink,
        endHandleLayerLink: _endHandleLayerLink,
        toolbarLayerLink: _toolbarLayerLink,
        magnifierConfiguration: widget.magnifierConfiguration);
  }

  void _updateSelectionOverlay() {
    if (_selectionOverlay == null) {
      return;
    }
    assert(_hasSelectionOverlayGeometry);
    final start = _selectionDelegate.value.startSelectionPoint;
    final end = _selectionDelegate.value.endSelectionPoint;
    _selectionOverlay!
      ..startHandleType = start?.handleType ?? TextSelectionHandleType.left
      ..lineHeightAtStart = start?.lineHeight ?? end!.lineHeight
      ..endHandleType = end?.handleType ?? TextSelectionHandleType.right
      ..lineHeightAtEnd = end?.lineHeight ?? start!.lineHeight
      ..selectionEndpoints = selectionEndpoints;
  }

  /// Shows the selection handles.
  ///
  /// Returns true if the handles are shown, false if the handles can't be
  /// shown.
  bool _showHandles() {
    if (_selectionOverlay != null) {
      _selectionOverlay!.showHandles();
      return true;
    }

    if (!_hasSelectionOverlayGeometry) {
      return false;
    }

    _createSelectionOverlay();
    _selectionOverlay!.showHandles();
    return true;
  }

  /// Shows the text selection toolbar.
  ///
  /// If the parameter `location` is set, the toolbar will be shown at the
  /// location. Otherwise, the toolbar location will be calculated based on the
  /// handles' locations. The `location` is in the coordinates system of the
  /// [Overlay].
  ///
  /// Returns true if the toolbar is shown, false if the toolbar can't be shown.
  bool _showToolbar({Offset? location}) {
    if (!_hasSelectionOverlayGeometry && _selectionOverlay == null) {
      return false;
    }

    // Web is using native dom elements to enable clipboard functionality of the
    // context menu: copy, paste, select, cut. It might also provide additional
    // functionality depending on the browser (such as translate). Due to this,
    // we should not show a Flutter toolbar for the editable text elements
    // unless the browser's context menu is explicitly disabled.
    if (kIsWeb && BrowserContextMenu.enabled) {
      return false;
    }

    if (_selectionOverlay == null) {
      _createSelectionOverlay();
    }

    _selectionOverlay!.toolbarLocation = location;
    if (widget.selectionControls is! TextSelectionHandleControls) {
      _selectionOverlay!.showToolbar();
      return true;
    }

    _selectionOverlay!.hideToolbar();

    _selectionOverlay!.showToolbar(
      context: context,
      contextMenuBuilder: (BuildContext context) =>
          widget.contextMenuBuilder!(context, this),
    );
    return true;
  }

  /// Sets or updates selection end edge to the `offset` location.
  ///
  /// A selection always contains a select start edge and selection end edge.
  /// They can be created by calling both [_selectStartTo] and [_selectEndTo], or
  /// use other selection APIs, such as [_selectWordAt] or [selectAll].
  ///
  /// This method sets or updates the selection end edge by sending
  /// [SelectionEdgeUpdateEvent]s to the child [Selectable]s.
  ///
  /// If `continuous` is set to true and the update causes scrolling, the
  /// method will continue sending the same [SelectionEdgeUpdateEvent]s to the
  /// child [Selectable]s every frame until the scrolling finishes or a
  /// [_finalizeSelection] is called.
  ///
  /// The `continuous` argument defaults to false.
  ///
  /// The `offset` is in global coordinates.
  ///
  /// Provide the `textGranularity` if the selection should not move by the default
  /// [TextGranularity.character]. Only [TextGranularity.character] and
  /// [TextGranularity.word] are currently supported.
  ///
  /// See also:
  ///  * [_selectStartTo], which sets or updates selection start edge.
  ///  * [_finalizeSelection], which stops the `continuous` updates.
  ///  * [_clearSelection], which clears the ongoing selection.
  ///  * [_selectWordAt], which selects a whole word at the location.
  ///  * [_collapseSelectionAt], which collapses the selection at the location.
  ///  * [selectAll], which selects the entire content.
  void _selectEndTo(
      {required Offset offset,
      bool continuous = false,
      TextGranularity? textGranularity}) {
    if (!continuous) {
      _selectable?.dispatchSelectionEvent(SelectionEdgeUpdateEvent.forEnd(
          globalPosition: offset, granularity: textGranularity));
      return;
    }
    if (_selectionEndPosition != offset) {
      _selectionEndPosition = offset;
      _triggerSelectionEndEdgeUpdate(textGranularity: textGranularity);
    }
  }

  /// Sets or updates selection start edge to the `offset` location.
  ///
  /// A selection always contains a select start edge and selection end edge.
  /// They can be created by calling both [_selectStartTo] and [_selectEndTo], or
  /// use other selection APIs, such as [_selectWordAt] or [selectAll].
  ///
  /// This method sets or updates the selection start edge by sending
  /// [SelectionEdgeUpdateEvent]s to the child [Selectable]s.
  ///
  /// If `continuous` is set to true and the update causes scrolling, the
  /// method will continue sending the same [SelectionEdgeUpdateEvent]s to the
  /// child [Selectable]s every frame until the scrolling finishes or a
  /// [_finalizeSelection] is called.
  ///
  /// The `continuous` argument defaults to false.
  ///
  /// The `offset` is in global coordinates.
  ///
  /// Provide the `textGranularity` if the selection should not move by the default
  /// [TextGranularity.character]. Only [TextGranularity.character] and
  /// [TextGranularity.word] are currently supported.
  ///
  /// See also:
  ///  * [_selectEndTo], which sets or updates selection end edge.
  ///  * [_finalizeSelection], which stops the `continuous` updates.
  ///  * [_clearSelection], which clears the ongoing selection.
  ///  * [_selectWordAt], which selects a whole word at the location.
  ///  * [_collapseSelectionAt], which collapses the selection at the location.
  ///  * [selectAll], which selects the entire content.
  void _selectStartTo(
      {required Offset offset,
      bool continuous = false,
      TextGranularity? textGranularity}) {
    if (!continuous) {
      _selectable?.dispatchSelectionEvent(SelectionEdgeUpdateEvent.forStart(
          globalPosition: offset, granularity: textGranularity));
      return;
    }
    if (_selectionStartPosition != offset) {
      _selectionStartPosition = offset;
      _triggerSelectionStartEdgeUpdate(textGranularity: textGranularity);
    }
  }

  /// Collapses the selection at the given `offset` location.
  ///
  /// See also:
  ///  * [_selectStartTo], which sets or updates selection start edge.
  ///  * [_selectEndTo], which sets or updates selection end edge.
  ///  * [_finalizeSelection], which stops the `continuous` updates.
  ///  * [_clearSelection], which clears the ongoing selection.
  ///  * [_selectWordAt], which selects a whole word at the location.
  ///  * [selectAll], which selects the entire content.
  void _collapseSelectionAt({required Offset offset}) {
    _selectStartTo(offset: offset);
    _selectEndTo(offset: offset);
  }

  /// Selects a whole word at the `offset` location.
  ///
  /// If the whole word is already in the current selection, selection won't
  /// change. One call [_clearSelection] first if the selection needs to be
  /// updated even if the word is already covered by the current selection.
  ///
  /// One can also use [_selectEndTo] or [_selectStartTo] to adjust the selection
  /// edges after calling this method.
  ///
  /// See also:
  ///  * [_selectStartTo], which sets or updates selection start edge.
  ///  * [_selectEndTo], which sets or updates selection end edge.
  ///  * [_finalizeSelection], which stops the `continuous` updates.
  ///  * [_clearSelection], which clears the ongoing selection.
  ///  * [_collapseSelectionAt], which collapses the selection at the location.
  ///  * [selectAll], which selects the entire content.
  void _selectWordAt({required Offset offset}) {
    // There may be other selection ongoing.
    _finalizeSelection();
    _selectable?.dispatchSelectionEvent(
        SelectWordSelectionEvent(globalPosition: offset));
  }

  /// Stops any ongoing selection updates.
  ///
  /// This method is different from [_clearSelection] that it does not remove
  /// the current selection. It only stops the continuous updates.
  ///
  /// A continuous update can happen as result of calling [_selectStartTo] or
  /// [_selectEndTo] with `continuous` sets to true which causes a [Selectable]
  /// to scroll. Calling this method will stop the update as well as the
  /// scrolling.
  void _finalizeSelection() {
    _stopSelectionEndEdgeUpdate();
    _stopSelectionStartEdgeUpdate();
  }

  /// Removes the ongoing selection.
  void _clearSelection() {
    _finalizeSelection();
    _directionalHorizontalBaseline = null;
    _adjustingSelectionEnd = null;
    _selectable?.dispatchSelectionEvent(const ClearSelectionEvent());
    _updateSelectedContentIfNeeded();
  }

  Future<void> _copy() async {
    final data = _selectable?.getSelectedContent();
    if (data == null) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: data.plainText));
  }

  /// {@macro flutter.widgets.EditableText.getAnchors}
  ///
  /// See also:
  ///
  ///  * [contextMenuButtonItems], which provides the [ContextMenuButtonItem]s
  ///    for the default context menu buttons.
  TextSelectionToolbarAnchors get contextMenuAnchors {
    if (lastSecondaryTapDownPosition != null) {
      return TextSelectionToolbarAnchors(
        primaryAnchor: lastSecondaryTapDownPosition!,
      );
    }
    final renderBox = context.findRenderObject()! as RenderBox;
    return TextSelectionToolbarAnchors.fromSelection(
      renderBox: renderBox,
      startGlyphHeight: startGlyphHeight,
      endGlyphHeight: endGlyphHeight,
      selectionEndpoints: selectionEndpoints,
    );
  }

  bool? _adjustingSelectionEnd;

  bool _determineIsAdjustingSelectionEnd(bool forward) {
    if (_adjustingSelectionEnd != null) {
      return _adjustingSelectionEnd!;
    }
    final bool isReversed;
    final start = _selectionDelegate.value.startSelectionPoint!;
    final end = _selectionDelegate.value.endSelectionPoint!;
    if (start.localPosition.dy > end.localPosition.dy) {
      isReversed = true;
    } else if (start.localPosition.dy < end.localPosition.dy) {
      isReversed = false;
    } else {
      isReversed = start.localPosition.dx > end.localPosition.dx;
    }
    // Always move the selection edge that increases the selection range.
    return _adjustingSelectionEnd = forward != isReversed;
  }

  void _granularlyExtendSelection(TextGranularity granularity, bool forward) {
    _directionalHorizontalBaseline = null;
    if (!_selectionDelegate.value.hasSelection) {
      return;
    }
    _selectable?.dispatchSelectionEvent(
      GranularlyExtendSelectionEvent(
        forward: forward,
        isEnd: _determineIsAdjustingSelectionEnd(forward),
        granularity: granularity,
      ),
    );
    _updateSelectedContentIfNeeded();
  }

  double? _directionalHorizontalBaseline;

  void _directionallyExtendSelection(bool forward) {
    if (!_selectionDelegate.value.hasSelection) {
      return;
    }
    final adjustingSelectionExtend = _determineIsAdjustingSelectionEnd(forward);
    final baseLinePoint = adjustingSelectionExtend
        ? _selectionDelegate.value.endSelectionPoint!
        : _selectionDelegate.value.startSelectionPoint!;
    _directionalHorizontalBaseline ??= baseLinePoint.localPosition.dx;
    final globalSelectionPointOffset = MatrixUtils.transformPoint(
        context.findRenderObject()!.getTransformTo(null),
        Offset(_directionalHorizontalBaseline!, 0));
    _selectable?.dispatchSelectionEvent(
      DirectionallyExtendSelectionEvent(
        isEnd: _adjustingSelectionEnd!,
        direction: forward
            ? SelectionExtendDirection.nextLine
            : SelectionExtendDirection.previousLine,
        dx: globalSelectionPointOffset.dx,
      ),
    );
    _updateSelectedContentIfNeeded();
  }

  // [TextSelectionDelegate] overrides.

  /// Returns the [ContextMenuButtonItem]s representing the buttons in this
  /// platform's default selection menu.
  ///
  /// See also:
  ///
  /// * [SelectableRegion.getSelectableButtonItems], which performs a similar role,
  ///   but for any selectable text, not just specifically SelectableRegion.
  /// * [EditableTextState.contextMenuButtonItems], which performs a similar role
  ///   but for content that is not just selectable but also editable.
  /// * [contextMenuAnchors], which provides the anchor points for the default
  ///   context menu.
  /// * [AdaptiveTextSelectionToolbar], which builds the toolbar itself, and can
  ///   take a list of [ContextMenuButtonItem]s with
  ///   [AdaptiveTextSelectionToolbar.buttonItems].
  /// * [AdaptiveTextSelectionToolbar.getAdaptiveButtons], which builds the
  ///   button Widgets for the current platform given [ContextMenuButtonItem]s.
  List<ContextMenuButtonItem> get contextMenuButtonItems =>
      SelectableRegion.getSelectableButtonItems(
        selectionGeometry: _selectionDelegate.value,
        onCopy: () {
          _copy();

          // In Android copy should clear the selection.
          switch (defaultTargetPlatform) {
            case TargetPlatform.android:
            case TargetPlatform.fuchsia:
              _clearSelection();
            case TargetPlatform.iOS:
              hideToolbar(false);
            case TargetPlatform.linux:
            case TargetPlatform.macOS:
            case TargetPlatform.windows:
              hideToolbar();
          }
        },
        onSelectAll: () {
          switch (defaultTargetPlatform) {
            case TargetPlatform.android:
            case TargetPlatform.iOS:
            case TargetPlatform.fuchsia:
              selectAll(SelectionChangedCause.toolbar);
            case TargetPlatform.linux:
            case TargetPlatform.macOS:
            case TargetPlatform.windows:
              selectAll();
              hideToolbar();
          }
        },
      );

  /// The line height at the start of the current selection.
  double get startGlyphHeight =>
      _selectionDelegate.value.startSelectionPoint!.lineHeight;

  /// The line height at the end of the current selection.
  double get endGlyphHeight =>
      _selectionDelegate.value.endSelectionPoint!.lineHeight;

  /// Returns the local coordinates of the endpoints of the current selection.
  List<TextSelectionPoint> get selectionEndpoints {
    final start = _selectionDelegate.value.startSelectionPoint;
    final end = _selectionDelegate.value.endSelectionPoint;
    late List<TextSelectionPoint> points;
    final startLocalPosition = start?.localPosition ?? end!.localPosition;
    final endLocalPosition = end?.localPosition ?? start!.localPosition;
    if (startLocalPosition.dy > endLocalPosition.dy) {
      points = <TextSelectionPoint>[
        TextSelectionPoint(endLocalPosition, TextDirection.ltr),
        TextSelectionPoint(startLocalPosition, TextDirection.ltr),
      ];
    } else {
      points = <TextSelectionPoint>[
        TextSelectionPoint(startLocalPosition, TextDirection.ltr),
        TextSelectionPoint(endLocalPosition, TextDirection.ltr),
      ];
    }
    return points;
  }

  @override
  bool get cutEnabled => false;

  @override
  bool get pasteEnabled => false;

  @override
  void hideToolbar([bool hideHandles = true]) {
    _selectionOverlay?.hideToolbar();
    if (hideHandles) {
      _selectionOverlay?.hideHandles();
    }
  }

  @override
  void selectAll([SelectionChangedCause? cause]) {
    _clearSelection();
    _selectable?.dispatchSelectionEvent(const SelectAllSelectionEvent());
    if (cause == SelectionChangedCause.toolbar) {
      _showToolbar();
      _showHandles();
    }
    _updateSelectedContentIfNeeded();
  }

  @Deprecated(
    'Use `contextMenuBuilder` instead. '
    'This feature was deprecated after v3.3.0-0.5.pre.',
  )
  @override
  void copySelection(SelectionChangedCause cause) {
    _copy();
    _clearSelection();
  }

  @Deprecated(
    'Use `contextMenuBuilder` instead. '
    'This feature was deprecated after v3.3.0-0.5.pre.',
  )
  @override
  TextEditingValue textEditingValue = const TextEditingValue(text: '_');

  Selectable? get selectable => _selectable;

  @Deprecated(
    'Use `contextMenuBuilder` instead. '
    'This feature was deprecated after v3.3.0-0.5.pre.',
  )
  @override
  void bringIntoView(TextPosition position) {
    /* SelectableRegion must be in view at this point. */
  }

  @Deprecated(
    'Use `contextMenuBuilder` instead. '
    'This feature was deprecated after v3.3.0-0.5.pre.',
  )
  @override
  void cutSelection(SelectionChangedCause cause) {
    assert(false);
  }

  @Deprecated(
    'Use `contextMenuBuilder` instead. '
    'This feature was deprecated after v3.3.0-0.5.pre.',
  )
  @override
  void userUpdateTextEditingValue(
      TextEditingValue value, SelectionChangedCause cause) {
    /* SelectableRegion maintains its own state */
  }

  @Deprecated(
    'Use `contextMenuBuilder` instead. '
    'This feature was deprecated after v3.3.0-0.5.pre.',
  )
  @override
  Future<void> pasteText(SelectionChangedCause cause) async {
    assert(false);
  }

  // [SelectionRegistrar] override.

  @override
  void add(Selectable selectable) {
    assert(_selectable == null);
    _selectable = selectable;
    _selectable!.addListener(_updateSelectionStatus);
    _selectable!.pushHandleLayers(_startHandleLayerLink, _endHandleLayerLink);
  }

  @override
  void remove(Selectable selectable) {
    assert(_selectable == selectable);
    _selectable!.removeListener(_updateSelectionStatus);
    _selectable!.pushHandleLayers(null, null);
    _selectable = null;
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChanged);
    _selectable?.removeListener(_updateSelectionStatus);
    _selectable?.pushHandleLayers(null, null);
    _selectionDelegate.dispose();
    // In case dispose was triggered before gesture end, remove the magnifier
    // so it doesn't remain stuck in the overlay forever.
    _selectionOverlay?.hideMagnifier();
    _selectionOverlay?.dispose();
    _selectionOverlay = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasOverlay(context));
    Widget result = SelectionContainer(
      registrar: this,
      delegate: _selectionDelegate,
      child: widget.child,
    );
    if (kIsWeb) {
      result = PlatformSelectableRegionContextMenu(
        child: result,
      );
    }
    return CompositedTransformTarget(
      link: _toolbarLayerLink,
      child: RawGestureDetector(
        gestures: _gestureRecognizers,
        behavior: HitTestBehavior.translucent,
        excludeFromSemantics: true,
        child: Actions(
          actions: _actions,
          child: Focus(
            includeSemantics: false,
            focusNode: widget.focusNode,
            child: result,
          ),
        ),
      ),
    );
  }
}

/// An action that does not override any [Action.overridable] in the subtree.
///
/// If this action is invoked by an [Action.overridable], it will immediately
/// invoke the [Action.overridable] and do nothing else. Otherwise, it will call
/// [invokeAction].
abstract class _NonOverrideAction<T extends Intent> extends ContextAction<T> {
  Object? invokeAction(T intent, [BuildContext? context]);

  @override
  Object? invoke(T intent, [BuildContext? context]) {
    if (callingAction != null) {
      return callingAction!.invoke(intent);
    }
    return invokeAction(intent, context);
  }
}

class _SelectAllAction extends _NonOverrideAction<SelectAllTextIntent> {
  _SelectAllAction(this.state);

  final SelectableRegionState state;

  @override
  void invokeAction(SelectAllTextIntent intent, [BuildContext? context]) {
    state.selectAll(SelectionChangedCause.keyboard);
  }
}

class _CopySelectionAction extends _NonOverrideAction<CopySelectionTextIntent> {
  _CopySelectionAction(this.state);

  final SelectableRegionState state;

  @override
  void invokeAction(CopySelectionTextIntent intent, [BuildContext? context]) {
    state._copy();
  }
}

class _GranularlyExtendSelectionAction<T extends DirectionalTextEditingIntent>
    extends _NonOverrideAction<T> {
  _GranularlyExtendSelectionAction(this.state, {required this.granularity});

  final SelectableRegionState state;
  final TextGranularity granularity;

  @override
  void invokeAction(T intent, [BuildContext? context]) {
    state._granularlyExtendSelection(granularity, intent.forward);
  }
}

class _GranularlyExtendCaretSelectionAction<
    T extends DirectionalCaretMovementIntent> extends _NonOverrideAction<T> {
  _GranularlyExtendCaretSelectionAction(this.state,
      {required this.granularity});

  final SelectableRegionState state;
  final TextGranularity granularity;

  @override
  void invokeAction(T intent, [BuildContext? context]) {
    if (intent.collapseSelection) {
      // Selectable region never collapses selection.
      return;
    }
    state._granularlyExtendSelection(granularity, intent.forward);
  }
}

class _DirectionallyExtendCaretSelectionAction<
    T extends DirectionalCaretMovementIntent> extends _NonOverrideAction<T> {
  _DirectionallyExtendCaretSelectionAction(this.state);

  final SelectableRegionState state;

  @override
  void invokeAction(T intent, [BuildContext? context]) {
    if (intent.collapseSelection) {
      // Selectable region never collapses selection.
      return;
    }
    state._directionallyExtendSelection(intent.forward);
  }
}

class _SelectableRegionContainerDelegate
    extends MultiSelectableSelectionContainerDelegate {
  final Set<Selectable> _hasReceivedStartEvent = <Selectable>{};
  final Set<Selectable> _hasReceivedEndEvent = <Selectable>{};

  Offset? _lastStartEdgeUpdateGlobalPosition;
  Offset? _lastEndEdgeUpdateGlobalPosition;

  @override
  void remove(Selectable selectable) {
    _hasReceivedStartEvent.remove(selectable);
    _hasReceivedEndEvent.remove(selectable);
    super.remove(selectable);
  }

  void _updateLastEdgeEventsFromGeometries() {
    if (currentSelectionStartIndex != -1 &&
        selectables[currentSelectionStartIndex].value.hasSelection) {
      final start = selectables[currentSelectionStartIndex];
      final localStartEdge = start.value.startSelectionPoint!.localPosition +
          Offset(0, -start.value.startSelectionPoint!.lineHeight / 2);
      _lastStartEdgeUpdateGlobalPosition = MatrixUtils.transformPoint(
          start.getTransformTo(null), localStartEdge);
    }
    if (currentSelectionEndIndex != -1 &&
        selectables[currentSelectionEndIndex].value.hasSelection) {
      final end = selectables[currentSelectionEndIndex];
      final localEndEdge = end.value.endSelectionPoint!.localPosition +
          Offset(0, -end.value.endSelectionPoint!.lineHeight / 2);
      _lastEndEdgeUpdateGlobalPosition =
          MatrixUtils.transformPoint(end.getTransformTo(null), localEndEdge);
    }
  }

  @override
  SelectionResult handleSelectAll(SelectAllSelectionEvent event) {
    final result = super.handleSelectAll(event);
    for (final selectable in selectables) {
      _hasReceivedStartEvent.add(selectable);
      _hasReceivedEndEvent.add(selectable);
    }
    // Synthesize last update event so the edge updates continue to work.
    _updateLastEdgeEventsFromGeometries();
    return result;
  }

  /// Selects a word in a selectable at the location
  /// [SelectWordSelectionEvent.globalPosition].
  @override
  SelectionResult handleSelectWord(SelectWordSelectionEvent event) {
    final result = super.handleSelectWord(event);
    if (currentSelectionStartIndex != -1) {
      _hasReceivedStartEvent.add(selectables[currentSelectionStartIndex]);
    }
    if (currentSelectionEndIndex != -1) {
      _hasReceivedEndEvent.add(selectables[currentSelectionEndIndex]);
    }
    _updateLastEdgeEventsFromGeometries();
    return result;
  }

  @override
  SelectionResult handleClearSelection(ClearSelectionEvent event) {
    final result = super.handleClearSelection(event);
    _hasReceivedStartEvent.clear();
    _hasReceivedEndEvent.clear();
    _lastStartEdgeUpdateGlobalPosition = null;
    _lastEndEdgeUpdateGlobalPosition = null;
    return result;
  }

  @override
  SelectionResult handleSelectionEdgeUpdate(SelectionEdgeUpdateEvent event) {
    if (event.type == SelectionEventType.endEdgeUpdate) {
      _lastEndEdgeUpdateGlobalPosition = event.globalPosition;
    } else {
      _lastStartEdgeUpdateGlobalPosition = event.globalPosition;
    }
    return super.handleSelectionEdgeUpdate(event);
  }

  @override
  void dispose() {
    _hasReceivedStartEvent.clear();
    _hasReceivedEndEvent.clear();
    super.dispose();
  }

  @override
  SelectionResult dispatchSelectionEventToChild(
      Selectable selectable, SelectionEvent event) {
    switch (event.type) {
      case SelectionEventType.startEdgeUpdate:
        _hasReceivedStartEvent.add(selectable);
        ensureChildUpdated(selectable);
      case SelectionEventType.endEdgeUpdate:
        _hasReceivedEndEvent.add(selectable);
        ensureChildUpdated(selectable);
      case SelectionEventType.clear:
        _hasReceivedStartEvent.remove(selectable);
        _hasReceivedEndEvent.remove(selectable);
      case SelectionEventType.selectAll:
      case SelectionEventType.selectWord:
        break;
      case SelectionEventType.granularlyExtendSelection:
      case SelectionEventType.directionallyExtendSelection:
        _hasReceivedStartEvent.add(selectable);
        _hasReceivedEndEvent.add(selectable);
        ensureChildUpdated(selectable);
    }
    return super.dispatchSelectionEventToChild(selectable, event);
  }

  @override
  void ensureChildUpdated(Selectable selectable) {
    if (_lastEndEdgeUpdateGlobalPosition != null &&
        _hasReceivedEndEvent.add(selectable)) {
      final synthesizedEvent = SelectionEdgeUpdateEvent.forEnd(
        globalPosition: _lastEndEdgeUpdateGlobalPosition!,
      );
      if (currentSelectionEndIndex == -1) {
        handleSelectionEdgeUpdate(synthesizedEvent);
      }
      selectable.dispatchSelectionEvent(synthesizedEvent);
    }
    if (_lastStartEdgeUpdateGlobalPosition != null &&
        _hasReceivedStartEvent.add(selectable)) {
      final synthesizedEvent = SelectionEdgeUpdateEvent.forStart(
        globalPosition: _lastStartEdgeUpdateGlobalPosition!,
      );
      if (currentSelectionStartIndex == -1) {
        handleSelectionEdgeUpdate(synthesizedEvent);
      }
      selectable.dispatchSelectionEvent(synthesizedEvent);
    }
  }

  @override
  void didChangeSelectables() {
    if (_lastEndEdgeUpdateGlobalPosition != null) {
      handleSelectionEdgeUpdate(
        SelectionEdgeUpdateEvent.forEnd(
          globalPosition: _lastEndEdgeUpdateGlobalPosition!,
        ),
      );
    }
    if (_lastStartEdgeUpdateGlobalPosition != null) {
      handleSelectionEdgeUpdate(
        SelectionEdgeUpdateEvent.forStart(
          globalPosition: _lastStartEdgeUpdateGlobalPosition!,
        ),
      );
    }
    final selectableSet = selectables.toSet();
    _hasReceivedEndEvent.removeWhere(
        (Selectable selectable) => !selectableSet.contains(selectable));
    _hasReceivedStartEvent.removeWhere(
        (Selectable selectable) => !selectableSet.contains(selectable));
    super.didChangeSelectables();
  }
}
