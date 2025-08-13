import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:convert';

import '../../../common/common_function.dart';
import '../../workout_screen/model/workout_model.dart';

part 'workout_list_provider.g.dart';

/// This provider manages the list of workouts, allowing for adding, updating, deleting, and clearing workouts.
@riverpod
class WorkoutList extends _$WorkoutList {
  final _key = 'workoutList';

  @override
  List<WorkoutModel> build() {
    final savedData = storage.read<String>(_key);
    if (savedData != null) {
      try {
        final decoded = jsonDecode(savedData) as List;
        return decoded.map((e) => WorkoutModel.fromJson(e)).toList();
      } catch (e) {
        // Handle JSON decode error
        debugPrint('Error decoding workout list: $e');
      }
    }
    return [];
  }

  // Adds a new workout to the list and saves it to storage.
  void addWorkout(WorkoutModel workout) {
    state = [...state, workout];
    _saveToStorage();
  }

  // Updates an existing workout in the list and saves it to storage.
  void updateWorkout(WorkoutModel oldWorkout, WorkoutModel newWorkout) {
    final index = state.indexOf(oldWorkout);
    if (index != -1) {
      state = [
        ...state.sublist(0, index),
        newWorkout,
        ...state.sublist(index + 1),
      ];
      _saveToStorage();
    }
  }

  // Deletes a workout from the list by its index and saves the updated list to storage.
  void deleteWorkout(int index) {
    state = [...state]..removeAt(index);
    _saveToStorage();
  }

  // Clears all workouts from the list and saves the empty list to storage.
  void clearWorkouts() {
    state = [];
    _saveToStorage();
  }

  // Saves the current state of workouts to persistent storage.
  void _saveToStorage() {
    final encoded = jsonEncode(state.map((e) => e.toJson()).toList());
    storage.write(_key, encoded);
  }
}
