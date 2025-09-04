import 'package:step_on_it/goal_model.dart';
import 'package:test/test.dart';

  void main() {
    test('Setting goal value works', () {
      final goal = GoalModel();
      print("Initial goal setting ${goal.goal}");
      final newGoal = 7500.0;
      bool called = false;
      goal.addListener(() {
        print("kilroy was here");
        called = true;
      });
      goal.setGoal(newGoal);
      expect(called, true);
      expect(goal.goal, newGoal);
    });
  }
