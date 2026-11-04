import 'dart:convert';

import '../app_database.dart';
import '../daos/workout_dao.dart' show maxReps, maxWeightKg;

/// Marker and version written into every backup file.
const backupFormat = 'workout_tracker_backup';
const backupVersion = 1;

/// Files larger than this are rejected before decoding (a hostile file must not OOM us).
const maxBackupBytes = 20 * 1024 * 1024;

/// The file is not a valid backup. Nothing was written.
class BackupFormatException implements Exception {
  const BackupFormatException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Every row of every table, as drift data classes.
class BackupData {
  const BackupData({
    required this.exercises,
    required this.routines,
    required this.routineExercises,
    required this.sessions,
    required this.sessionExercises,
    required this.sets,
    required this.settings,
  });

  final List<Exercise> exercises;
  final List<Routine> routines;
  final List<RoutineExercise> routineExercises;
  final List<WorkoutSession> sessions;
  final List<SessionExercise> sessionExercises;
  final List<SetEntry> sets;
  final AppSettingsData settings;
}

// ------------------------------------------------------------------- encode

String? _date(DateTime? d) => d?.toUtc().toIso8601String();

/// Serialises [data]. Keys are snake_case column names; dates are ISO-8601 UTC.
String encodeBackup(BackupData data, {required DateTime exportedAt}) {
  final s = data.settings;
  return const JsonEncoder.withIndent(' ').convert({
    'format': backupFormat,
    'version': backupVersion,
    'exported_at': _date(exportedAt),
    'tables': {
      'exercises': [
        for (final e in data.exercises)
          {
            'id': e.id,
            'name': e.name,
            'muscle_group': e.muscleGroup,
            'equipment': e.equipment,
            'description': e.description,
            'gif_asset': e.gifAsset,
            'is_custom': e.isCustom,
            'archived': e.archived,
          },
      ],
      'routines': [
        for (final r in data.routines)
          {
            'id': r.id,
            'name': r.name,
            'notes': r.notes,
            'position': r.position,
            'created_at': _date(r.createdAt),
          },
      ],
      'routine_exercises': [
        for (final r in data.routineExercises)
          {
            'id': r.id,
            'routine_id': r.routineId,
            'exercise_id': r.exerciseId,
            'position': r.position,
            'target_sets': r.targetSets,
            'target_reps': r.targetReps,
            'rest_seconds': r.restSeconds,
            'superset_group': r.supersetGroup,
          },
      ],
      'workout_sessions': [
        for (final w in data.sessions)
          {
            'id': w.id,
            'routine_id': w.routineId,
            'name': w.name,
            'started_at': _date(w.startedAt),
            'ended_at': _date(w.endedAt),
            'notes': w.notes,
          },
      ],
      'session_exercises': [
        for (final e in data.sessionExercises)
          {
            'id': e.id,
            'session_id': e.sessionId,
            'exercise_id': e.exerciseId,
            'position': e.position,
            'superset_group': e.supersetGroup,
            'notes': e.notes,
            'rest_seconds': e.restSeconds,
          },
      ],
      'set_entries': [
        for (final x in data.sets)
          {
            'id': x.id,
            'session_exercise_id': x.sessionExerciseId,
            'position': x.position,
            'weight_kg': x.weightKg,
            'reps': x.reps,
            'set_type': x.setType,
            'rpe': x.rpe,
            'completed_at': _date(x.completedAt),
          },
      ],
      'settings': {
        'unit': s.unit,
        'default_rest_seconds': s.defaultRestSeconds,
        'theme_mode': s.themeMode,
        'legacy_imported_at': _date(s.legacyImportedAt),
      },
    },
  });
}

// ------------------------------------------------------------------- decode

/// Reads one row's fields with type and range checks; errors name table, row, field.
class _Row {
  _Row(this.table, this.index, Object? raw)
    : map = raw is Map<String, Object?>
          ? raw
          : throw BackupFormatException(
              '$table row ${index + 1} is not an object',
            );

  final String table;
  final int index;
  final Map<String, Object?> map;

  Never _bad(String field, String why) =>
      throw BackupFormatException('$table row ${index + 1}: "$field" $why');

  int integer(String f, {int min = 0, int max = 1 << 31}) {
    final v = map[f];
    if (v is! int) _bad(f, 'must be a whole number');
    if (v < min || v > max) _bad(f, 'must be between $min and $max');
    return v;
  }

  int? optInt(String f, {int min = 0, int max = 1 << 31}) =>
      map[f] == null ? null : integer(f, min: min, max: max);

  double number(String f, {double min = 0, double max = double.maxFinite}) {
    final v = map[f];
    if (v is! num || !v.isFinite) _bad(f, 'must be a number');
    if (v < min || v > max) _bad(f, 'must be between $min and $max');
    return v.toDouble();
  }

  double? optNumber(
    String f, {
    double min = 0,
    double max = double.maxFinite,
  }) => map[f] == null ? null : number(f, min: min, max: max);

  String text(String f, {int minLength = 0, int maxLength = 2000}) {
    final v = map[f];
    if (v is! String) _bad(f, 'must be text');
    if (v.length < minLength || v.length > maxLength) {
      _bad(f, 'must be $minLength to $maxLength characters');
    }
    return v;
  }

  String? optText(String f, {int maxLength = 2000}) =>
      map[f] == null ? null : text(f, maxLength: maxLength);

  bool boolean(String f) {
    final v = map[f];
    if (v is! bool) _bad(f, 'must be true or false');
    return v;
  }

  DateTime date(String f) {
    final v = map[f];
    final d = v is String ? DateTime.tryParse(v) : null;
    if (d == null) _bad(f, 'must be an ISO-8601 date');
    return d.toLocal();
  }

  DateTime? optDate(String f) => map[f] == null ? null : date(f);

  String oneOf(String f, Set<String> allowed) {
    final v = text(f, minLength: 1, maxLength: 20);
    if (!allowed.contains(v)) _bad(f, 'must be one of ${allowed.join(', ')}');
    return v;
  }
}

List<Object?> _list(Map<String, Object?> tables, String name) {
  final v = tables[name];
  if (v is! List) throw BackupFormatException('Missing table "$name"');
  return v;
}

/// Ids must be unique and positive; returns them.
Set<int> _ids(String table, Iterable<int> ids) {
  final seen = <int>{};
  for (final id in ids) {
    if (id < 1) throw BackupFormatException('$table has an invalid id $id');
    if (!seen.add(id)) {
      throw BackupFormatException('$table has duplicate id $id');
    }
  }
  return seen;
}

void _ref(String table, String field, int? value, Set<int> targets) {
  if (value != null && !targets.contains(value)) {
    throw BackupFormatException('$table.$field points at missing row $value');
  }
}

const _setTypes = {'normal', 'warmup', 'drop', 'failure'};
const _gifPrefix = 'images/gifs/';

/// Only bundled demonstration GIFs are accepted; anything else is dropped (the app would
/// only ever load bundled assets, but a stray path is not worth keeping).
String? _safeGif(String? path) =>
    path != null &&
        path.startsWith(_gifPrefix) &&
        path.endsWith('.gif') &&
        !path.contains('..')
    ? path
    : null;

/// Parses and fully validates a backup. Throws [BackupFormatException] on any problem.
/// Pure: touches no database.
BackupData decodeBackup(String source) {
  if (utf8.encode(source).length > maxBackupBytes) {
    throw const BackupFormatException('The file is too large to be a backup');
  }
  final Object? root;
  try {
    root = jsonDecode(source);
  } on FormatException {
    throw const BackupFormatException('The file is not valid JSON');
  }
  if (root is! Map<String, Object?> || root['format'] != backupFormat) {
    throw const BackupFormatException('This is not a Workout Tracker backup');
  }
  final version = root['version'];
  if (version is! int) {
    throw const BackupFormatException('The backup has no version');
  }
  if (version > backupVersion) {
    throw BackupFormatException(
      'This backup was made by a newer version of the app (format $version). '
      'Update the app to restore it.',
    );
  }
  if (version < 1) {
    throw BackupFormatException('Unsupported backup version $version');
  }
  final tables = root['tables'];
  if (tables is! Map<String, Object?>) {
    throw const BackupFormatException('The backup has no tables');
  }

  final exercises = [
    for (final (i, raw) in _list(tables, 'exercises').indexed)
      () {
        final r = _Row('exercises', i, raw);
        return Exercise(
          id: r.integer('id'),
          name: r.text('name', minLength: 1, maxLength: 80).trim(),
          muscleGroup: r.text('muscle_group', minLength: 1, maxLength: 40),
          equipment: r.text('equipment', minLength: 1, maxLength: 40),
          description: r.text('description'),
          gifAsset: _safeGif(r.optText('gif_asset', maxLength: 200)),
          isCustom: r.boolean('is_custom'),
          archived: r.boolean('archived'),
        );
      }(),
  ];
  final routines = [
    for (final (i, raw) in _list(tables, 'routines').indexed)
      () {
        final r = _Row('routines', i, raw);
        return Routine(
          id: r.integer('id'),
          name: r.text('name', minLength: 1, maxLength: 80),
          notes: r.optText('notes'),
          position: r.integer('position'),
          createdAt: r.date('created_at'),
        );
      }(),
  ];
  final routineExercises = [
    for (final (i, raw) in _list(tables, 'routine_exercises').indexed)
      () {
        final r = _Row('routine_exercises', i, raw);
        return RoutineExercise(
          id: r.integer('id'),
          routineId: r.integer('routine_id'),
          exerciseId: r.integer('exercise_id'),
          position: r.integer('position'),
          targetSets: r.integer('target_sets', min: 1, max: 50),
          targetReps: r.optInt('target_reps', max: maxReps),
          restSeconds: r.optInt('rest_seconds', max: 3600),
          supersetGroup: r.optInt('superset_group'),
        );
      }(),
  ];
  final sessions = [
    for (final (i, raw) in _list(tables, 'workout_sessions').indexed)
      () {
        final r = _Row('workout_sessions', i, raw);
        return WorkoutSession(
          id: r.integer('id'),
          routineId: r.optInt('routine_id'),
          name: r.text('name', minLength: 1, maxLength: 80),
          startedAt: r.date('started_at'),
          endedAt: r.optDate('ended_at'),
          notes: r.optText('notes'),
        );
      }(),
  ];
  final sessionExercises = [
    for (final (i, raw) in _list(tables, 'session_exercises').indexed)
      () {
        final r = _Row('session_exercises', i, raw);
        return SessionExercise(
          id: r.integer('id'),
          sessionId: r.integer('session_id'),
          exerciseId: r.integer('exercise_id'),
          position: r.integer('position'),
          supersetGroup: r.optInt('superset_group'),
          notes: r.optText('notes'),
          restSeconds: r.optInt('rest_seconds', max: 3600),
        );
      }(),
  ];
  final sets = [
    for (final (i, raw) in _list(tables, 'set_entries').indexed)
      () {
        final r = _Row('set_entries', i, raw);
        return SetEntry(
          id: r.integer('id'),
          sessionExerciseId: r.integer('session_exercise_id'),
          position: r.integer('position'),
          weightKg: r.number('weight_kg', max: maxWeightKg),
          reps: r.integer('reps', max: maxReps),
          setType: r.oneOf('set_type', _setTypes),
          rpe: r.optNumber('rpe', max: 10),
          completedAt: r.optDate('completed_at'),
        );
      }(),
  ];
  final rawSettings = tables['settings'];
  final sr = _Row('settings', 0, rawSettings);
  final settings = AppSettingsData(
    id: 1,
    unit: sr.oneOf('unit', {'kg', 'lb'}),
    defaultRestSeconds: sr.integer('default_rest_seconds', max: 3600),
    themeMode: sr.oneOf('theme_mode', {'system', 'light', 'dark'}),
    legacyImportedAt: sr.optDate('legacy_imported_at'),
  );

  // Referential integrity and uniqueness: the restore must never hit a constraint midway.
  final exerciseIds = _ids('exercises', exercises.map((e) => e.id));
  final names = <String>{};
  for (final e in exercises) {
    if (!names.add(e.name.toLowerCase())) {
      throw BackupFormatException('Two exercises are named "${e.name}"');
    }
  }
  final routineIds = _ids('routines', routines.map((r) => r.id));
  _ids('routine_exercises', routineExercises.map((r) => r.id));
  for (final r in routineExercises) {
    _ref('routine_exercises', 'routine_id', r.routineId, routineIds);
    _ref('routine_exercises', 'exercise_id', r.exerciseId, exerciseIds);
  }
  final sessionIds = _ids('workout_sessions', sessions.map((s) => s.id));
  for (final s in sessions) {
    _ref('workout_sessions', 'routine_id', s.routineId, routineIds);
    if (s.endedAt != null && s.endedAt!.isBefore(s.startedAt)) {
      throw BackupFormatException('Workout ${s.id} ends before it starts');
    }
  }
  if (sessions.where((s) => s.endedAt == null).length > 1) {
    throw const BackupFormatException('More than one workout is in progress');
  }
  final seIds = _ids('session_exercises', sessionExercises.map((e) => e.id));
  for (final e in sessionExercises) {
    _ref('session_exercises', 'session_id', e.sessionId, sessionIds);
    _ref('session_exercises', 'exercise_id', e.exerciseId, exerciseIds);
  }
  _ids('set_entries', sets.map((s) => s.id));
  for (final s in sets) {
    _ref('set_entries', 'session_exercise_id', s.sessionExerciseId, seIds);
  }

  return BackupData(
    exercises: exercises,
    routines: routines,
    routineExercises: routineExercises,
    sessions: sessions,
    sessionExercises: sessionExercises,
    sets: sets,
    settings: settings,
  );
}

// ----------------------------------------------------------------- database

/// Reads every table. The whole database is held in memory; see ARCHITECTURE §9.
Future<BackupData> readBackupData(AppDatabase db) async => BackupData(
  exercises: await db.select(db.exercises).get(),
  routines: await db.select(db.routines).get(),
  routineExercises: await db.select(db.routineExercises).get(),
  sessions: await db.select(db.workoutSessions).get(),
  sessionExercises: await db.select(db.sessionExercises).get(),
  sets: await db.select(db.setEntries).get(),
  settings: await db.settingsDao.getSettings(),
);

/// Replaces ALL data with [data] in one transaction. On any failure the transaction
/// rolls back and existing data is untouched.
Future<void> replaceAllData(AppDatabase db, BackupData data) {
  return db.transaction(() async {
    // Children first (foreign keys are ON).
    await db.delete(db.setEntries).go();
    await db.delete(db.sessionExercises).go();
    await db.delete(db.workoutSessions).go();
    await db.delete(db.routineExercises).go();
    await db.delete(db.routines).go();
    await db.delete(db.exercises).go();
    await db.delete(db.appSettings).go();
    await db.batch((b) {
      b.insertAll(db.exercises, data.exercises);
      b.insertAll(db.routines, data.routines);
      b.insertAll(db.routineExercises, data.routineExercises);
      b.insertAll(db.workoutSessions, data.sessions);
      b.insertAll(db.sessionExercises, data.sessionExercises);
      b.insertAll(db.setEntries, data.sets);
      b.insert(db.appSettings, data.settings);
    });
  });
}

// ---------------------------------------------------------------------- CSV

/// Quotes a CSV field and neutralises spreadsheet formulas (a name like "=HYPERLINK(...)"
/// would otherwise execute when the CSV is opened in a spreadsheet).
String csvField(Object? value) {
  var s = value?.toString() ?? '';
  if (value is String && s.isNotEmpty && '=+-@\t\r'.contains(s[0])) {
    s = "'$s";
  }
  if (s.contains(RegExp('[",\n\r]')) || s != s.trim()) {
    s = '"${s.replaceAll('"', '""')}"';
  }
  return s;
}

/// Every set of every workout, oldest first, one query.
Future<String> exportSetsCsv(AppDatabase db) async {
  final rows = await db
      .customSelect(
        '''
SELECT ws.started_at, ws.name AS workout, e.name AS exercise,
       st.position, st.weight_kg, st.reps, st.set_type, st.rpe, st.completed_at
FROM set_entries st
JOIN session_exercises se ON se.id = st.session_exercise_id
JOIN workout_sessions ws ON ws.id = se.session_id
JOIN exercises e ON e.id = se.exercise_id
ORDER BY ws.started_at, ws.id, se.position, st.position
''',
        readsFrom: {
          db.setEntries,
          db.sessionExercises,
          db.workoutSessions,
          db.exercises,
        },
      )
      .get();
  final out = StringBuffer(
    'date,workout,exercise,set,weight_kg,reps,set_type,rpe,completed\n',
  );
  for (final r in rows) {
    out.writeln(
      [
        csvField(_date(r.read<DateTime>('started_at'))),
        csvField(r.read<String>('workout')),
        csvField(r.read<String>('exercise')),
        csvField(r.read<int>('position') + 1),
        csvField(r.read<double>('weight_kg')),
        csvField(r.read<int>('reps')),
        csvField(r.read<String>('set_type')),
        csvField(r.readNullable<double>('rpe')),
        csvField(
          r.readNullable<DateTime>('completed_at') != null ? 'yes' : 'no',
        ),
      ].join(','),
    );
  }
  return out.toString();
}
