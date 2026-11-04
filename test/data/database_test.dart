import 'package:drift/native.dart' show SqliteException;
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/data/app_database.dart';
import 'package:workout_tracker/data/daos/exercise_dao.dart';
import 'package:workout_tracker/data/daos/workout_dao.dart';
import 'package:workout_tracker/data/models.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  final t0 = DateTime(2026, 1, 1, 10);

  setUp(() => db = testDatabase());
  tearDown(() => db.close());

  group('schema', () {
    test(
      'creates the settings row with defaults and seeds exercises',
      () async {
        final s = await db.settingsDao.getSettings();
        expect(s.unit, 'kg');
        expect(s.defaultRestSeconds, 90);
        expect(s.themeMode, 'system');
        expect(s.legacyImportedAt, isNull);
        expect(await db.select(db.exercises).get(), hasLength(3));
      },
    );

    test('foreign keys are enforced', () async {
      expect(
        () => db
            .into(db.sessionExercises)
            .insert(
              SessionExercisesCompanion.insert(
                sessionId: 999,
                exerciseId: 1,
                position: 0,
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('an exercise used by history cannot be deleted', () async {
      await logFinishedSession(db, exercise: 'Squat', at: t0, sets: [(100, 5)]);
      final id = await exerciseId(db, 'Squat');
      expect(
        () => (db.delete(db.exercises)..where((e) => e.id.equals(id))).go(),
        throwsA(isA<SqliteException>()),
      );
    });

    test('indexes exist', () async {
      final rows = await db
          .customSelect("SELECT name FROM sqlite_master WHERE type = 'index'")
          .get();
      final names = rows.map((r) => r.read<String>('name')).toSet();
      expect(
        names,
        containsAll([
          'idx_workout_sessions_started_at',
          'idx_session_exercises_session_id',
          'idx_session_exercises_exercise_id',
          'idx_set_entries_session_exercise_id',
        ]),
      );
    });
  });

  group('ExerciseDao', () {
    test('search is case-insensitive substring, filters combine', () async {
      final dao = db.exerciseDao;
      expect(
        (await dao.watchExercises(query: 'PRESS').first).map((e) => e.name),
        ['Bench press'],
      );
      expect(
        (await dao.watchExercises(equipment: 'Barbell').first).map(
          (e) => e.name,
        ),
        ['Bench press', 'Squat'],
      );
      expect(
        await dao
            .watchExercises(equipment: 'Barbell', muscleGroup: 'Biceps')
            .first,
        isEmpty,
      );
    });

    test('LIKE wildcards in the query are literal', () async {
      expect(await db.exerciseDao.watchExercises(query: '%').first, isEmpty);
      expect(await db.exerciseDao.watchExercises(query: '_').first, isEmpty);
    });

    test('custom create rejects case-insensitive duplicates', () async {
      final dao = db.exerciseDao;
      final id = await dao.createCustom(
        name: '  Cable fly ',
        muscleGroup: 'Chest',
        equipment: 'Cable',
      );
      final created = (await dao.getById(id))!;
      expect(created.name, 'Cable fly');
      expect(created.isCustom, isTrue);
      expect(
        () => dao.createCustom(name: 'squat', muscleGroup: 'x', equipment: 'y'),
        throwsA(isA<DuplicateExerciseNameException>()),
      );
    });

    test(
      'updateCustom edits customs only; archive hides from the list',
      () async {
        final dao = db.exerciseDao;
        final squat = await exerciseId(db, 'Squat');
        await dao.updateCustom(
          id: squat,
          name: 'Renamed',
          muscleGroup: 'Quads',
          equipment: 'Barbell',
        );
        expect((await dao.getById(squat))!.name, 'Squat');

        await dao.setArchived(squat, true);
        expect(
          (await dao.watchExercises().first).map((e) => e.name),
          isNot(contains('Squat')),
        );
        expect(
          (await dao.watchExercises(includeArchived: true).first).map(
            (e) => e.name,
          ),
          contains('Squat'),
        );
      },
    );

    test('distinct muscle groups and equipment', () async {
      expect(await db.exerciseDao.watchMuscleGroups().first, [
        'Biceps',
        'Chest',
        'Quads',
      ]);
      expect(await db.exerciseDao.watchEquipment().first, [
        'Barbell',
        'Dumbbell',
      ]);
    });
  });

  group('RoutineDao', () {
    test(
      'save, read back in order, update replaces items, delete cascades',
      () async {
        final dao = db.routineDao;
        final squat = await exerciseId(db, 'Squat');
        final bench = await exerciseId(db, 'Bench press');
        final id = await dao.saveRoutine(
          name: ' Push ',
          notes: '  ',
          items: [
            RoutineExerciseDraft(
              exerciseId: bench,
              targetSets: 4,
              restSeconds: 120,
            ),
            RoutineExerciseDraft(exerciseId: squat, targetReps: 5),
          ],
          now: t0,
        );
        var detail = (await dao.getRoutine(id))!;
        expect(detail.routine.name, 'Push');
        expect(detail.routine.notes, isNull);
        expect(detail.exercises.map((e) => e.exercise.name), [
          'Bench press',
          'Squat',
        ]);
        expect(detail.exercises.first.entry.targetSets, 4);

        final summaries = await dao.watchRoutines().first;
        expect(summaries.single.exerciseCount, 2);

        await dao.saveRoutine(
          id: id,
          name: 'Push',
          items: [RoutineExerciseDraft(exerciseId: squat)],
          now: t0,
        );
        detail = (await dao.getRoutine(id))!;
        expect(detail.exercises.map((e) => e.exercise.name), ['Squat']);

        await dao.deleteRoutine(id);
        expect(await dao.getRoutine(id), isNull);
        expect(await db.select(db.routineExercises).get(), isEmpty);
      },
    );

    test('an empty routine lists with count 0', () async {
      await db.routineDao.saveRoutine(name: 'Empty', items: const [], now: t0);
      expect(
        (await db.routineDao.watchRoutines().first).single.exerciseCount,
        0,
      );
    });
  });

  group('WorkoutDao', () {
    test('only one active session at a time', () async {
      final dao = db.workoutDao;
      final id = await dao.startSession(name: '', now: t0);
      expect((await dao.getActiveSession())!.name, 'Workout');
      expect(
        () => dao.startSession(name: 'Second', now: t0),
        throwsA(isA<ActiveSessionExistsException>()),
      );
      await dao.finishSession(id, t0.add(const Duration(minutes: 30)));
      expect(await dao.getActiveSession(), isNull);
    });

    test(
      'starting from a routine copies exercises, sets, rest, previous values',
      () async {
        final squat = await exerciseId(db, 'Squat');
        await logFinishedSession(
          db,
          exercise: 'Squat',
          at: t0,
          sets: [(100, 5), (105, 3)],
        );
        final routineId = await db.routineDao.saveRoutine(
          name: 'Legs',
          items: [
            RoutineExerciseDraft(
              exerciseId: squat,
              targetSets: 3,
              restSeconds: 180,
            ),
          ],
          now: t0,
        );
        final sid = await db.workoutDao.startSession(
          name: 'Legs',
          routineId: routineId,
          now: t0.add(const Duration(days: 1)),
        );
        final detail = (await db.workoutDao.watchSessionDetail(sid).first)!;
        final ex = detail.exercises.single;
        expect(ex.entry.restSeconds, 180);
        // 3 target sets; previous had 2 -> third repeats the last previous set.
        expect(ex.sets.map((s) => (s.weightKg, s.reps)), [
          (100.0, 5),
          (105.0, 3),
          (105.0, 3),
        ]);
        expect(ex.sets.every((s) => s.completedAt == null), isTrue);
      },
    );

    test('add / move / remove exercises keeps positions dense', () async {
      final dao = db.workoutDao;
      final sid = await dao.startSession(name: 'W', now: t0);
      final a = await dao.addExercise(sid, await exerciseId(db, 'Squat'));
      await dao.addExercise(sid, await exerciseId(db, 'Bench press'));
      await dao.addExercise(sid, await exerciseId(db, 'Bicep curl'));
      await dao.moveSessionExercise(sid, 2, 0);
      var d = (await dao.watchSessionDetail(sid).first)!;
      expect(d.exercises.map((e) => e.exercise.name), [
        'Bicep curl',
        'Squat',
        'Bench press',
      ]);
      await dao.removeSessionExercise(a);
      d = (await dao.watchSessionDetail(sid).first)!;
      expect(d.exercises.map((e) => e.exercise.name), [
        'Bicep curl',
        'Bench press',
      ]);
      expect(d.exercises.map((e) => e.entry.position), [0, 1]);
      // A new exercise with no history starts with exactly one empty set.
      expect(d.exercises.first.sets.single.weightKg, 0);
    });

    test(
      'sets: add copies last, remove renumbers, update validates, complete toggles',
      () async {
        final dao = db.workoutDao;
        final sid = await dao.startSession(name: 'W', now: t0);
        final se = await dao.addExercise(sid, await exerciseId(db, 'Squat'));
        var sets =
            (await dao.watchSessionDetail(sid).first)!.exercises.single.sets;
        await dao.updateSet(sets.first.id, weightKg: 60, reps: 8);
        await dao.addSet(se);
        await dao.addSet(se);
        sets = (await dao.watchSessionDetail(sid).first)!.exercises.single.sets;
        expect(sets.map((s) => (s.position, s.weightKg, s.reps)), [
          (0, 60.0, 8),
          (1, 60.0, 8),
          (2, 60.0, 8),
        ]);
        await dao.removeSet(sets[1].id);
        sets = (await dao.watchSessionDetail(sid).first)!.exercises.single.sets;
        expect(sets.map((s) => s.position), [0, 1]);

        expect(
          () => dao.updateSet(sets.first.id, weightKg: -1, reps: 5),
          throwsRangeError,
        );
        expect(
          () => dao.updateSet(sets.first.id, weightKg: 10, reps: 1001),
          throwsRangeError,
        );

        await dao.setCompleted(sets.first.id, completed: true, now: t0);
        sets = (await dao.watchSessionDetail(sid).first)!.exercises.single.sets;
        expect(sets.first.completedAt, t0);
        await dao.setCompleted(sets.first.id, completed: false, now: t0);
        sets = (await dao.watchSessionDetail(sid).first)!.exercises.single.sets;
        expect(sets.first.completedAt, isNull);
      },
    );

    test('deleting a session cascades to exercises and sets', () async {
      final sid = await logFinishedSession(
        db,
        exercise: 'Squat',
        at: t0,
        sets: [(1, 1)],
      );
      await db.workoutDao.deleteSession(sid);
      expect(await db.select(db.sessionExercises).get(), isEmpty);
      expect(await db.select(db.setEntries).get(), isEmpty);
    });

    test(
      'previous values come from the latest FINISHED session only',
      () async {
        final dao = db.workoutDao;
        final squat = await exerciseId(db, 'Squat');
        expect(await dao.previousSetsFor([squat]), isEmpty);
        await logFinishedSession(
          db,
          exercise: 'Squat',
          at: t0,
          sets: [(80, 5)],
        );
        await logFinishedSession(
          db,
          exercise: 'Squat',
          at: t0.add(const Duration(days: 2)),
          sets: [(90, 5), (95, 3)],
        );
        final active = await dao.startSession(
          name: 'Now',
          now: t0.add(const Duration(days: 3)),
        );
        await dao.addExercise(active, squat);
        final prev = await dao.previousSetsFor([
          squat,
        ], excludeSessionId: active);
        expect(prev[squat]!.map((s) => s.weightKg), [90.0, 95.0]);
        final watched = await dao.watchPreviousSetsForSession(active).first;
        expect(watched[squat]!.map((s) => s.weightKg), [90.0, 95.0]);
      },
    );

    test('an unfinished session never counts as "previous"', () async {
      final dao = db.workoutDao;
      final squat = await exerciseId(db, 'Squat');
      await logFinishedSession(db, exercise: 'Squat', at: t0, sets: [(80, 5)]);
      final active = await dao.startSession(
        name: 'Now',
        now: t0.add(const Duration(days: 1)),
      );
      final se = await dao.addExercise(active, squat);
      final setId = (await dao.watchSessionDetail(active).first)!
          .exercises
          .single
          .sets
          .single
          .id;
      await dao.updateSet(setId, weightKg: 200, reps: 1);
      expect(se, isPositive);
      // No exclusion given: the in-progress 200 kg must still not be returned.
      final prev = await dao.previousSetsFor([squat]);
      expect(prev[squat]!.map((s) => s.weightKg), [80.0]);
    });

    group('history paging', () {
      Future<void> seedSessions(int n) async {
        for (var i = 0; i < n; i++) {
          await logFinishedSession(
            db,
            exercise: 'Squat',
            at: t0.add(Duration(days: i)),
            sets: [(100, 5)],
          );
        }
      }

      Future<List<SessionSummary>> all(int pageSize) async {
        final out = <SessionSummary>[];
        HistoryCursor? cursor;
        while (true) {
          final page = await db.workoutDao.historyPage(
            before: cursor,
            limit: pageSize,
          );
          out.addAll(page);
          if (page.length < pageSize) return out;
          cursor = HistoryCursor(
            startedAt: page.last.session.startedAt,
            id: page.last.session.id,
          );
        }
      }

      for (final n in [0, 1, 5, 6]) {
        test(
          '$n sessions with page size 5: all returned once, newest first',
          () async {
            await seedSessions(n);
            final got = await all(5);
            expect(got, hasLength(n));
            expect(got.map((s) => s.session.id).toSet(), hasLength(n));
            for (var i = 1; i < got.length; i++) {
              expect(
                got[i - 1].session.startedAt.isAfter(got[i].session.startedAt),
                isTrue,
              );
            }
          },
        );
      }

      test('same start time is split by id without duplicates', () async {
        for (var i = 0; i < 4; i++) {
          await logFinishedSession(
            db,
            exercise: 'Squat',
            at: t0,
            sets: [(1, 1)],
          );
        }
        final got = await all(3);
        expect(got.map((s) => s.session.id).toSet(), hasLength(4));
      });

      test(
        'active session is excluded; volume counts completed sets only',
        () async {
          await logFinishedSession(
            db,
            exercise: 'Squat',
            at: t0,
            sets: [(100, 5), (50, 10)],
          );
          await logFinishedSession(
            db,
            exercise: 'Squat',
            at: t0.add(const Duration(days: 1)),
            sets: [(100, 5)],
            completed: false,
          );
          await db.workoutDao.startSession(
            name: 'Active',
            now: t0.add(const Duration(days: 2)),
          );
          final page = await db.workoutDao.historyPage();
          expect(page, hasLength(2));
          expect(page.first.volumeKg, 0);
          expect(page.first.completedSetCount, 0);
          expect(page.last.volumeKg, 1000);
          expect(page.last.completedSetCount, 2);
          expect(page.last.exerciseCount, 1);
          expect(page.last.duration, const Duration(hours: 1));
        },
      );
    });
  });

  group('SettingsDao', () {
    test('writes and validates', () async {
      final dao = db.settingsDao;
      await dao.setUnit('lb');
      await dao.setDefaultRestSeconds(120);
      await dao.setThemeMode('dark');
      final s = await dao.getSettings();
      expect((s.unit, s.defaultRestSeconds, s.themeMode), ('lb', 120, 'dark'));
      expect(() => dao.setUnit('st'), throwsArgumentError);
      expect(() => dao.setThemeMode('blue'), throwsArgumentError);
      expect(() => dao.setDefaultRestSeconds(-1), throwsRangeError);
    });

    test('recreates a missing settings row', () async {
      await db.delete(db.appSettings).go();
      expect((await db.settingsDao.getSettings()).unit, 'kg');
    });
  });
}
