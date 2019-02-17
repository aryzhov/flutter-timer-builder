import 'package:flutter/material.dart';
import 'package:timer_builder/timer_builder.dart';

void main() {
  runApp(SampleApp());
}

class SampleApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Sample App'),
        ),
        body: Center(
          child: ClockWidget(),
        ),
      ),
    );
  }
}

class ClockWidget extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return TimerBuilder(
      specific: List.generate(10, (i) => alignDateTime(DateTime.now().add(Duration(seconds: i*2)), Duration(seconds: 1))),
      periodic: Duration(seconds: 3),
      align: true,
      builder: (context) {
        return Text("${DateTime.now()}");
      }
    );
  }

}
