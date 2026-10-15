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
    super.key,
  });

  final Widget child;
  final Widget placeholder;

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
    _waiting.remove(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      _shown = _shown || _take(this);
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

final _waiting = <_DeferredMountState>{};

bool _take(_DeferredMountState state) {
  if (!_frame.isRunning) {
    _frame
      ..reset()
      ..start();
  }
  if (!_endScheduled) {
    _endScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) => _endFrame());
  }
  if (_frame.elapsed < _budget) return true;
  _waiting.add(state);
  return false;
}

void _endFrame() {
  _endScheduled = false;
  _frame.stop();
  final waiting = _waiting.toList();
  _waiting.clear();
  for (final state in waiting) {
    state._retry();
  }
}
