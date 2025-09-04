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
                SliderSettingsTile(
                  title: "Daily Steps Goal",
                  defaultValue: 1.0*goal,
                  settingKey: Constants.KEY_GOAL_SETTING,
                  min: 100,
                  max: 1.0*goal,
                  step: 100,
                  onChange: (value) {
                      goal = value.toInt();
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




