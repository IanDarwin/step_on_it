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
    final int goal = goalModel.goal;
    return SettingsScreen(title: "Step On It Settings",
        children: <Widget>[
          SettingsGroup(title: "Personalization",
              children: [
                SliderSettingsTile(
                  title: "Daily Steps Goal",
                  defaultValue: goal.toDouble(),
                  settingKey: Constants.KEY_GOAL_SETTING,
                  min: 100.0,
                  max: goal < defaultGoal ? 1.2 * defaultGoal : 2.0 * goal,
                  step: 100.0,
                  onChange: (double value) async {
					          goalModel.setGoal(value.round());
                    await prefs.setInt(Constants.KEY_GOAL_SETTING, value.round());
				          },
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




