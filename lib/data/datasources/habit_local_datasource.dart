import '../models/habit_model.dart';

abstract class HabitLocalDataSource {
  Future<List<HabitModel>> getTodayHabits();
  Future<void> saveHabits(List<HabitModel> habits);
}
