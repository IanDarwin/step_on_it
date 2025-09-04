import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:material_charts/material_charts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import 'package:step_on_it/nav_drawer.dart';

import 'constants.dart';

late SharedPreferences prefs;
late String version;
late int buildNumber;
const defaultGoal = 10000;
int goal = 0;
double percentage = 0;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  prefs = await SharedPreferences.getInstance();
  await Settings.init();
  try {
    goal = prefs.getDouble(Constants.KEY_GOAL_SETTING)!.toInt();
  } catch(exc) {
    debugPrint("Getting goal from prefs blew $exc");
    goal = defaultGoal;
  }
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  version = packageInfo.version;
  buildNumber = int.parse(packageInfo.buildNumber);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Step Counter',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const StepCounterPage(),
    );
  }
}

class StepCounterPage extends StatefulWidget {
  const StepCounterPage({super.key});

  @override
  StepCounterPageState createState() => StepCounterPageState();
}

class StepCounterPageState extends State<StepCounterPage> {
  late Stream<StepCount> _stepCountStream;
  late Stream<PedestrianStatus> _pedestrianStatusStream;
  String _status = "Don't know yet";
  int _totalSteps = 0;
  int _stepsToday = 0;
  int _stepsAtMidnight = 0;
  bool _firstStepEventReceived = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  @override
  void dispose() { 
    _timer?.cancel();
    super.dispose();
  }

  void onStepCount(StepCount event) {
    if (!_firstStepEventReceived) {
      _firstStepEventReceived = true;
      _checkAndResetDailySteps(event.steps);
    }
    
    setState(() {
      _totalSteps = event.steps;
      _stepsToday = _totalSteps - _stepsAtMidnight;
      percentage = _stepsToday*100.0 / goal;
      if (percentage > 100) {
        percentage = 100;
      }
    });
    _saveData();
  }

  void onPedestrianStatusChanged(PedestrianStatus event) {
    setState(() {
      _status = event.status;
    });
  }

  void onPedestrianStatusError(error) {
    setState(() {
      _status = 'Pedestrian Status not available';
    });
  }

  void onStepCountError(error) {
    setState(() {
      _totalSteps = 0;
      _stepsToday = 0;
    });
  }

  Future<void> initPlatformState() async {
    await _loadSavedData();
    
    var status = await Permission.activityRecognition.request();
    if (status.isGranted) {
      _pedestrianStatusStream = Pedometer.pedestrianStatusStream;
      _pedestrianStatusStream
          .listen(onPedestrianStatusChanged)
          .onError(onPedestrianStatusError);

      _stepCountStream = Pedometer.stepCountStream;
      _stepCountStream.listen(onStepCount).onError(onStepCountError);
      _startMidnightTimer(); // Start the timer after everything is initialized
    } else {
      setState(() {
        _status = 'Permission Denied';
      });
    }
  }

  void _startMidnightTimer() {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final duration = nextMidnight.difference(now);
    
    _timer = Timer(duration, () {
      _resetAtMidnight();
      // Set a new timer for the next midnight
      _timer = Timer.periodic(const Duration(days: 1), (timer) {
        _resetAtMidnight();
      });
    });
  }

  void _resetAtMidnight() {
    // We can't rely on _totalSteps being updated at this exact moment,
    // so we get the current total steps from the latest event.
    // This is a robust approach for a midnight reset.
    _stepsAtMidnight = _totalSteps;
    _stepsToday = _totalSteps - _stepsAtMidnight; // This SHOULD set stepsToday to 0
    _saveData();
    
    setState(() {}); // Force a rebuild to update the UI
  }

  Future<void> _loadSavedData() async {
    _stepsAtMidnight = prefs.getInt('stepsAtMidnight') ?? 0;
    
    // We can calculate _stepsToday from saved data to show the last known count,
    // but this will be corrected by the first step event.
    int lastTotalSteps = prefs.getInt('lastTotalSteps') ?? 0;
    if (lastTotalSteps > _stepsAtMidnight) {
      setState(() {
        _stepsToday = lastTotalSteps - _stepsAtMidnight;
      });
    }
  }

  Future<void> _saveData() async {
    await prefs.setInt('stepsAtMidnight', _stepsAtMidnight);
    await prefs.setString('lastResetDate', DateTime.now().toIso8601String().substring(0, 10));
    await prefs.setInt('lastTotalSteps', _totalSteps);
  }

  void _checkAndResetDailySteps(int currentTotalSteps) async {
    final now = DateTime.now();
    final lastResetDateString = prefs.getString('lastResetDate');
    final lastResetDate = lastResetDateString != null ? DateTime.parse(lastResetDateString) : null;

    if (lastResetDate == null ||
        now.day != lastResetDate.day ||
        now.month != lastResetDate.month ||
        now.year != lastResetDate.year) {
      // The `_resetSteps` function is now called with the first valid total steps value.
      _resetSteps(currentTotalSteps);
    } else {
       // If it's the same day, update _stepsAtMidnight to the loaded value.
       _stepsAtMidnight = prefs.getInt('stepsAtMidnight') ?? 0;
    }
  }

  void _resetSteps(int currentTotalSteps) async {
    // Set the new baseline for the day.
    _stepsAtMidnight = currentTotalSteps;
    await _saveData();
    
    // Recalculate daily steps after the reset
    setState(() {
      _stepsToday = 0; // Steps today should be zero at the moment of reset
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Step Counter'),
      ),
      drawer: NavDrawer(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            MaterialChartHollowSemiCircle(
              percentage: percentage,
              size: 280,
              hollowRadius: 0.65,
              style: ChartStyle(
                activeColor: Colors.green,
                inactiveColor: Colors.grey[300]!,
                showPercentageText: true,
                showLegend: true,
                percentageStyle: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
                legendStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
                legendFormatter: (label, percentage) =>
                  "${label=='Active'?_stepsToday:goal-_stepsToday} of $goal",
              ),
            ),
            const Divider(
              height: 100,
              thickness: 0,
              color: Colors.white,
            ),
            const Text(
              'Status:',
              style: TextStyle(fontSize: 30),
            ),
            Icon(
              _status == 'walking'
                  ? Icons.directions_walk
                  : _status == 'stopped'
                      ? Icons.accessibility_new
                      : Icons.error,
              size: 100,
            ),
            Center(
              child: Text(
                _status[0].toUpperCase() + _status.substring(1),
                style: _status == 'walking' || _status == 'stopped'
                    ? const TextStyle(fontSize: 30, color: Colors.green)
                    : const TextStyle(fontSize: 20, color: Colors.red),
              ),
            )
          ],
        ),
      ),
    );
  }
}
