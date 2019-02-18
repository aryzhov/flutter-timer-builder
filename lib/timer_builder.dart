import 'package:flutter/material.dart';
import 'dart:async';

/// Used by TimerBuilder to determine the next DateTime to trigger a rebuild on
typedef DateTime TimerGenerator(DateTime now);

/// A widget that rebuilds on specific and / or periodic Timer events.
class TimerBuilder extends StatefulWidget {
  final WidgetBuilder builder;
  final TimerGenerator generator;

  /// Use this constructor only if you need to provide a custom TimerGenerator.
  /// For general cases, prefer to use [TimerBuilder.periodic] and [TimerBuilder..scheduled]
  /// This constructor accepts a custom generator function that returns the next time event
  /// to rebuild on.
  TimerBuilder({
    /// Returns the next time event. If the returned time is in the past, it will be ignored and
    /// the generator will be called again to retrieve the next time event.
    /// If the generator returns [null], it indicates the end of time event sequence.
    @required
    this.generator,
    /// Builds the widget. Called for every time event or when the widget needs to be built/rebuilt.
    @required
    this.builder,
  });

  @override
  State<StatefulWidget> createState() {
    return _TimerBuilderState();
  }

  /// Rebuilds periodically
  TimerBuilder.periodic(Duration period, {
    /// If true then the events will be aligned
    bool align = true,
    /// Builds the widget. Called for every time event or when the widget needs to be built/rebuilt.
    @required
    this.builder,
  }): this.generator = periodicTimer(period, align: align ? period: Duration.zero);

  /// Rebuilds on a schedule
  TimerBuilder.scheduled(Iterable<DateTime> schedule, {
    bool align = true,
    /// Builds the widget. Called for every time event or when the widget needs to be built/rebuilt.
    @required
    this.builder,
  }): this.generator = scheduledTimer(schedule);

  static TimerGenerator periodicTimer(Duration period, {Duration align = Duration.zero}) {
    assert(period > Duration.zero);

    DateTime next;
    return (DateTime now) {
      next = alignDateTime((next ?? now).add(period), align);
      if(now.compareTo(next) < 0) {
        next = alignDateTime(now.add(period), align);
      }
      return next;
    };

  }

  static TimerGenerator scheduledTimer(Iterable<DateTime> schedule) {

    List<DateTime> sortedSpecific = List.from(schedule.where((e) => e != null).toList());
    sortedSpecific.sort((a, b) => a.compareTo(b));

    return fromIterable(sortedSpecific);

  }

  static TimerGenerator fromIterable(Iterable<DateTime> iterable) {

    final iterator = iterable.iterator;
    return (DateTime now) {
      return  iterator.moveNext() ? iterator.current : null;
    };

  }

  /// Rounds down or up a [DateTime] object using a [Duration] object.
  /// If [roundUp] is true, the result is rounded up, otherwise it's rounded down.
  static DateTime alignDateTime(DateTime dt, Duration duration, [bool roundUp = false]) {
    if(duration == Duration.zero)
      return dt;
    final micros = dt.microsecondsSinceEpoch;
    final durationMicros = duration.inMicroseconds.abs();
    if (durationMicros == 0) return dt;
    final correction = micros % durationMicros;
    if (correction == 0) return dt;
    final correctedResultMicros = micros - correction + (roundUp ? durationMicros : 0);
    final result = DateTime.fromMicrosecondsSinceEpoch(correctedResultMicros);
    return result;
  }

}

class _TimerBuilderState extends State<TimerBuilder> {

  Stream<DateTime> stream;
  Completer completer;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: stream,
      builder: (context, _) => widget.builder(context),
    );
  }

  @override
  void didUpdateWidget(TimerBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    _update();
  }

  @override
  void initState() {
    super.initState();
    _update();
  }

  @override
  void dispose() {
    super.dispose();
    _cancel();
  }

  _update() {
    _cancel();
    completer = Completer();
    stream = _timerStream(widget.generator, completer.future);
  }

  _cancel() {
    if(completer != null)
      completer.complete();
  }

  static Stream<DateTime> _timerStream(
    TimerGenerator generator,
    Future stopWhen,
  ) async* {
    var now = DateTime.now();
    DateTime next;
    while((next = generator(now)) != null) {
      if(now.compareTo(next) > 0)
        continue;
      Duration waitTime = next.difference(now);
      try {
        await stopWhen.timeout(waitTime);
        return;
      } catch (ex) {
        if (!(ex is TimeoutException))
          throw ex;
      }
      yield next;
      now = DateTime.now();
    }
  }

}
