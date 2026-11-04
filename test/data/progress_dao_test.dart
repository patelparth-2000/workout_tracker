import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/data/app_database.dart';
import 'package:workout_tracker/utils/workout_math.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  final t0 = DateTime(2026, 3, 1, 9);
  DateTime day(int d) => t0.add(Duration(days: d));

  setUp(() => db = testDatabase());
  tearDown(() => db.close());

  Future<int> squat() => exerciseId(db, 'Squat');

  group('bests', () {
    test('no data: everything null, count 0', () async {
      final b = await db.progressDao.watchBests(await squat()).first;
      expect(b.bestWeightKg, isNull);
      expect(b.bestE1rmKg, isNull);
      expect(b.bestSessionVolumeKg, isNull);
      expect(b.sessionCount, 0);
    });

    test(
      'best weight, best e1RM and best volume session are computed in SQL',
      () async {
        await logFinishedSession(
          db,
          exercise: 'Squat',
          at: day(0),
          sets: [(100, 5), (100, 5)],
        );
        await logFinishedSession(
          db,
          exercise: 'Squat',
          at: day(1),
          sets: [(120, 1)],
        );
        await logFinishedSession(
          db,
          exercise: 'Squat',
          at: day(2),
          sets: [(90, 10)],
        );
        final b = await db.progressDao.watchBests(await squat()).first;
        expect(b.bestWeightKg, 120);
        // 90 x 10 -> 120 ; 100 x 5 -> 116.67 ; 120 x 1 -> 120. Same as the Dart formula.
        expect(b.bestE1rmKg, closeTo(estimatedOneRepMax(90, 10)!, 1e-9));
        expect(b.bestSessionVolumeKg, 1000);
        expect(b.bestVolumeAt, day(0));
        expect(b.sessionCount, 3);
      },
    );

    test(
      'ignores incomplete sets, zero reps / weight, and unfinished sessions',
      () async {
        await logFinishedSession(
          db,
          exercise: 'Squat',
          at: day(0),
          sets: [(500, 5)],
          completed: false,
        );
        await logFinishedSession(
          db,
          exercise: 'Squat',
          at: day(1),
          sets: [(300, 0), (0, 20), (60, 5)],
        );
        final active = await db.workoutDao.startSession(name: 'A', now: day(2));
        final se = await db.workoutDao.addExercise(active, await squat());
        final setId = (await db.select(db.setEntries).get()).last.id;
        await db.workoutDao.updateSet(setId, weightKg: 400, reps: 3);
        await db.workoutDao.setCompleted(setId, completed: true, now: day(2));
        expect(se, isPositive);
        final b = await db.progressDao.watchBests(await squat()).first;
        expect(b.bestWeightKg, 60);
        expect(b.bestE1rmKg, closeTo(estimatedOneRepMax(60, 5)!, 1e-9));
        expect(b.sessionCount, 1);
      },
    );
  });

  test(
    'series: one point per finished session, oldest first, range filter',
    () async {
      await logFinishedSession(
        db,
        exercise: 'Squat',
        at: day(0),
        sets: [(100, 5)],
      );
      await logFinishedSession(
        db,
        exercise: 'Squat',
        at: day(10),
        sets: [(110, 5), (50, 10)],
      );
      final all = await db.progressDao.watchSeries(await squat()).first;
      expect(all.map((p) => p.at), [day(0), day(10)]);
      expect(all.last.volumeKg, 1050);
      expect(all.last.topWeightKg, 110);
      expect(all.last.e1rmKg, closeTo(estimatedOneRepMax(110, 5)!, 1e-9));
      final recent = await db.progressDao
          .watchSeries(await squat(), since: day(5))
          .first;
      expect(recent.map((p) => p.at), [day(10)]);
    },
  );

  test(
    'exercises with history: most recent first, only completed work',
    () async {
      await logFinishedSession(
        db,
        exercise: 'Bench press',
        at: day(0),
        sets: [(60, 5)],
      );
      await logFinishedSession(
        db,
        exercise: 'Squat',
        at: day(1),
        sets: [(100, 5)],
      );
      await logFinishedSession(
        db,
        exercise: 'Bicep curl',
        at: day(2),
        sets: [(10, 5)],
        completed: false,
      );
      final list = await db.progressDao.watchExercisesWithHistory().first;
      expect(list.map((e) => e.exercise.name), ['Squat', 'Bench press']);
      expect(list.first.lastAt, day(1));
      expect(list.first.sessionCount, 1);
    },
  );

  group('records', () {
    Future<Set<int>> records(int sessionId) =>
        db.progressDao.watchRecordSetIds(sessionId).first;
    Future<List<SetEntry>> setsOf(int sessionId) async {
      final d = (await db.workoutDao.watchSessionDetail(sessionId).first)!;
      return d.exercises.expand((e) => e.sets).toList();
    }

    test('first-ever log sets the baseline: no record', () async {
      final s = await logFinishedSession(
        db,
        exercise: 'Squat',
        at: day(0),
        sets: [(100, 5)],
      );
      expect(await records(s), isEmpty);
    });

    test(
      'beating the prior best e1RM marks only the best set of the session',
      () async {
        await logFinishedSession(
          db,
          exercise: 'Squat',
          at: day(0),
          sets: [(100, 5)],
        );
        final s = await logFinishedSession(
          db,
          exercise: 'Squat',
          at: day(1),
          sets: [(102, 5), (105, 5), (90, 3)],
        );
        final sets = await setsOf(s);
        expect(await records(s), {sets[1].id});
      },
    );

    test('a tie is not a record', () async {
      await logFinishedSession(
        db,
        exercise: 'Squat',
        at: day(0),
        sets: [(100, 5)],
      );
      final s = await logFinishedSession(
        db,
        exercise: 'Squat',
        at: day(1),
        sets: [(100, 5)],
      );
      expect(await records(s), isEmpty);
    });

    test('reps 1 counts as its weight; reps 0 never counts', () async {
      await logFinishedSession(
        db,
        exercise: 'Squat',
        at: day(0),
        sets: [(100, 5)],
      ); // 116.7
      final s1 = await logFinishedSession(
        db,
        exercise: 'Squat',
        at: day(1),
        sets: [(117, 1)],
      );
      expect(await records(s1), hasLength(1));
      final s2 = await logFinishedSession(
        db,
        exercise: 'Squat',
        at: day(2),
        sets: [(500, 0)],
      );
      expect(await records(s2), isEmpty);
    });

    test(
      'only EARLIER sessions are compared (an old session is not re-judged)',
      () async {
        final old = await logFinishedSession(
          db,
          exercise: 'Squat',
          at: day(0),
          sets: [(80, 5)],
        );
        await logFinishedSession(
          db,
          exercise: 'Squat',
          at: day(1),
          sets: [(100, 5)],
        );
        final mid = await logFinishedSession(
          db,
          exercise: 'Squat',
          at: day(2),
          sets: [(90, 5)],
        );
        expect(await records(old), isEmpty);
        expect(await records(mid), isEmpty);
      },
    );

    test('a record stays a record after it is beaten later', () async {
      await logFinishedSession(
        db,
        exercise: 'Squat',
        at: day(0),
        sets: [(80, 5)],
      );
      final s2 = await logFinishedSession(
        db,
        exercise: 'Squat',
        at: day(1),
        sets: [(100, 5)],
      );
      await logFinishedSession(
        db,
        exercise: 'Squat',
        at: day(2),
        sets: [(120, 5)],
      );
      expect(await records(s2), {(await setsOf(s2)).single.id});
    });

    test('records in the active session against finished history', () async {
      await logFinishedSession(
        db,
        exercise: 'Squat',
        at: day(0),
        sets: [(100, 5)],
      );
      final active = await db.workoutDao.startSession(name: 'Now', now: day(1));
      await db.workoutDao.addExercise(active, await squat());
      final set = (await setsOf(active)).single;
      await db.workoutDao.updateSet(set.id, weightKg: 110, reps: 5);
      expect(await records(active), isEmpty); // not completed yet
      await db.workoutDao.setCompleted(set.id, completed: true, now: day(1));
      expect(await records(active), {set.id});
    });
  });
}
