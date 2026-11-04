/// Choices offered when creating a custom exercise. Match the seed's vocabulary.
const muscleGroupOptions = [
  'Chest',
  'Back',
  'Shoulders',
  'Biceps',
  'Triceps',
  'Quads',
  'Hamstrings',
  'Glutes',
  'Calves',
  'Core',
  'Full body',
  'Other',
];

const equipmentOptions = [
  'Barbell',
  'Dumbbell',
  'Machine',
  'Cable',
  'Bodyweight',
  'Kettlebell',
  'Band',
  'Other',
];

/// Filter applied to the exercise list.
class ExerciseFilterState {
  const ExerciseFilterState({
    this.query = '',
    this.muscleGroup,
    this.equipment,
    this.showArchived = false,
  });

  final String query;
  final String? muscleGroup;
  final String? equipment;
  final bool showArchived;

  bool get isFiltered =>
      query.trim().isNotEmpty ||
      muscleGroup != null ||
      equipment != null ||
      showArchived;

  ExerciseFilterState copyWith({
    String? query,
    String? Function()? muscleGroup,
    String? Function()? equipment,
    bool? showArchived,
  }) => ExerciseFilterState(
    query: query ?? this.query,
    muscleGroup: muscleGroup != null ? muscleGroup() : this.muscleGroup,
    equipment: equipment != null ? equipment() : this.equipment,
    showArchived: showArchived ?? this.showArchived,
  );
}
