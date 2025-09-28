import 'package:flutter/material.dart';

import 'package:step_on_it/constants.dart';
import 'package:step_on_it/main.dart' show runType,
  rebootFactor, stepsAtMidnight, stepsToday, totalSteps;

class DebugPanel extends StatefulWidget {
  const DebugPanel({super.key});

  @override
  DebugState createState() => DebugState();
}

class DebugState extends State<DebugPanel> {

  DebugState();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Step Counter'),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Current Values:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text("Debug: ${Constants.debug}"),
                  Text("RunType: $runType"),
                  Text("TotalSteps from OS: $totalSteps"),
                  Text("Steps today: $stepsToday"),
                  Text("Steps at midnight: $stepsAtMidnight"),
                  Text("RebootFactor: $rebootFactor"),
                  // Get goal
                  // Get rebootFactor
                ]
        )
    );
  }
}