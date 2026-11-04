import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/backup/backup_codec.dart';
import '../../../data/database_provider.dart';
import '../../../utils/clock.dart';

part 'backup_controller.g.dart';

/// OS integration for backups (share sheet, file picker). Overridden in tests.
class BackupPlatform {
  const BackupPlatform();

  /// Writes [contents] to a temporary file and opens the share sheet for it.
  Future<void> shareText(
    String fileName,
    String contents,
    String mimeType,
  ) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(contents, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: mimeType)],
        subject: fileName,
      ),
    );
  }

  /// Lets the user pick a backup; returns its text, or null when cancelled.
  /// The size is checked BEFORE reading, so a huge file is never loaded.
  Future<String?> pickBackupText() async {
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (picked == null) return null;
    final length = await picked.length();
    if (length != null && length > maxBackupBytes) {
      throw const BackupFormatException('The file is too large to be a backup');
    }
    try {
      return utf8.decode(await picked.readAsBytes());
    } on FormatException {
      throw const BackupFormatException('The file is not a text backup');
    }
  }
}

@Riverpod(keepAlive: true)
BackupPlatform backupPlatform(Ref ref) => const BackupPlatform();

/// Export / restore (keepAlive: only ever `ref.read`).
@Riverpod(keepAlive: true)
class BackupController extends _$BackupController {
  @override
  void build() {}

  String _stamp() =>
      DateFormat('yyyyMMdd-HHmm').format(ref.read(clockProvider)());

  Future<void> exportJson() async {
    final db = ref.read(appDatabaseProvider);
    final json = encodeBackup(
      await readBackupData(db),
      exportedAt: ref.read(clockProvider)(),
    );
    await ref
        .read(backupPlatformProvider)
        .shareText(
          'workout_tracker_backup_${_stamp()}.json',
          json,
          'application/json',
        );
  }

  Future<void> exportCsv() async {
    final csv = await exportSetsCsv(ref.read(appDatabaseProvider));
    await ref
        .read(backupPlatformProvider)
        .shareText('workout_tracker_sets_${_stamp()}.csv', csv, 'text/csv');
  }

  /// Picks and fully validates a backup. Null when the user cancelled.
  Future<BackupData?> pickAndValidate() async {
    final text = await ref.read(backupPlatformProvider).pickBackupText();
    return text == null ? null : decodeBackup(text);
  }

  Future<void> restore(BackupData data) =>
      replaceAllData(ref.read(appDatabaseProvider), data);
}
