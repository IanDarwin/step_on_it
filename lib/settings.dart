import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';

import 'package:step_on_it/main.dart' show prefs, goal;

import 'constants.dart';

/// Activity for Settings.
///
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  SettingsState createState() => new SettingsState();
}

class SettingsState extends State<SettingsPage> {

  SettingsState();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return SettingsScreen(title: "StepOnIt Settings",
        children: <Widget>[
          SettingsGroup(title: "Personalization",
              children: [
                TextInputSettingsTile(
                  title: "Daily Steps Goal",
                  initialValue: goal.toString(),
                  settingKey: Constants.KEY_DAILY_GOAL,
                  keyboardType: TextInputType.numberWithOptions(signed:false, decimal:false),
                  validator: (stepsGoal) {
                    // Must be a valid number
                    if (stepsGoal != null && stepsGoal.isNotEmpty &&
                        RegExp(r'^\d+$').hasMatch(stepsGoal)) {
                      goal = int.parse(stepsGoal);
                      // XXX Propagate value
                      return null;
                    }
                    return "Daily steps goal must be numeric digits.";
                  },
                  errorColor: Colors.redAccent,
                ),
              ]),
          SettingsGroup(
            title: "More stuff?",
            children: [
              DropDownSettingsTile<int>(
                title: 'Something',
                selected: 1,
                settingKey: Constants.KEY_DUMMY,
                  values: {
                  1: "1",
                  2: "2",
                  3: "3",
                  4: "4",
                  5: "5",
                }
              ),
            ],
          ),
          SettingsGroup(
            title: "Personalization",
            children: [
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




