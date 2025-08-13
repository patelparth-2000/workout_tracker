class WorkoutModel {
  final String type;
  final String weight;
  final String reps;
  final String sets;
  final String icon;
  final String description;

  WorkoutModel({
    required this.type,
    required this.weight,
    required this.reps,
    required this.sets,
    required this.icon,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'weight': weight,
    'reps': reps,
    'sets': sets,
    'icon': icon,
    'description': description,
  };

  factory WorkoutModel.fromJson(Map<String, dynamic> json) => WorkoutModel(
    type: json['type'],
    weight: json['weight'],
    reps: json['reps'],
    sets: json['sets'],
    icon: json['icon'],
    description: json['description'],
  );
}
