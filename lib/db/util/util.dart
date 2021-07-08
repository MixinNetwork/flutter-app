import 'package:moor/moor.dart';

final maxLimit = _MaxLimit();

class _MaxLimit extends Limit {
  _MaxLimit() : super(0, null);

  @override
  void writeInto(GenerationContext context) {
    // do nothing;
  }
}

const ignoreWhere = CustomExpression<bool>('true');
