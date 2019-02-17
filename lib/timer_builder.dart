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
  DateTime _currentTime;
  final _timers = Map<DateTime, Timer>();
  Duration _period;
  DateTime _nextPeriodic;
  bool _align;
  bool _disposed = false;

  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }

  @override
  void didUpdateWidget(TimerBuilder oldWidget) {
    _update(widget.specific, widget.periodic, widget.align);
  }

  @override
  void initState() {
    super.initState();
    _update(widget.specific, widget.periodic, widget.align);
  }

  @override
  void dispose() {
    super.dispose();
    _cancelAll();
    _disposed = false;
  }

  DateTime _getNextPeriodic(DateTime now) {
    if (_period == null) return null;
    return alignDateTime(now.add(_period), _align ? _period : Duration.zero);
  }

  _update(Iterable<DateTime> triggers, Duration period, bool align) {
    if (_disposed) return;
    var now = _currentTime ?? DateTime.now();
    if (_period != period || _align != align) {
      this._period = period;
      this._align = align;
      if (this._period != null) {
        _nextPeriodic = _getNextPeriodic(now);
        _addTimer(_nextPeriodic, true);
      } else {
        _nextPeriodic = null;
      }
    }
    for (var d in _timers.keys.toList()) if (!triggers.contains(d) && d != _nextPeriodic) _removeTimer(d);
    for (var t in triggers) _addTimer(t);
  }

  _addTimer(DateTime trigger, [bool force = false]) {
    if (trigger == null) return;
    final now = DateTime.now();
//    print("addTimer: $trigger");
    var difference = trigger.difference(now);
    if (difference <= Duration.zero) {
      if (force)
        difference = Duration.zero;
      else
        return;
    }
    _timers.putIfAbsent(
        trigger,
        () => Timer(difference, () {
              _currentTime = DateTime.now();
//      print("Timer: $_currentTime");
              bool found = false;
              // In case the device was suspended, cancel all other timers which are past due
              for (var t in _timers.keys.toList()) {
                if (t == trigger || t.compareTo(_currentTime) <= 0) {
                  _removeTimer(t);
                  found = true;
                }
              }
              if (_nextPeriodic != null && _nextPeriodic.compareTo(_currentTime) <= 0) {
                _nextPeriodic = _getNextPeriodic(_currentTime);
                _addTimer(_nextPeriodic, true);
                found = true;
              }
              try {
                if (found && !_disposed) setState(() {});
              } finally {
                _currentTime = null;
              }
            }));
  }

  _removeTimer(DateTime trigger) {
//    print("removeTimer: $trigger");
    if (trigger != null) _timers.remove(trigger)?.cancel();
  }

  _cancelAll() {
    if (_timers.isNotEmpty) _update([], null, false);
  }
}
