import 'package:boot_time_plugin/boot_time_plugin.dart';
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
int rebootFactor = 0;
const defaultGoal = 10000;
StepCountDB stepCountDB = StepCountDB();

/// Step On It - a basic step-counting app
///
/// Step Counting sounds simple, but isn't. The app can be killed anytime
/// and restarted many steps later, so you have to handle that. As well,
/// the underlying OS step-counter increments from zero after each reboot,
/// so first time after a reboot, you have to behave specially.
///
/// We handle application restart by caching steps in the shared prefs.
/// we don't yet correctly handle in-day device restart - major XXX!
///
/// The main data items are:
///  _totalSteps - from the OS counter, set in onStep
///  current goal - set in "GoalModel"
///
/// The SharedPreferences singleton is used to store and retrieve 3 values:
///  stepsAtMidnight - the value of _totalSteps as of 00:00:01 this morning
///  _totalSteps - what it says
///  stepsAtMidnight - ditto
///  rebootFactor - for use only after in-day reboot
///
/// The StepCountDB is write-only for now; to be used for graphing and exporting.
///
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
  String _status = "No steps yet";
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

  void onStepCount(StepCount event) async {
    print("step");
    if (!_firstStepEventReceived) {
      _firstStepEventReceived = true;
      _checkAndResetDailySteps(event.steps);
    }
    _totalSteps = event.steps;
    _stepsToday = _totalSteps - _stepsAtMidnight + rebootFactor;
    print("_stepsToday $_stepsToday");
    await _saveData();
    setState(() {
      // update ui
    });
  }

  void onPedestrianStatusChanged(PedestrianStatus event) {
    print("ped stat change");
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
    int? previousBootTimeMillis = prefs.getInt(Constants.KEY_LAST_BOOT_TIME);
    int bootTimeMillis = await BootTimePlugin.getBootTimeMilliseconds();
    if (previousBootTimeMillis == null) {
      // first run after app install!
      print("first run after app install!");
    }
    prefs.setInt(Constants.KEY_LAST_BOOT_TIME, bootTimeMillis);
    _stepsAtMidnight = prefs.getInt('stepsAtMidnight') ?? 0;
    _totalSteps = prefs.getInt('lastTotalSteps') ?? 0;
    bool newDay = !await stepCountDB.existsForDate(Date.today());
    if (previousBootTimeMillis != bootTimeMillis) {
      // First run after device reboot - saved data may be wrong!
      // if (!newDay) {
      //   rebootFactor = -_totalSteps;
      // }
      print("First run after device reboot; rebootFactor = $rebootFactor");
    }

    double? savedGoal = prefs.getDouble(Constants.KEY_GOAL_SETTING);
    if (newDay) {
      // First run on today's date
      var dc = DateCount(date: Date.today(), count:0, goal: savedGoal != null ? savedGoal.round() : defaultGoal);
      stepCountDB.save(dc);
      // invalidate caches
      _stepsAtMidnight = 0;
      _totalSteps = 0;
    }
      // Calculate initial _stepsToday from saved data to show the last known count,
      // even though this will be corrected by the first step event.
      if (_totalSteps >= _stepsAtMidnight) {
          // This MUST agree with the line in onStep()
          _stepsToday = _totalSteps - _stepsAtMidnight + rebootFactor;
      }

    if (savedGoal != null) {
      var goalModel = Provider.of<GoalModel>(context, listen:false);
      goalModel.setGoal(savedGoal);
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

We never ever upload any data, anywhere. You can export the data; 
what you do with it then is up to you."""),
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
        setState(() {
          // update display
        });
      } else {
        setState(() {
          _status = 'Permission Denied';
        });
      }
      await _saveData();
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
    // We can't rely on _totalSteps being updated at this exact moment,
    // so we get the current total steps from the latest event.
    // This is a robust approach for a midnight reset.
    _stepsAtMidnight = _totalSteps;
    setState(() {
      _stepsToday = 0; // Start over!
    });
    await _saveData();
  }

  Future<void> _saveData() async {
    await prefs.setInt('stepsAtMidnight', _stepsAtMidnight);
    await prefs.setString('lastResetDate', Date.today().toString());
    await prefs.setInt('lastTotalSteps', _totalSteps);
    stepCountDB.setTodayCount(_stepsToday);
  }

  void _checkAndResetDailySteps(int currentTotalSteps) async {
    final now = Date.today();
    final lastResetDateString = prefs.getString('lastResetDate');
    final lastResetDate = lastResetDateString != null ? DateTime.parse(lastResetDateString) : null;
    if (lastResetDate == null ||
        now.day != lastResetDate.day ||
        now.month != lastResetDate.month ||
        now.year != lastResetDate.year) {
      _stepsAtMidnight = currentTotalSteps;
      setState(() {
         _stepsToday = 0; // Steps today should be zero at the moment of reset
      });
      await _saveData();
    } else {
       // If it's the same day, update _stepsAtMidnight to the loaded value.
       _stepsAtMidnight = prefs.getInt('stepsAtMidnight') ?? 0;
    }
  }

  // Last but not least, the all-important widget build method!
  @override
  Widget build(BuildContext context) {
    return Consumer<GoalModel>(
      builder: (context, goalModel, child) {
        double percentage = 100 * _stepsToday.toDouble() / goalModel.goal;
        if (percentage > 100) {
          // Wahoo! They got more steps than original goal.
          // Should set to percentage and bump max - later XXX
          // Should be a confetti animation here XXX
          goalModel.setGoal(goalModel.goal * 1.5);
          percentage = 100 * _stepsToday.toDouble() / goalModel.goal;
        }
        if (percentage < 0) {
          debugPrint("OOPS: % is $percentage, clipping to zero");
          percentage = 0;
        }
        var currentGoal = goalModel.goal; // Get the current goal from the provider
        return Scaffold(
          appBar: AppBar(
            title: const Text('Step Counter'),
          ),
          drawer: NavDrawer(),
          body: Center(
            child: SingleChildScrollView(
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
          ),
        );
      });
  }
}
