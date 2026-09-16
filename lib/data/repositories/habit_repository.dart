import '../models/habit_model.dart';

abstract class HabitRepository {
  Future<List<HabitModel>> getTodayHabits();
  Future<void> toggleHabitCompletion(String id);
}
