import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:convert';

import '../../../common/common_function.dart';
import '../../workout_screen/model/workout_model.dart';

part 'workout_list_provider.g.dart';

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

  void addWorkout(WorkoutModel workout) {
    state = [...state, workout];
    _saveToStorage();
  }

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

  void deleteWorkout(int index) {
    state = [...state]..removeAt(index);
    _saveToStorage();
  }

  void clearWorkouts() {
    state = [];
    _saveToStorage();
  }

  void _saveToStorage() {
    final encoded = jsonEncode(state.map((e) => e.toJson()).toList());
    storage.write(_key, encoded);
  }
}
