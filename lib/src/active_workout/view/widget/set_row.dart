import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../../../../data/app_database.dart';
import '../../../../data/daos/workout_dao.dart' show maxReps, maxWeightKg;
import '../../../../utils/app_spacing.dart';
import '../../../../utils/app_theme.dart';
import '../../../../utils/units.dart';

/// Column widths shared by the header and every row so they line up.
class SetRowLayout {
  static const double setNumber = 40;
  static const double previous = 84;
  static const double done = AppSizes.minTapTarget;
}

/// One set: number, previous value, weight + reps inputs (numeric, validated), done tick.
/// Values are saved as you type (when valid), so a killed app loses nothing.
class SetRow extends StatefulWidget {
  const SetRow({
    super.key,
    required this.index,
    required this.set,
    required this.unit,
    required this.onChanged,
    required this.onToggleComplete,
    required this.onDelete,
    this.previous,
    this.isRecord = false,
  });

  final int index;
  final SetEntry set;
  final SetEntry? previous;
  final WeightUnit unit;
  final bool isRecord;

  /// Called with valid values in kg.
  final void Function(double weightKg, int reps) onChanged;
  final VoidCallback onToggleComplete;
  final VoidCallback onDelete;

  @override
  State<SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<SetRow> {
  late final TextEditingController _weight;
  late final TextEditingController _reps;
  final _weightFocus = FocusNode();
  final _repsFocus = FocusNode();
  String? _weightError;
  String? _repsError;

  @override
  void initState() {
    super.initState();
    _weight = TextEditingController(text: _weightText(widget.set.weightKg));
    _reps = TextEditingController(text: '${widget.set.reps}');
  }

  String _weightText(double kg) =>
      formatWeight(kg, widget.unit, withUnit: false);

  @override
  void didUpdateWidget(SetRow old) {
    super.didUpdateWidget(old);
    // Reflect outside changes (unit switch, edits elsewhere) but never overwrite what
    // the user is typing.
    if (!_weightFocus.hasFocus) {
      final valid = _parseWeight(_weight.text);
      final changed =
          valid == null ||
          (valid - widget.set.weightKg).abs() > 1e-6 ||
          old.unit != widget.unit;
      if (changed && _weightError == null) {
        _weight.text = _weightText(widget.set.weightKg);
      }
    }
    if (!_repsFocus.hasFocus &&
        _repsError == null &&
        int.tryParse(_reps.text) != widget.set.reps) {
      _reps.text = '${widget.set.reps}';
    }
  }

  @override
  void dispose() {
    _weight.dispose();
    _reps.dispose();
    _weightFocus.dispose();
    _repsFocus.dispose();
    super.dispose();
  }

  double? _parseWeight(String text) {
    final v = parseWeightInput(text);
    if (v == null) return null;
    final kg = unitToKg(v, widget.unit);
    return kg > maxWeightKg ? null : kg;
  }

  /// Validates both fields; saves when valid. Returns whether they are valid.
  bool _commit() {
    final kg = _parseWeight(_weight.text);
    final reps = parseRepsInput(_reps.text);
    setState(() {
      _weightError = kg == null ? 'Invalid' : null;
      _repsError = (reps == null || reps > maxReps) ? 'Invalid' : null;
    });
    if (kg == null || reps == null || reps > maxReps) return false;
    if ((kg - widget.set.weightKg).abs() > 1e-9 || reps != widget.set.reps) {
      widget.onChanged(kg, reps);
    }
    return true;
  }

  void _toggle() {
    if (widget.set.completedAt == null && !_commit()) return;
    widget.onToggleComplete();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final done = widget.set.completedAt != null;
    final n = widget.index + 1;
    final prev = widget.previous;
    final prevText = prev == null
        ? '—'
        : '${formatWeight(prev.weightKg, widget.unit, withUnit: false)} × ${prev.reps}';

    return Dismissible(
      key: ValueKey('dismiss-${widget.set.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => widget.onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: AppInsets.screenH,
        color: theme.colorScheme.errorContainer,
        child: Icon(Icons.delete, color: theme.colorScheme.onErrorContainer),
      ),
      child: Semantics(
        customSemanticsActions: {
          CustomSemanticsAction(label: 'Delete set $n'): widget.onDelete,
        },
        child: Container(
          color: done ? colors.successContainer : null,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xxs,
          ),
          child: Row(
            children: [
              SizedBox(
                width: SetRowLayout.setNumber,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$n', style: theme.textTheme.titleSmall),
                    if (widget.isRecord)
                      Tooltip(
                        message: 'Personal record',
                        child: Icon(
                          Icons.emoji_events,
                          size: AppSizes.iconSm,
                          color: colors.record,
                          semanticLabel: 'Personal record',
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(
                width: SetRowLayout.previous,
                child: Semantics(
                  label: prev == null
                      ? 'No previous value'
                      : 'Previous: $prevText ${widget.unit.symbol}',
                  excludeSemantics: true,
                  child: Text(
                    prevText,
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  child: TextField(
                    controller: _weight,
                    focusNode: _weightFocus,
                    enabled: !done,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      LengthLimitingTextInputFormatter(7),
                    ],
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => _commit(),
                    decoration: InputDecoration(
                      labelText: widget.unit.symbol,
                      errorText: _weightError,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  child: TextField(
                    controller: _reps,
                    focusNode: _repsFocus,
                    enabled: !done,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    onChanged: (_) => _commit(),
                    onSubmitted: (_) => _toggle(),
                    decoration: InputDecoration(
                      labelText: 'Reps',
                      errorText: _repsError,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: SetRowLayout.done,
                child: IconButton(
                  tooltip: done ? 'Mark set $n not done' : 'Mark set $n done',
                  isSelected: done,
                  onPressed: _toggle,
                  icon: const Icon(Icons.check_circle_outline),
                  selectedIcon: Icon(Icons.check_circle, color: colors.success),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
