import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../common/widget/error_state.dart';
import '../../../common/widget/loading_state.dart';
import '../../../common/widget/show_toast.dart';
import '../../../data/daos/exercise_dao.dart';
import '../../../data/database_provider.dart';
import '../../../utils/app_spacing.dart';
import '../model/exercise_options.dart';
import '../viewmodel/exercise_providers.dart';

/// Create (exerciseId == null) or edit a custom exercise.
class ExerciseEditScreen extends ConsumerStatefulWidget {
  const ExerciseEditScreen({super.key, this.exerciseId});

  final int? exerciseId;

  @override
  ConsumerState<ExerciseEditScreen> createState() => _ExerciseEditScreenState();
}

class _ExerciseEditScreenState extends ConsumerState<ExerciseEditScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  String _muscle = muscleGroupOptions.first;
  String _equipment = equipmentOptions.first;
  bool _loaded = false;
  bool _saving = false;
  String? _nameError;

  Object? _loadError;
  bool _missing = false;

  @override
  void initState() {
    super.initState();
    if (widget.exerciseId == null) {
      _loaded = true;
    } else {
      _load(widget.exerciseId!);
    }
  }

  /// Loads the exercise ONCE into the form. (v1 re-filled its form on every build, which
  /// froze typing — never do that.)
  Future<void> _load(int id) async {
    setState(() {
      _loadError = null;
      _missing = false;
    });
    try {
      final e = await ref.read(appDatabaseProvider).exerciseDao.getById(id);
      if (!mounted) return;
      setState(() {
        if (e == null) {
          _missing = true;
          return;
        }
        _name.text = e.name;
        _description.text = e.description;
        _muscle = muscleGroupOptions.contains(e.muscleGroup)
            ? e.muscleGroup
            : 'Other';
        _equipment = equipmentOptions.contains(e.equipment)
            ? e.equipment
            : 'Other';
        _loaded = true;
      });
    } catch (e) {
      if (mounted) setState(() => _loadError = e);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _nameError = null);
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final c = ref.read(exerciseControllerProvider.notifier);
    try {
      if (widget.exerciseId == null) {
        await c.create(
          name: _name.text,
          muscleGroup: _muscle,
          equipment: _equipment,
          description: _description.text,
        );
        showToast(message: 'Exercise created');
      } else {
        await c.update(
          id: widget.exerciseId!,
          name: _name.text,
          muscleGroup: _muscle,
          equipment: _equipment,
          description: _description.text,
        );
        showToast(message: 'Exercise saved');
      }
      if (mounted) context.pop();
    } on DuplicateExerciseNameException catch (e) {
      setState(() => _nameError = '$e');
    } catch (e) {
      showToast(message: 'Could not save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.exerciseId;
    if (!_loaded) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit exercise')),
        body: _missing
            ? const ErrorState(message: 'This exercise no longer exists.')
            : _loadError != null
            ? ErrorState(message: '$_loadError', onRetry: () => _load(id!))
            : const LoadingState(),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(id == null ? 'New exercise' : 'Edit exercise'),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: AppInsets.screen,
          children: [
            TextFormField(
              controller: _name,
              autofocus: id == null,
              maxLength: 80,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Name',
                errorText: _nameError,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _muscle,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Muscle group'),
              items: [
                for (final m in muscleGroupOptions)
                  DropdownMenuItem(value: m, child: Text(m)),
              ],
              onChanged: (v) => setState(() => _muscle = v ?? _muscle),
            ),
            const SizedBox(height: AppSpacing.lg),
            DropdownButtonFormField<String>(
              initialValue: _equipment,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Equipment'),
              items: [
                for (final m in equipmentOptions)
                  DropdownMenuItem(value: m, child: Text(m)),
              ],
              onChanged: (v) => setState(() => _equipment = v ?? _equipment),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _description,
              minLines: 3,
              maxLines: 8,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving…' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}
