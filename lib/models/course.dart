import 'package:cloud_firestore/cloud_firestore.dart';

class Course {
  final String id;
  final String title;
  final String description;
  final String creatorId;
  final String creatorName;
  final double price;
  final List<String> subscribers;
  final List<WorkoutPlan> workoutPlans;
  final List<String> videoUrls;
  final List<String> photoUrls;
  final DateTime createdAt;
  final bool isPublished;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.creatorId,
    required this.creatorName,
    required this.price,
    required this.subscribers,
    required this.workoutPlans,
    required this.videoUrls,
    required this.photoUrls,
    required this.createdAt,
    required this.isPublished,
  });

  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      creatorId: map['creatorId'] as String,
      creatorName: map['creatorName'] as String,
      price: (map['price'] as num).toDouble(),
      subscribers: List<String>.from(map['subscribers'] ?? []),
      workoutPlans: (map['workoutPlans'] as List<dynamic>?)
          ?.map((plan) => WorkoutPlan.fromMap(plan as Map<String, dynamic>))
          .toList() ?? [],
      videoUrls: List<String>.from(map['videoUrls'] ?? []),
      photoUrls: List<String>.from(map['photoUrls'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isPublished: map['isPublished'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'price': price,
      'subscribers': subscribers,
      'workoutPlans': workoutPlans.map((plan) => plan.toMap()).toList(),
      'videoUrls': videoUrls,
      'photoUrls': photoUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      'isPublished': isPublished,
    };
  }
}

class WorkoutPlan {
  final String title;
  final String description;
  final List<Exercise> exercises;
  final int duration; // in minutes
  final String difficulty; // Beginner, Intermediate, Advanced

  WorkoutPlan({
    required this.title,
    required this.description,
    required this.exercises,
    required this.duration,
    required this.difficulty,
  });

  factory WorkoutPlan.fromMap(Map<String, dynamic> map) {
    return WorkoutPlan(
      title: map['title'] as String,
      description: map['description'] as String,
      exercises: (map['exercises'] as List<dynamic>)
          .map((exercise) => Exercise.fromMap(exercise as Map<String, dynamic>))
          .toList(),
      duration: map['duration'] as int,
      difficulty: map['difficulty'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'exercises': exercises.map((exercise) => exercise.toMap()).toList(),
      'duration': duration,
      'difficulty': difficulty,
    };
  }
}

class Exercise {
  final String name;
  final String description;
  final int sets;
  final int reps;
  final String? videoUrl;
  final String? photoUrl;

  Exercise({
    required this.name,
    required this.description,
    required this.sets,
    required this.reps,
    this.videoUrl,
    this.photoUrl,
  });

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      name: map['name'] as String,
      description: map['description'] as String,
      sets: map['sets'] as int,
      reps: map['reps'] as int,
      videoUrl: map['videoUrl'] as String?,
      photoUrl: map['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'sets': sets,
      'reps': reps,
      'videoUrl': videoUrl,
      'photoUrl': photoUrl,
    };
  }
} 