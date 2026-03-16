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
///  _totalSteps - latest reading from the OS
///  stepsAtMidnight - ditto
///  rebootFactor - for use only after in-day reboot
///
/// The StepCountDB is write-only for now; to be used for graphing and exporting.
///
/// Most important methods to read: main, initPlatformState, onStepCount,
/// stepsAtMidnight, saveData, and of course build().
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

enum RunType {
  firstRunAfterInstall,
  firstRunAfterReboot,
  firstRunOfDay,
  subsequentRunSameDay,
  unknown
}
RunType runType = RunType.unknown;

enum Status {
	Starting,
	Walking,
	Stopped,
	Error,
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StepOnIt Step Counter',
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

int totalSteps = 0;
int stepsToday = 0;
int stepsAtMidnight = 0;

class StepCounterPageState extends State<StepCounterPage> {
  late Stream<StepCount> _stepCountStream;
  late Stream<PedestrianStatus> _pedestrianStatusStream;
  Status _status = Status.Starting;
  bool _firstStepEventReceived = false;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    int? previousBootTimeMillis = prefs.getInt(Constants.KEY_LAST_BOOT_TIME);
    int bootTimeMillis = await BootTimePlugin.getBootTimeMilliseconds();
    await prefs.setInt(Constants.KEY_LAST_BOOT_TIME, bootTimeMillis);

    stepsAtMidnight = prefs.getInt(Constants.keyStepsAtMidnight) ?? 0;
    if (stepsAtMidnight == 0) {
      stepsAtMidnight = 12345;
    }
    totalSteps = prefs.getInt(Constants.keyLastTotalSteps) ?? 0;
    bool newDay = !await stepCountDB.existsForDate(Date.today());

    if (previousBootTimeMillis == null) {
      // first run after app install!
      runType = RunType.firstRunAfterInstall;
    } else if (newDay) {
      if (previousBootTimeMillis != bootTimeMillis) {
        rebootFactor = -stepsAtMidnight;
        runType = RunType.firstRunAfterReboot;
        debugPrint("First run after device reboot; rebootFactor = $rebootFactor");
      } else {
        runType = RunType.firstRunOfDay;
      }
    } else {
      runType = RunType.subsequentRunSameDay;
    }
    debugPrint("RunType: $runType");

    // For mid-day app restarts on the same day, ensure we haven't crossed midnight
    if (!newDay) {
      _ensureResetForNewDay(totalSteps);
    }

    double? savedGoal = prefs.getDouble(Constants.KEY_GOAL_SETTING);

    // Calculate initial _stepsToday from saved data to show the last known count,
    // even though this will be corrected by the first step event.
    if (totalSteps >= stepsAtMidnight) {
      // This MUST agree with the line in onStep()
      stepsToday = totalSteps - stepsAtMidnight + rebootFactor;
    }

    if (savedGoal != null) {
      var goalModel = Provider.of<GoalModel>(context, listen:false);
      goalModel.setGoal(savedGoal);
    }

    if (!await Permission.activityRecognition.isGranted) {
      // if (!mounted) {
      //   return;
      // }
      await Navigator.push(context,
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
      setState(() {
        // just update display
      });
      debugPrint("Initialization completed normally");
    } else {
      debugPrint("Permission denied!");
      setState(() {
        _status = Status.Error;
      });
    }
    await _saveData();
    debugPrint("end of initState: runType $runType, newday = $newDay, steps=$stepsToday");
  }


  void onStepCount(StepCount event) async {
    if (!_firstStepEventReceived) {
      _firstStepEventReceived = true;
      _ensureResetForNewDay(stepsAtMidnight = event.steps);
    }
    totalSteps = event.steps;
    stepsToday = totalSteps - stepsAtMidnight + rebootFactor;
    // debugPrint("_stepsToday $stepsToday");
    setState(() {});
    await _saveData();
  }

  void _ensureResetForNewDay(int currentTotalSteps) async {
    final today = Date.today();
    final lastResetDateString = prefs.getString(Constants.keyLastResetDate);
    
    // Only reset if we have no saved date OR if the saved date is from a different day
    if (lastResetDateString == null) {
      // First ever run
      stepsAtMidnight = currentTotalSteps;
      rebootFactor = 0;
      setState(() {
        stepsToday = 0;
      });
      await _saveData();
    } else {
      // We have a saved date - parse it and compare just the date portion
      final lastResetDate = DateTime.parse(lastResetDateString);
      if (lastResetDate.year != today.year || 
          lastResetDate.month != today.month || 
          lastResetDate.day != today.day) {
        // It's a new day
        stepsAtMidnight = currentTotalSteps;
        rebootFactor = 0;
        setState(() {
          stepsToday = 0;
        });
        await _saveData();
      }
      // If same day, do nothing - keep the saved stepsAtMidnight
    }
  }

  Future<void> _saveData() async {
    await prefs.setInt(Constants.keyStepsAtMidnight, stepsAtMidnight);
    await prefs.setString(Constants.keyLastResetDate, Date.today().toString());
    await prefs.setInt(Constants.keyLastTotalSteps, totalSteps);
    await stepCountDB.setTodayCount(stepsToday);
  }

  void onPedestrianStatusChanged(PedestrianStatus event) {
    debugPrint("ped stat changeL ${event.status}");
    setState(() {
      Status? myStatus;
      for (Status s in Status.values) {
        if (s.name.toLowerCase() == event.status) {
          myStatus = s;
        }
      }
      myStatus ??= Status.Error;
      _status = myStatus;
    });
  }

  void onPedestrianStatusError(dynamic error) {
    setState(() {
      _status = Status.Error;
    });
  }

  void onStepCountError(dynamic error) {
    setState(() {
      totalSteps = 0;
      stepsToday = 0;
    });
  }

  // Last but not least, the all-important widget build method!
  @override
  Widget build(BuildContext context) {
    return Consumer<GoalModel>(
      builder: (context, goalModel, child) {
        double percentage = 100 * stepsToday.toDouble() / goalModel.goal;
        //
        // Clamp values to reasonable.
        if (percentage > 100) {
          // Wahoo! They got more steps than original goal.
          // Should set to percentage and bump max - later XXX
          // Should be a confetti animation here XXX
          // XXX Need to keep 'chosendGoal' and updatedGoal separate??
          // goalModel.setGoal(goalModel.goal * 1.5);
          // percentage = 100 * _stepsToday.toDouble() / goalModel.goal;
          percentage = 100;
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
                      "${label=='Active'?stepsToday.round():(currentGoal-stepsToday).round()} of ${currentGoal.round()}",
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
                  _status == Status.Walking
                      ? Icons.directions_walk
                      : _status == Status.Starting || _status == Status.Stopped
                          ? Icons.accessibility_new
                          : Icons.error,
                  size: 100,
                ),
                Center(
                  child: Text(
                    _status.name[0].toUpperCase() + _status.name.substring(1),
                    style: _status != Status.Error
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
