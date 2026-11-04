import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../data/app_database.dart';
import '../../../../data/daos/workout_dao.dart' show maxReps, maxWeightKg;
import '../../../../utils/app_spacing.dart';
import '../../../../utils/units.dart';

/// Result of editing a logged set. Weight is kg.
class EditedSet {
  const EditedSet({
    required this.weightKg,
    required this.reps,
    required this.done,
  });
  final double weightKg;
  final int reps;
  final bool done;
}

/// Sentinel returned when the user chose "Delete set".
const deleteSetResult = EditedSet(weightKg: -1, reps: -1, done: false);

Future<EditedSet?> showEditSetDialog(
  BuildContext context, {
  required SetEntry set,
  required int number,
  required WeightUnit unit,
}) => showDialog<EditedSet>(
  context: context,
  builder: (_) => _EditSetDialog(set: set, number: number, unit: unit),
);

class _EditSetDialog extends StatefulWidget {
  const _EditSetDialog({
    required this.set,
    required this.number,
    required this.unit,
  });

  final SetEntry set;
  final int number;
  final WeightUnit unit;

  @override
  State<_EditSetDialog> createState() => _EditSetDialogState();
}

class _EditSetDialogState extends State<_EditSetDialog> {
  late final _weight = TextEditingController(
    text: formatWeight(widget.set.weightKg, widget.unit, withUnit: false),
  );
  late final _reps = TextEditingController(text: '${widget.set.reps}');
  late bool _done = widget.set.completedAt != null;
  String? _weightError;
  String? _repsError;

  @override
  void dispose() {
    _weight.dispose();
    _reps.dispose();
    super.dispose();
  }

  void _save() {
    final w = parseWeightInput(_weight.text);
    final kg = w == null ? null : unitToKg(w, widget.unit);
    final reps = parseRepsInput(_reps.text);
    setState(() {
      _weightError = (kg == null || kg > maxWeightKg)
          ? 'Enter a valid weight'
          : null;
      _repsError = (reps == null || reps > maxReps) ? 'Enter valid reps' : null;
    });
    if (_weightError != null || _repsError != null) return;
    Navigator.of(
      context,
    ).pop(EditedSet(weightKg: kg!, reps: reps!, done: _done));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Set ${widget.number}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _weight,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                labelText: 'Weight (${widget.unit.symbol})',
                errorText: _weightError,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _reps,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Reps',
                errorText: _repsError,
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Done (counts toward volume and records)'),
              value: _done,
              onChanged: (v) => setState(() => _done = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(deleteSetResult),
          child: const Text('Delete set'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
