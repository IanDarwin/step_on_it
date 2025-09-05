import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:provider/provider.dart';

import 'package:step_on_it/constants.dart';
import 'package:step_on_it/main.dart' show defaultGoal, prefs;

import 'goal_model.dart';

/// Activity for Settings.
///
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  SettingsState createState() => SettingsState();
}

class SettingsState extends State<SettingsPage> {

  SettingsState();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Get the provider instance without listening
    final goalModel = Provider.of<GoalModel>(context, listen: false);
    final double goal = goalModel.goal;
    return SettingsScreen(title: "Step On It Settings",
        children: <Widget>[
          SettingsGroup(title: "Fitness",
              children: [
                SliderSettingsTile(
                  title: "Daily Steps Goal",
                  defaultValue: goal,
                  settingKey: Constants.KEY_GOAL_SETTING,
                  min: 500.0,
                  max: goal < defaultGoal ? 1.2 * defaultGoal : 2.0 * goal,
                  step: 250.0,
                  decimalPrecision: 0,
                  subtitleTextStyle: TextStyle(fontSize: 16),
                  onChange: (double value) async {
                    goalModel.setGoal(value);
                    await prefs.setDouble(Constants.KEY_GOAL_SETTING, value);
                  },
                ),
              ],
          ),
          SettingsGroup(
            title: "App Customization",
            children: [
              DropDownSettingsTile<int>(
                title: 'History to Keep & display',
                selected: 0,
                settingKey: Constants.KEY_DUMMY,
                  values: {
                    0: "Don't save",
                    1: "1 day",
                    2: "2",
                    3: "3",
                    4: "4",
                    5: "5",
                    6: "6",
                    7: "7",
                }
              ),
              SwitchSettingsTile(
                title: "Dark mode",
                  leading: Icon(Icons.dark_mode),
                  settingKey: Constants.KEY_DARK_MODE,
                  onChange: (val) {
                    print("Change will take effect on app restart");
                  })
              ],
        )
      ]
    );
  }

  @override
  void dispose() {
	// Do we need anything here?
	super.dispose();
  }
}




