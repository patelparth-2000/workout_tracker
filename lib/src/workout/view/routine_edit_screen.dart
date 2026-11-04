import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../common/widget/confirm_dialog.dart';
import '../../../common/widget/error_state.dart';
import '../../../common/widget/loading_state.dart';
import '../../../common/widget/show_toast.dart';
import '../../../data/database_provider.dart';
import '../../../data/models.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/workout_math.dart';
import '../viewmodel/routine_providers.dart';

/// One exercise in the editor, with its display name.
class _Item {
  _Item(this.draft, this.name);
  RoutineExerciseDraft draft;
  final String name;
  final Key key = UniqueKey();
}

/// Rest choices for a routine exercise; null = use the settings default.
const _restChoices = <int?>[null, 30, 45, 60, 90, 120, 150, 180, 240, 300];
const _maxTargetSets = 20;

/// Create (routineId == null) or edit a routine.
class RoutineEditScreen extends ConsumerStatefulWidget {
  const RoutineEditScreen({super.key, this.routineId});

  final int? routineId;

  @override
  ConsumerState<RoutineEditScreen> createState() => _RoutineEditScreenState();
}

class _RoutineEditScreenState extends ConsumerState<RoutineEditScreen> {
  final _name = TextEditingController();
  final _notes = TextEditingController();
  final _items = <_Item>[];
  bool _loaded = false;
  bool _missing = false;
  Object? _loadError;
  bool _dirty = false;
  bool _saving = false;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    if (widget.routineId == null) {
      _loaded = true;
    } else {
      _load(widget.routineId!);
    }
  }

  Future<void> _load(int id) async {
    setState(() => _loadError = null);
    try {
      final d = await ref.read(routineControllerProvider.notifier).load(id);
      if (!mounted) return;
      setState(() {
        if (d == null) {
          _missing = true;
          return;
        }
        _name.text = d.routine.name;
        _notes.text = d.routine.notes ?? '';
        _items
          ..clear()
          ..addAll([
            for (final e in d.exercises)
              _Item(
                RoutineExerciseDraft(
                  exerciseId: e.exercise.id,
                  targetSets: e.entry.targetSets,
                  targetReps: e.entry.targetReps,
                  restSeconds: e.entry.restSeconds,
                ),
                e.exercise.name,
              ),
          ]);
        _loaded = true;
      });
    } catch (e) {
      if (mounted) setState(() => _loadError = e);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _change(VoidCallback f) => setState(() {
    f();
    _dirty = true;
  });

  /// Text edits must rebuild once so PopScope.canPop sees the new dirty state.
  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _addExercise() async {
    final id = await context.pushNamed<int>(RouteNames.exercisePicker);
    if (id == null || !mounted) return;
    final e = await ref.read(appDatabaseProvider).exerciseDao.getById(id);
    if (e == null || !mounted) return;
    _change(
      () => _items.add(_Item(RoutineExerciseDraft(exerciseId: id), e.name)),
    );
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _nameError = 'Enter a name');
      return;
    }
    if (_items.isEmpty) {
      showToast(message: 'Add at least one exercise');
      return;
    }
    setState(() {
      _nameError = null;
      _saving = true;
    });
    try {
      await ref
          .read(routineControllerProvider.notifier)
          .save(
            id: widget.routineId,
            name: _name.text,
            notes: _notes.text,
            items: [for (final i in _items) i.draft],
          );
      _dirty = false;
      showToast(message: 'Routine saved');
      if (mounted) context.pop();
    } catch (e) {
      showToast(message: 'Could not save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.routineId == null ? 'New routine' : 'Edit routine';
    if (!_loaded) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: _missing
            ? const ErrorState(message: 'This routine no longer exists.')
            : _loadError != null
            ? ErrorState(
                message: '$_loadError',
                onRetry: () => _load(widget.routineId!),
              )
            : const LoadingState(),
      );
    }
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final discard = await showConfirmDialog(
          context,
          title: 'Discard changes?',
          message: 'Your changes to this routine have not been saved.',
          confirmLabel: 'Discard',
          destructive: true,
        );
        if (discard && context.mounted) {
          setState(() => _dirty = false);
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: [
            TextButton(
              onPressed: _saving ? null : _save,
              child: const Text('Save'),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _addExercise,
          icon: const Icon(Icons.add),
          label: const Text('Add exercise'),
        ),
        body: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: AppInsets.screen,
              sliver: SliverList.list(
                children: [
                  TextField(
                    controller: _name,
                    maxLength: 80,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => _markDirty(),
                    decoration: InputDecoration(
                      labelText: 'Routine name',
                      errorText: _nameError,
                    ),
                  ),
                  TextField(
                    controller: _notes,
                    maxLength: 500,
                    maxLines: 3,
                    minLines: 1,
                    onChanged: (_) => _markDirty(),
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                    ),
                  ),
                ],
              ),
            ),
            if (_items.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: AppInsets.screen,
                  child: Text('No exercises yet. Tap "Add exercise".'),
                ),
              )
            else
              SliverReorderableList(
                itemCount: _items.length,
                onReorder: (from, to) => _change(() {
                  final item = _items.removeAt(from);
                  _items.insert(to > from ? to - 1 : to, item);
                }),
                itemBuilder: (context, i) => _RoutineItemCard(
                  key: _items[i].key,
                  index: i,
                  item: _items[i],
                  onChanged: (d) => _change(() => _items[i].draft = d),
                  onRemove: () => _change(() => _items.removeAt(i)),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ),
      ),
    );
  }
}

class _RoutineItemCard extends StatelessWidget {
  const _RoutineItemCard({
    super.key,
    required this.index,
    required this.item,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final _Item item;
  final ValueChanged<RoutineExerciseDraft> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final d = item.draft;
    return Card(
      child: Padding(
        padding: AppInsets.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: const Tooltip(
                    message: 'Drag to reorder',
                    child: SizedBox.square(
                      dimension: AppSizes.minTapTarget,
                      child: Icon(Icons.drag_handle),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    item.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Remove ${item.name}',
                  icon: const Icon(Icons.close),
                  onPressed: onRemove,
                ),
              ],
            ),
            Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'One set fewer',
                      icon: const Icon(Icons.remove),
                      onPressed: d.targetSets > 1
                          ? () => onChanged(
                              d.copyWith(targetSets: d.targetSets - 1),
                            )
                          : null,
                    ),
                    Text('${d.targetSets} set${d.targetSets == 1 ? '' : 's'}'),
                    IconButton(
                      tooltip: 'One set more',
                      icon: const Icon(Icons.add),
                      onPressed: d.targetSets < _maxTargetSets
                          ? () => onChanged(
                              d.copyWith(targetSets: d.targetSets + 1),
                            )
                          : null,
                    ),
                  ],
                ),
                SizedBox(
                  width: 120,
                  child: TextFormField(
                    initialValue: d.targetReps?.toString() ?? '',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    decoration: const InputDecoration(labelText: 'Target reps'),
                    onChanged: (v) {
                      final reps = int.tryParse(v);
                      onChanged(d.copyWith(targetReps: () => reps));
                    },
                  ),
                ),
                DropdownButton<int?>(
                  value: d.restSeconds,
                  hint: const Text('Rest: default'),
                  items: [
                    for (final r in _restChoices)
                      DropdownMenuItem(
                        value: r,
                        child: Text(
                          r == null
                              ? 'Rest: default'
                              : 'Rest ${formatClock(Duration(seconds: r))}',
                        ),
                      ),
                  ],
                  onChanged: (v) => onChanged(d.copyWith(restSeconds: () => v)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
