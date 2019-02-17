import 'package:flutter/material.dart';
import 'dart:async';

/// A widget that rebuilds on specific and / or periodic Timer events.
class TimerBuilder extends StatefulWidget {
  final WidgetBuilder builder;
  final List<DateTime> specific;
  final Duration periodic;
  final bool align;

  TimerBuilder({
    /// Specific time events. If a time event occurs in the past, it will be ignored.
    this.specific = const [],
    /// Specifies a duration for a periodic refresh.
    this.periodic,
    /// If true and [periodic] is specified, the periodic time events will be aligned
    /// using the [alignDateTime] function.
    this.align = true,
    /// Builds the widget. Called for every time event or when the widget needs to be built/rebuilt.
    @required this.builder,
  });

  @override
  State<StatefulWidget> createState() {
    return _TimerBuilderState();
  }
}

/// Rounds down or up a [DateTime] object using a [Duration] object.
/// If [roundUp] is true, the result is rounded up, otherwise it's rounded down.
DateTime alignDateTime(DateTime dt, Duration duration, [bool roundUp = false]) {
  final micros = dt.microsecondsSinceEpoch;
  final durationMicros = duration.inMicroseconds.abs();
  if (durationMicros == 0) return dt;
  final correction = micros % durationMicros;
  if (correction == 0) return dt;
  final correctedResultMicros = micros - correction + (roundUp ? durationMicros : 0);
  final result = DateTime.fromMicrosecondsSinceEpoch(correctedResultMicros);
  return result;
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
    stream = timerStream(specific: widget.specific, period: widget.periodic,
        align: widget.align ? widget.periodic : null, stopWhen: completer.future);
  }

  _cancel() {
    if(completer != null)
      completer.complete();
  }
}

Stream<DateTime> timerStream({
  List<DateTime> specific = const [],
  Duration period,
  Duration align,
  Future stopWhen,
}) async* {
  assert(period == null || period >= Duration.zero);
  final sortedSpecific = List.from(specific.where((e) => e != null).toList());
  sortedSpecific.sort((a, b) => -a.compareTo(b));

  var now = DateTime.now();
  var nextPeriodic = period == null ? null: alignDateTime(now.add(period), align);

  while(true) {
    DateTime nextSpecific;
    while(sortedSpecific.isNotEmpty && nextSpecific == null) {
      var next = sortedSpecific.removeLast();
      if(now.compareTo(next) <= 0)
        nextSpecific = next;
    }

    final nextStop = nextSpecific != null ?
      nextPeriodic != null ? nextSpecific.compareTo(nextPeriodic) < 0 ?
          nextSpecific: nextPeriodic: nextSpecific: nextPeriodic;
    if(nextStop == null)
      return;
    Duration waitTime = nextStop.difference(now);
    if(waitTime > Duration.zero) {
      if (stopWhen != null) {
        try {
          await stopWhen.timeout(waitTime);
          return;
        } catch (ex) {
          if (!(ex is TimeoutException))
            throw ex;
        }
      } else {
        await Future.delayed(waitTime);
      }
    }
    yield nextStop;
    now = DateTime.now();
    if(nextPeriodic != null && now.compareTo(nextPeriodic) > 0) {
      nextPeriodic = alignDateTime(nextPeriodic.add(period), align);
      if(now.compareTo(nextPeriodic) < 0) {
        nextPeriodic = alignDateTime(now.add(period), align);
      }
    }
  }
}