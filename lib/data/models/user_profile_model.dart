import 'package:flutter/material.dart';

/// Fitness Level options with presentation helpers.
enum FitnessLevel {
  beginner,
  intermediate,
  advanced;

  String get displayName {
    switch (this) {
      case FitnessLevel.beginner:
        return 'Beginner';
      case FitnessLevel.intermediate:
        return 'Intermediate';
      case FitnessLevel.advanced:
        return 'Advanced';
    }
  }

  String get description {
    switch (this) {
      case FitnessLevel.beginner:
        return 'New to workouts or returning after a long break.';
      case FitnessLevel.intermediate:
        return 'Active 2-3 times per week with good baseline stamina.';
      case FitnessLevel.advanced:
        return 'Consistently training and looking for high performance.';
    }
  }

  IconData get icon {
    switch (this) {
      case FitnessLevel.beginner:
        return Icons.spa_rounded;
      case FitnessLevel.intermediate:
        return Icons.bolt_rounded;
      case FitnessLevel.advanced:
        return Icons.local_fire_department_rounded;
    }
  }

  static FitnessLevel fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'intermediate':
        return FitnessLevel.intermediate;
      case 'advanced':
        return FitnessLevel.advanced;
      case 'beginner':
      default:
        return FitnessLevel.beginner;
    }
  }
}

/// Primary Fitness Goals.
enum PrimaryGoal {
  getFit,
  buildStrength,
  loseWeight,
  improveEndurance,
  buildHealthyHabits,
  stayActive;

  String get displayName {
    switch (this) {
      case PrimaryGoal.getFit:
        return 'Get Fit';
      case PrimaryGoal.buildStrength:
        return 'Build Strength';
      case PrimaryGoal.loseWeight:
        return 'Lose Weight';
      case PrimaryGoal.improveEndurance:
        return 'Improve Endurance';
      case PrimaryGoal.buildHealthyHabits:
        return 'Build Healthy Habits';
      case PrimaryGoal.stayActive:
        return 'Stay Active';
    }
  }

  String get description {
    switch (this) {
      case PrimaryGoal.getFit:
        return 'Overall conditioning, functional agility, and better health.';
      case PrimaryGoal.buildStrength:
        return 'Progressive bodyweight exercises and muscle development.';
      case PrimaryGoal.loseWeight:
        return 'Burn calories through consistent daily movement and habits.';
      case PrimaryGoal.improveEndurance:
        return 'Boost stamina, step count, and aerobic capacity.';
      case PrimaryGoal.buildHealthyHabits:
        return 'Form long-lasting consistency with progressive micro-goals.';
      case PrimaryGoal.stayActive:
        return 'Maintain energy levels and break sedentary daily routines.';
    }
  }

  IconData get icon {
    switch (this) {
      case PrimaryGoal.getFit:
        return Icons.fitness_center_rounded;
      case PrimaryGoal.buildStrength:
        return Icons.shield_rounded;
      case PrimaryGoal.loseWeight:
        return Icons.local_fire_department_rounded;
      case PrimaryGoal.improveEndurance:
        return Icons.directions_run_rounded;
      case PrimaryGoal.buildHealthyHabits:
        return Icons.check_circle_outline_rounded;
      case PrimaryGoal.stayActive:
        return Icons.directions_walk_rounded;
    }
  }

  static PrimaryGoal fromString(String? value) {
    switch (value) {
      case 'buildStrength':
        return PrimaryGoal.buildStrength;
      case 'loseWeight':
        return PrimaryGoal.loseWeight;
      case 'improveEndurance':
        return PrimaryGoal.improveEndurance;
      case 'buildHealthyHabits':
        return PrimaryGoal.buildHealthyHabits;
      case 'stayActive':
        return PrimaryGoal.stayActive;
      case 'getFit':
      default:
        return PrimaryGoal.getFit;
    }
  }
}

/// Optional Gender enumeration.
enum Gender {
  male,
  female,
  nonBinary,
  preferNotToSay;

  String get displayName {
    switch (this) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
      case Gender.nonBinary:
        return 'Non-Binary';
      case Gender.preferNotToSay:
        return 'Prefer not to say';
    }
  }

  static Gender? fromString(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'male':
        return Gender.male;
      case 'female':
        return Gender.female;
      case 'nonBinary':
        return Gender.nonBinary;
      case 'preferNotToSay':
        return Gender.preferNotToSay;
      default:
        return null;
    }
  }
}

/// Complete User Profile Model for Habitude.
class UserProfile {
  final String id;
  final String name;
  final String? email;
  final int age;
  final Gender? gender;
  final double height; // in cm
  final double weight; // in kg
  final FitnessLevel fitnessLevel;
  final PrimaryGoal primaryGoal;
  final int dailyStepGoal;
  final int preferredWorkoutDuration; // in minutes
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.name,
    this.email,
    required this.age,
    this.gender,
    required this.height,
    required this.weight,
    required this.fitnessLevel,
    required this.primaryGoal,
    this.dailyStepGoal = 6000,
    this.preferredWorkoutDuration = 10,
    required this.createdAt,
    required this.updatedAt,
  });

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    int? age,
    Gender? gender,
    double? height,
    double? weight,
    FitnessLevel? fitnessLevel,
    PrimaryGoal? primaryGoal,
    int? dailyStepGoal,
    int? preferredWorkoutDuration,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
      primaryGoal: primaryGoal ?? this.primaryGoal,
      dailyStepGoal: dailyStepGoal ?? this.dailyStepGoal,
      preferredWorkoutDuration:
          preferredWorkoutDuration ?? this.preferredWorkoutDuration,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'age': age,
      'gender': gender?.name,
      'height': height,
      'weight': weight,
      'fitnessLevel': fitnessLevel.name,
      'primaryGoal': primaryGoal.name,
      'dailyStepGoal': dailyStepGoal,
      'preferredWorkoutDuration': preferredWorkoutDuration,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? 'user_default',
      name: json['name'] as String? ?? '',
      email: json['email'] as String?,
      age: (json['age'] as num?)?.toInt() ?? 25,
      gender: Gender.fromString(json['gender'] as String?),
      height: (json['height'] as num?)?.toDouble() ?? 175.0,
      weight: (json['weight'] as num?)?.toDouble() ?? 70.0,
      fitnessLevel: FitnessLevel.fromString(json['fitnessLevel'] as String?),
      primaryGoal: PrimaryGoal.fromString(json['primaryGoal'] as String?),
      dailyStepGoal: (json['dailyStepGoal'] as num?)?.toInt() ?? 6000,
      preferredWorkoutDuration:
          (json['preferredWorkoutDuration'] as num?)?.toInt() ?? 10,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          email == other.email &&
          age == other.age &&
          gender == other.gender &&
          height == other.height &&
          weight == other.weight &&
          fitnessLevel == other.fitnessLevel &&
          primaryGoal == other.primaryGoal &&
          dailyStepGoal == other.dailyStepGoal &&
          preferredWorkoutDuration == other.preferredWorkoutDuration;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      age.hashCode ^
      height.hashCode ^
      weight.hashCode ^
      fitnessLevel.hashCode ^
      primaryGoal.hashCode;

  @override
  String toString() {
    return 'UserProfile(id: $id, name: $name, age: $age, level: ${fitnessLevel.displayName}, goal: ${primaryGoal.displayName}, steps: $dailyStepGoal, duration: ${preferredWorkoutDuration}m)';
  }
}
