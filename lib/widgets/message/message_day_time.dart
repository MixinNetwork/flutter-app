import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../bloc/minute_timer_cubit.dart';
import '../../db/mixin_database.dart' as db;
import '../../utils/datetime_format_utils.dart';
import '../../utils/extension/extension.dart';
import '../../utils/hook.dart';
import '../../utils/logger.dart';
import 'message.dart';

class MessageDayTime extends HookWidget {
  const MessageDayTime({
    Key? key,
    required this.dateTime,
  }) : super(key: key);

  final DateTime dateTime;

  @override
  Widget build(BuildContext context) {
    final hide =
        useBlocStateConverter<_HiddenMessageDayTimeBloc, DateTime?, bool>(
            converter: (state) => isSameDay(state, dateTime));
    return Center(
      child: Opacity(
        opacity: hide ? 0 : 1,
        child: _MessageDayTimeWidget(dateTime: dateTime),
      ),
    );
  }
}

class _MessageDayTimeWidget extends HookWidget {
  const _MessageDayTimeWidget({Key? key, required this.dateTime})
      : super(key: key);

  final DateTime dateTime;

  @override
  Widget build(BuildContext context) {
    final dateTimeString =
        useBlocStateConverter<MinuteTimerCubit, DateTime, String>(
      converter: (_) => dateTime.formatOfDay,
      keys: [dateTime],
    );
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: context.theme.dateTime,
        ),
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 64,
          ),
          child: Text(
            dateTimeString,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: MessageItemWidget.secondaryFontSize,
            ),
          ),
        ),
      ),
    );
  }
}

class _HiddenMessageDayTimeBloc extends Cubit<DateTime?> {
  _HiddenMessageDayTimeBloc() : super(null);

  void update(DateTime? dateTime) => emit(dateTime);
}

class MessageDayTimeViewportWidget extends HookWidget {
  const MessageDayTimeViewportWidget({
    Key? key,
    required this.child,
    required this.scrollController,
    required this.topKey,
    required this.bottomKey,
    required this.center,
    required this.centerKey,
  })  : assert((centerKey == null) == (center == null)),
        super(key: key);

  final Widget child;

  final ScrollController scrollController;

  final GlobalKey topKey;
  final GlobalKey bottomKey;
  final db.MessageItem? center;
  final GlobalKey? centerKey;

  @override
  Widget build(BuildContext context) {
    final dateTime = useState<DateTime?>(null);
    final dateTimeTopOffset = useState<double>(0);

    final bloc =
        useBloc<_HiddenMessageDayTimeBloc>(() => _HiddenMessageDayTimeBloc());

    void doTraversal() {
      final items = <db.MessageItem>[];
      final elements = <Element>[];
      final dayTimeElements = <Element?>[];

      void findMessageItem() {
        void dumpKeyedSubtree(Element element, {bool reverse = false}) {
          final item =
              element.descendantFirstOf((e) => e.widget is MessageItemWidget);
          final widget = item.widget as MessageItemWidget;

          final Element? dayTimeElement;
          if (!isSameDay(widget.message.createdAt, widget.prev?.createdAt)) {
            dayTimeElement = element
                .descendantFirstOf((e) => e.widget is _MessageDayTimeWidget);
          } else {
            dayTimeElement = null;
          }
          if (!reverse) {
            items.add(widget.message);
            elements.add(item);
            dayTimeElements.add(dayTimeElement);
          } else {
            items.insert(0, widget.message);
            elements.insert(0, item);
            dayTimeElements.insert(0, dayTimeElement);
          }
        }

        topKey.currentContext!
            .visitChildElements((e) => dumpKeyedSubtree(e, reverse: true));

        if (center != null) {
          final item = (centerKey!.currentContext! as Element)
              .descendantFirstOf((e) => e.widget is MessageItemWidget);
          items.add(center!);
          elements.add(item);
        }

        bottomKey.currentContext!.visitChildElements(dumpKeyedSubtree);
      }

      findMessageItem();

      assert(
        items.length == elements.length,
        'items.length != elements.length',
      );
      if (items.isEmpty) {
        return;
      }
      final currentRender = context.findRenderObject()! as RenderBox;

      // find first item which in screen
      var firstInScreenIndex = -1;
      for (var i = 0; i < elements.length; i++) {
        final render = elements[i].renderObject as RenderBox?;
        if (render == null) {
          continue;
        }
        final offset = render.localToGlobal(
          Offset(0, render.size.height),
          ancestor: currentRender,
        );

        if (offset.dy > 0) {
          firstInScreenIndex = i;
          break;
        }
      }

      if (firstInScreenIndex == -1) {
        d('no item in screen');
        dateTime.value = null;
        return;
      }

      var closestToTopDayTimeIndex = -1;
      var closestToTopDayTimeOffset = double.infinity;
      for (var i = -1; i <= 1; i++) {
        final index = firstInScreenIndex + i;
        if (index < 0 || index >= dayTimeElements.length) {
          continue;
        }
        final element = dayTimeElements[firstInScreenIndex + i];
        if (element != null) {
          final render = element.renderObject as RenderBox?;
          if (render == null) {
            continue;
          }
          final offset = render.localToGlobal(
            Offset(0, render.size.height / 2),
            ancestor: currentRender,
          );
          final distance = (offset.dy - render.size.height / 2).abs();
          if (distance < closestToTopDayTimeOffset) {
            closestToTopDayTimeIndex = index;
            closestToTopDayTimeOffset = distance;
          }
        }
      }

      if (closestToTopDayTimeIndex != -1) {
        final render = dayTimeElements[closestToTopDayTimeIndex]!.renderObject
            as RenderBox?;
        assert(render != null, '$closestToTopDayTimeIndex render is null');
        final offset = render!.localToGlobal(
          Offset(0, render.size.height / 2),
          ancestor: currentRender,
        );

        if (offset.dy < render.size.height / 2) {
          // up
          firstInScreenIndex = closestToTopDayTimeIndex;
          bloc.update(items[closestToTopDayTimeIndex].createdAt);
          dateTimeTopOffset.value = 0;
        } else {
          // down
          if (firstInScreenIndex != closestToTopDayTimeIndex) {
            assert(() {
              if (firstInScreenIndex > closestToTopDayTimeIndex) {
                e('firstInScreenIndex > closestToTopDayTimeIndex');
              }
              if (isSameDay(items[firstInScreenIndex].createdAt,
                  items[closestToTopDayTimeIndex].createdAt)) {
                e('there is a day time item but is the same day.'
                    ' $firstInScreenIndex $closestToTopDayTimeIndex');
              }
              return true;
            }());
            bloc.update(null);
            dateTimeTopOffset.value = offset.dy - render.size.height * 1.5;
          } else {
            firstInScreenIndex = -1;
            dateTimeTopOffset.value = 0;
            bloc.update(null);
          }
        }
      } else {
        bloc.update(null);
        dateTimeTopOffset.value = 0;
      }

      dateTime.value = items.getOrNull(firstInScreenIndex)?.createdAt;
    }

    useEffect(() {
      scrollController.addListener(doTraversal);
      return () {
        scrollController.removeListener(doTraversal);
      };
    }, [scrollController]);

    useEffect(() {
      WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
        doTraversal();
      });
    }, [centerKey]);

    return BlocProvider.value(
      value: bloc,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            child,
            if (dateTime.value != null)
              Transform.translate(
                offset: Offset(0, dateTimeTopOffset.value.clamp(-60.0, 0.0)),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: _MessageDayTimeWidget(dateTime: dateTime.value!),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

extension _ElementExt on Element {
  Element descendantFirstOf(bool Function(Element e) predicate) {
    Element? dump(Element element) {
      if (predicate(element)) {
        return element;
      }
      Element? child;
      element.visitChildren((e) {
        if (child != null) {
          return;
        }
        child = dump(e);
      });
      return child;
    }

    Element? result;
    visitChildren((element) {
      if (result != null) {
        return;
      }
      result = dump(element);
    });
    return result!;
  }
}
