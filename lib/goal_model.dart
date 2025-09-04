import 'package:flutter/material.dart';

import 'main.dart' show defaultGoal;

class GoalModel extends ChangeNotifier {
  double _goal = defaultGoal.toDouble();

  double get goal => _goal;

  void setGoal(double newGoal) {
    _goal = newGoal;
    notifyListeners();
  }
}
