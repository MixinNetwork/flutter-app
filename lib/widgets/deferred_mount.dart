import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Shows [child] in the frame that lays it out while that frame has time
/// left, and shows [placeholder] until a later frame otherwise.
///
/// A list that mounts many costly children at once, such as the conversation
/// list on a category switch, then spreads them over a few frames instead of
/// dropping frames. The choice happens at layout, after the children laid out
/// before it, so the budget covers their build and layout and rows appear from
/// the top. The placeholder must take the size of the child.
class DeferredMount extends StatefulWidget {
  const DeferredMount({
    required this.child,
    this.placeholder = const SizedBox.shrink(),
    this.defer = true,
    super.key,
  });

  final Widget child;
  final Widget placeholder;

  /// Whether [child] can wait for a later frame. A list without fixed item
  /// extents sets it to false for an item it showed before: a placeholder that
  /// grows above the viewport moves the content below it.
  final bool defer;

  @override
  State<DeferredMount> createState() => _DeferredMountState();
}

class _DeferredMountState extends State<DeferredMount> {
  var _shown = false;

  void _retry() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _leave(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (!_shown) {
        _shown = widget.defer ? _take(this) : _leave(this);
      }
      return _shown ? widget.child : widget.placeholder;
    },
  );
}

// The budget starts at the first layout in a frame, so the work before it,
// paint, and the rest of the frame need the remainder of an 8.3 ms frame at
// 120 Hz.
const _budget = Duration(milliseconds: 3);

// Runs from the first layout in a frame to the end of that frame.
final _frame = Stopwatch();
var _endScheduled = false;
var _shownThisFrame = 0;

// Children wait in the order they first missed the budget, until they show.
final _waiting = <_DeferredMountState>{};

bool _take(_DeferredMountState state) {
  if (!_frame.isRunning) {
    _frame
      ..reset()
      ..start();
  }
  _scheduleEnd();
  if (_frame.elapsed < _budget) {
    _waiting.remove(state);
    _shownThisFrame++;
    return true;
  }
  _waiting.add(state);
  return false;
}

// A waiting child that stops waiting or unmounts leaves the queue, and the
// queue still retries the children after it at the end of this frame.
bool _leave(_DeferredMountState state) {
  if (_waiting.remove(state)) _scheduleEnd();
  return true;
}

void _scheduleEnd() {
  if (_endScheduled) return;
  _endScheduled = true;
  SchedulerBinding.instance.addPostFrameCallback((_) => _endFrame());
}

void _endFrame() {
  _endScheduled = false;
  _frame.stop();
  // Retry only the head of the queue: a fast scroll can leave hundreds of
  // children waiting, and building each placeholder again costs time. The
  // layout still checks the time, so the count only needs to be enough.
  final retries = 2 * _shownThisFrame + 1;
  _shownThisFrame = 0;
  for (final state in _waiting.take(retries).toList()) {
    state._retry();
  }
}
