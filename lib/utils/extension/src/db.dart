part of '../extension.dart';

const kDefaultThrottleDuration = Duration(milliseconds: 333);
const kSlowThrottleDuration = Duration(seconds: 1);
const kVerySlowThrottleDuration = Duration(seconds: 3);

extension SelectedableThrottle<T> on Selectable<T> {
  Stream<Value> _watchWithStream<Value>({
    required Iterable<Stream<dynamic>> eventStreams,
    required Duration duration,
    required Future<Value> Function() fetch,
    bool prepend = true,
  }) {
    var stream = Rx.merge(eventStreams).throttleTime(duration);
    if (prepend) stream = stream.startWith([]);
    return stream.asyncBufferMap((_) => fetch());
  }

  Stream<List<T>> watchWithStream({
    required Iterable<Stream<dynamic>> eventStreams,
    required Duration duration,
    bool prepend = true,
  }) =>
      _watchWithStream(
        eventStreams: eventStreams,
        duration: duration,
        prepend: prepend,
        fetch: get,
      );

  Stream<T> watchSingleWithStream({
    required Iterable<Stream<dynamic>> eventStreams,
    required Duration duration,
    bool prepend = true,
  }) =>
      _watchWithStream(
        eventStreams: eventStreams,
        duration: duration,
        prepend: prepend,
        fetch: getSingle,
      );

  Stream<T?> watchSingleOrNullWithStream({
    required Iterable<Stream<dynamic>> eventStreams,
    required Duration duration,
    bool prepend = true,
  }) =>
      _watchWithStream(
        eventStreams: eventStreams,
        duration: duration,
        prepend: prepend,
        fetch: getSingleOrNull,
      );
}

@immutable
class LikeEscapeOperator extends Expression<bool> {
  const LikeEscapeOperator(
    this.target,
    this.regex,
    this.escape, {
    this.operator = 'LIKE',
  });

  final Expression<String> target;
  final Expression<String> regex;
  final Expression<String> escape;
  final String operator;

  @override
  Precedence get precedence => Precedence.comparisonEq;

  @override
  void writeInto(GenerationContext context) {
    writeInner(context, target);
    context.writeWhitespace();
    context.buffer.write(operator);
    context.writeWhitespace();
    writeInner(context, regex);
    context.writeWhitespace();
    context.buffer.write('ESCAPE');
    context.writeWhitespace();
    writeInner(context, escape);
  }

  @override
  int get hashCode => Object.hash(target, regex, escape, operator);

  @override
  bool operator ==(Object other) =>
      other is LikeEscapeOperator &&
      other.target == target &&
      other.regex == regex &&
      other.escape == escape &&
      other.operator == operator;
}

extension LikeEscapeExpression on Expression<String> {
  Expression<bool> likeEscape(String pattern, {String escape = r'\'}) =>
      LikeEscapeOperator(
        this,
        Variable.withString(pattern),
        Variable.withString(escape),
      );
}
