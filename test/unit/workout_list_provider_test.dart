// Characterisation tests: they pin the CURRENT behaviour of the v1 WorkoutList provider,
// bugs included, so the v2 migration can prove what data it must preserve.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:workout_tracker/common/common_function.dart';
import 'package:workout_tracker/src/workout_list_screen/viewmodel/workout_list_provider.dart';
import 'package:workout_tracker/src/workout_screen/model/workout_model.dart';

const _key = 'workoutList';

WorkoutModel _model(String type, {String weight = '50'}) => WorkoutModel(
  type: type,
  weight: weight,
  reps: '10',
  sets: '3',
  icon: 'images/gifs/workout_squat.gif',
  description: 'd',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tmp;

  setUpAll(() async {
    tmp = await Directory.systemTemp.createTemp('wt_getstorage_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => tmp.path,
        );
    await GetStorage('GetStorage', tmp.path).initStorage;
  });

  tearDownAll(() async {
    if (tmp.existsSync()) await tmp.delete(recursive: true);
  });

  setUp(() async {
    await storage.erase();
  });

  ProviderContainer makeContainer() {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  group('WorkoutList (v1 characterisation)', () {
    test('starts empty when nothing is stored', () {
      expect(makeContainer().read(workoutListProvider), isEmpty);
    });

    test('addWorkout appends and writes the whole list as one JSON string', () {
      final c = makeContainer();
      c.read(workoutListProvider.notifier).addWorkout(_model('Squat'));
      c.read(workoutListProvider.notifier).addWorkout(_model('Deadlift'));

      expect(c.read(workoutListProvider).map((w) => w.type), [
        'Squat',
        'Deadlift',
      ]);
      final raw = storage.read<String>(_key)!;
      final decoded = jsonDecode(raw) as List;
      expect(decoded, hasLength(2));
      expect(decoded.first, {
        'type': 'Squat',
        'weight': '50',
        'reps': '10',
        'sets': '3',
        'icon': 'images/gifs/workout_squat.gif',
        'description': 'd',
      });
    });

    test('a fresh container reads back what was persisted', () {
      makeContainer().read(workoutListProvider.notifier).addWorkout(
        _model('Squat', weight: '80'),
      );
      final again = makeContainer().read(workoutListProvider);
      expect(again, hasLength(1));
      expect(again.single.weight, '80');
    });

    test('updateWorkout replaces the entry when given the same instance', () {
      final c = makeContainer();
      final n = c.read(workoutListProvider.notifier);
      n.addWorkout(_model('Squat'));
      final original = c.read(workoutListProvider).single;
      n.updateWorkout(original, _model('Squat', weight: '99'));
      expect(c.read(workoutListProvider).single.weight, '99');
    });

    test('updateWorkout with an equal COPY is a silent no-op (identity bug)', () {
      final c = makeContainer();
      final n = c.read(workoutListProvider.notifier);
      n.addWorkout(_model('Squat'));
      final copy = WorkoutModel.fromJson(
        c.read(workoutListProvider).single.toJson(),
      );
      n.updateWorkout(copy, _model('Squat', weight: '99'));
      expect(c.read(workoutListProvider).single.weight, '50');
    });

    test('deleteWorkout removes by index and persists', () {
      final c = makeContainer();
      final n = c.read(workoutListProvider.notifier);
      n.addWorkout(_model('Squat'));
      n.addWorkout(_model('Deadlift'));
      n.deleteWorkout(0);
      expect(c.read(workoutListProvider).single.type, 'Deadlift');
      expect(jsonDecode(storage.read<String>(_key)!) as List, hasLength(1));
    });

    test('clearWorkouts empties the list and stores "[]"', () {
      final c = makeContainer();
      final n = c.read(workoutListProvider.notifier);
      n.addWorkout(_model('Squat'));
      n.clearWorkouts();
      expect(c.read(workoutListProvider), isEmpty);
      expect(storage.read<String>(_key), '[]');
    });

    test('corrupt JSON is treated as empty (bug: hides data loss)', () async {
      await storage.write(_key, '{not json');
      expect(makeContainer().read(workoutListProvider), isEmpty);
    });

    test('the next write after corrupt JSON destroys the corrupt data', () async {
      await storage.write(_key, '{not json');
      makeContainer().read(workoutListProvider.notifier).addWorkout(
        _model('Squat'),
      );
      expect(storage.read<String>(_key), isNot(contains('not json')));
    });

    test('valid JSON that is not a list is treated as empty', () async {
      await storage.write(_key, '{"type":"Squat"}');
      expect(makeContainer().read(workoutListProvider), isEmpty);
    });
  });

  group('WorkoutModel JSON (legacy format)', () {
    test('round-trips every field as a String', () {
      final m = _model('Bench press', weight: '10 ');
      final back = WorkoutModel.fromJson(m.toJson());
      expect(back.toJson(), m.toJson());
      expect(back.weight, '10 ');
    });
  });
}
