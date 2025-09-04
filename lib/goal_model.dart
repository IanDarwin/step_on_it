import 'package:flutter/material.dart';

import 'main.dart' show defaultGoal;

class GoalModel extends ChangeNotifier {
  int _goal = defaultGoal;

  int get goal => _goal;

  void setGoal(int newGoal, bool notify) {
    _goal = newGoal;
    if (notify) {
      notifyListeners();
    }
  }
}