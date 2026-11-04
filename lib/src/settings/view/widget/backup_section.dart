import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/widget/confirm_dialog.dart';
import '../../../../common/widget/section_header.dart';
import '../../../../common/widget/show_toast.dart';
import '../../../../data/backup/backup_codec.dart';
import '../../../../utils/app_spacing.dart';
import '../../viewmodel/backup_controller.dart';

/// Export backup / export CSV / restore. One action at a time; each shows progress.
class BackupSection extends ConsumerStatefulWidget {
  const BackupSection({super.key});

  @override
  ConsumerState<BackupSection> createState() => _BackupSectionState();
}

class _BackupSectionState extends ConsumerState<BackupSection> {
  String? _busy;

  Future<void> _run(String key, Future<void> Function() action) async {
    if (_busy != null) return;
    setState(() => _busy = key);
    try {
      await action();
    } on BackupFormatException catch (e) {
      showToast(message: 'Not restored: $e. Your data was not changed.');
    } catch (e) {
      showToast(
        message: 'Something went wrong: $e. Your data was not changed.',
      );
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _restore() async {
    final c = ref.read(backupControllerProvider.notifier);
    final data = await c.pickAndValidate();
    if (data == null || !mounted) return;
    // Not "busy" while the user reads the confirmation.
    setState(() => _busy = '');
    final workouts = data.sessions.length;
    final ok = await showConfirmDialog(
      context,
      title: 'Replace all data?',
      message:
          'This backup has $workouts workout${workouts == 1 ? '' : 's'}, '
          '${data.routines.length} routines and ${data.exercises.length} exercises. '
          'Restoring REPLACES everything currently in the app. This cannot be undone.',
      confirmLabel: 'Replace',
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = 'restore');
    await c.restore(data);
    showToast(message: 'Backup restored');
  }

  Widget? _trailing(String key) => _busy == key
      ? const SizedBox.square(
          dimension: AppSizes.inlineProgress,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
      : null;

  @override
  Widget build(BuildContext context) {
    final c = ref.read(backupControllerProvider.notifier);
    final idle = _busy == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Your data'),
        ListTile(
          leading: const Icon(Icons.upload_file),
          title: const Text('Export backup'),
          subtitle: const Text(
            'Everything, as a JSON file you can share or save',
          ),
          trailing: _trailing('json'),
          enabled: idle,
          onTap: () => _run('json', c.exportJson),
        ),
        ListTile(
          leading: const Icon(Icons.table_chart_outlined),
          title: const Text('Export sets as CSV'),
          subtitle: const Text('For spreadsheets'),
          trailing: _trailing('csv'),
          enabled: idle,
          onTap: () => _run('csv', c.exportCsv),
        ),
        ListTile(
          leading: const Icon(Icons.restore),
          title: const Text('Restore from backup'),
          subtitle: const Text('Replaces all current data'),
          trailing: _trailing('restore'),
          enabled: idle,
          onTap: () => _run('restore', _restore),
        ),
      ],
    );
  }
}
