# TimerBuilder

A widget that rebuilds itself on scheduled, periodic, or
dynamically generated time events.

Here are some use cases for this widget:

- When showing time since or until a specified event;
- When the model updates frequently but you want to limit UI update frequency;
- When showing current date or time;
- When the representation a widget depends on a certain time event.

![animated image](https://github.com/aryzhov/flutter-timer-builder/blob/master/doc/timer_builder_example.gif?raw=true)

## Examples

### Periodic rebuild

```dart
import 'package:timer_builder/timer_builder.dart';

class ClockWidget extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return TimerBuilder.periodic(Duration(seconds: 1),
      builder: (context) {
        return Text("${DateTime.now()}");
      }
    );
  }

}
```

### Rebuild on a schedule

**WARNING**: `TimerBuilder.scheduled` sorts the iterable first, which is not recomended for very large iterables and **will not work** with Dart's generator functions.

```dart
import 'package:timer_builder/timer_builder.dart';

class StatusIndicator extends StatelessWidget {

  final DateTime startTime;
  final DateTime endTime;

  StatusIndicator(this.startTime, this.endTime);

  @override
  Widget build(BuildContext context) {
    return TimerBuilder.scheduled([startTime, endTime],
      builder: (context) {
        final now = DateTime.now();
        final started = now.compareTo(startTime) >= 0;
        final ended = now.compareTo(endTime) >= 0;
        return Text(started ? ended ? "Ended": "Started": "Not Started");
      }
    );
  }

}

```

### Generator functions

```dart
class ClockWidget extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return TimerBuilder(
      generator: fromIterable(_scheduler()),
      builder: (context) {
        return Text("${DateTime.now()}");
      }
    );
  }

  Iterable<DateTime> _scheduler() sync* {
    var next = DateTime.now();
    while (true) {
      next = next.add(const Duration(seconds: 1));
      yield next;
    }
  }

}
```
