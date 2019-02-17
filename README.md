# TimerBuilder

A widget that rebuilds itself on Timer events. A duration and / or a time duration can be specified.
Some cases where this widget can be useful:

* When showing the time since or until a specified event;
* When your model updates frequently but you want to limit UI update frequency;
* When showing current date or time;
* When the representation of of your UI depends on a certain time event.

## Getting Started

```dart
import 'package:timer_builder/timer_builder.dart';

class ClockWidget extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return TimerBuilder(
      periodic: Duration(seconds: 1),
      align: true,
      builder: (context) {
        return Text("${DateTime.now()}");
      }
    );
  }
  
}
```