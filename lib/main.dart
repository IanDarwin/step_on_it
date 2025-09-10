import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:material_charts/material_charts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import 'package:step_on_it/nav_drawer.dart';
import 'package:step_on_it/goal_model.dart';
import 'package:step_on_it/step_count_db.dart';

import 'constants.dart';
import 'date_count.dart';

late SharedPreferences prefs;
late String version;
late int buildNumber;
const defaultGoal = 10000;
StepCountDB stepCountDB = StepCountDB();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  prefs = await SharedPreferences.getInstance();
  await Settings.init();
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  version = packageInfo.version;
  buildNumber = int.parse(packageInfo.buildNumber);
  await stepCountDB.init();
  runApp(
    ChangeNotifierProvider(
      create: (context) => GoalModel(),
      child: const MyApp(),
    ),
  );
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
  int _stepsToday = 0;
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

  void onStepCount(StepCount event) async {
    var stepCount = await stepCountDB.findByDate(Date.today());
    var newCount = stepCount.count+1;
    stepCountDB.setTodayCount(newCount);
    
    setState(() {
      _stepsToday = newCount;
    });
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
      _stepsToday = 0;
    });
  }

  Future<void> initPlatformState() async {
    double? savedGoal = prefs.getDouble(Constants.KEY_GOAL_SETTING);
    if (savedGoal != null) {
      var goalModel = Provider.of<GoalModel>(context, listen:false);
      goalModel.setGoal(savedGoal);
    }
    if (!await stepCountDB.existsForDate(Date.today())) {
      var dc = DateCount(date: Date.today(), count:0, goal: savedGoal != null ? savedGoal as int : defaultGoal);
      stepCountDB.save(dc);
    }
    if (!await Permission.activityRecognition.isGranted) {
      if (!mounted) {
        return;
      }
      await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  AlertDialog(
                      title: const Text("Permission Request"),
                      content: const Text("""
Step On It saves your personal step count, only on your device.
That's the point of this app, after all!

We need physical activity sensor permission to count your steps.

We never ever upload any data, anywhere.

You can export the data; what you do with it then is not on us."""),
                      actions: <Widget>[
                        TextButton(
                            child: Text("OK"),
                            onPressed: () async {
                              Navigator.of(context).pop(); // Alert
                            }
                        )
                      ])));
     }
      if ((await Permission.activityRecognition.request()).isGranted) {
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

  void _resetAtMidnight() async {
    setState(() {
      _stepsToday = 0; // Steps today should be zero at the moment of reset
    });
    stepCountDB.setTodayCount(0);
    await prefs.setString('lastResetDate', DateTime.now().toIso8601String().substring(0, 10));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GoalModel>(
      builder: (context, goalModel, child) {
        double percentage = 100 * _stepsToday.toDouble() / goalModel.goal;
        if (percentage > 100) {
          debugPrint("OOPS: Percentage high: $percentage");
          percentage = 100;
        }
        if (percentage < 0) {
          debugPrint("OOPS: Percentage low: $percentage");
          percentage = 0;
        }
        var currentGoal = goalModel.goal; // Get the current goal from the provider
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
                  size: 250,
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
                      "${label=='Active'?_stepsToday.round():(currentGoal-_stepsToday).round()} of ${currentGoal.round()}",
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
      });
  }
}
