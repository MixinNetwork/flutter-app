import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

void main() {
  var created = 0;

  Future<void Function(List<int>)> pumpList(
    WidgetTester tester, {
    required bool withCallback,
    ItemScrollController? controller,
    ItemPositionsListener? positions,
  }) async {
    var ids = List.generate(30, (i) => i);
    late StateSetter setIds;
    await tester.pumpWidget(MaterialApp(
      home: StatefulBuilder(builder: (context, setState) {
        setIds = setState;
        final indexes = {for (var i = 0; i < ids.length; i++) ids[i]: i};
        return ScrollablePositionedList.builder(
          itemCount: ids.length,
          itemScrollController: controller,
          itemPositionsListener: positions,
          findChildIndexCallback: withCallback
              ? (key) =>
                  key is ValueKey<String> ? indexes[int.parse(key.value)] : null
              : null,
          itemBuilder: (context, index) => _Row(
            key: ValueKey('${ids[index]}'),
            onCreate: () => created++,
          ),
        );
      }),
    ));
    return (next) => setIds(() => ids = next);
  }

  List<int> moveToTop(int id) =>
      [id, ...List.generate(30, (i) => i).where((e) => e != id)];

  testWidgets('a moved item keeps its state with findChildIndexCallback',
      (tester) async {
    final setIds = await pumpList(tester, withCallback: true);
    created = 0;
    setIds(moveToTop(10));
    await tester.pump();
    // Only the items that change slivers are created again: the moved item
    // enters the center sliver and the old first item leaves it.
    expect(created, 2);
  });

  testWidgets('items are created again without findChildIndexCallback',
      (tester) async {
    final setIds = await pumpList(tester, withCallback: false);
    created = 0;
    setIds(moveToTop(10));
    await tester.pump();
    expect(created, 11);
  });

  testWidgets('positions report item indexes with findChildIndexCallback',
      (tester) async {
    final positions = ItemPositionsListener.create();
    final controller = ItemScrollController();
    await pumpList(tester,
        withCallback: true, controller: controller, positions: positions);
    controller.jumpTo(index: 5);
    await tester.pump();
    final indexes = positions.itemPositions.value.map((p) => p.index).toList()
      ..sort();
    expect(indexes.first, 5);
  });
}

class _Row extends StatefulWidget {
  const _Row({required this.onCreate, Key? key}) : super(key: key);

  final VoidCallback onCreate;

  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> {
  @override
  void initState() {
    super.initState();
    widget.onCreate();
  }

  @override
  Widget build(BuildContext context) => const SizedBox(height: 50);
}
