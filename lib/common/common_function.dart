import 'package:get_storage/get_storage.dart';
import 'package:workout_tracker/utils/images.dart';

List<Map<String, String>> workoutTypes = [
  {
    "name": 'Barbell row',
    "icon": Images.barbellRow,
    "description":
        "The barbell row is a compound exercise targeting the back muscles, particularly the lats, traps, and rhomboids, with variations affecting bicep and rear delt activation. It involves hinging at the hips and pulling a barbell towards the torso. Proper form includes maintaining a straight back, engaging the core, and controlling the weight throughout the movement. ",
  },
  {
    "name": 'Bench press',
    "icon": Images.benchPress,
    "description":
        "The bench press is a compound exercise primarily targeting the chest, shoulders, and triceps. It involves lying on a bench and pressing a barbell or dumbbells upward. Proper form includes keeping the feet flat on the ground, maintaining a neutral spine, and controlling the weight throughout the movement.",
  },
  {
    "name": 'Shoulder press',
    "icon": Images.shoulderPrees,
    "description":
        "The shoulder press is a compound exercise that targets the shoulders, triceps, and upper chest. It involves pressing a barbell or dumbbells overhead while standing or seated. Proper form includes keeping the core engaged, maintaining a neutral spine, and controlling the weight throughout the movement.",
  },
  {
    "name": 'Deadlift',
    "icon": Images.deadlift,
    "description":
        "The deadlift is a compound exercise that targets the posterior chain, including the hamstrings, glutes, and lower back. It involves lifting a barbell from the ground to hip level while maintaining a neutral spine. Proper form includes engaging the core, keeping the bar close to the body, and controlling the weight throughout the movement.",
  },
  {
    "name": 'Squat',
    "icon": Images.squat,
    "description":
        "The squat is a compound exercise that targets the quadriceps, hamstrings, glutes, and lower back. It involves bending at the knees and hips to lower the body while keeping the chest up and back straight. Proper form includes maintaining a neutral spine, keeping the knees aligned with the toes, and controlling the weight throughout the movement.",
  },
];

// global storage instance
final storage = GetStorage();
