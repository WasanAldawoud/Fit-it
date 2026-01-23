import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart';

// --- MODELS ---

class PlanExercise {
  String name;
  Duration duration;
  Duration remainingDuration;
  List<String> days;
  bool isCompleted;
  
  /// Tracks remaining duration for each specific day
  /// Logic: {'Monday': Duration(minutes: 10), 'Wednesday': Duration(minutes: 10)}
  Map<String, Duration> perDayRemainingDuration;

  PlanExercise({
    required this.name,
    required this.duration,
    Duration? remainingDuration,
    required this.days,
    this.isCompleted = false,
    Map<String, Duration>? perDayRemainingDuration,
  }) : 
    remainingDuration = remainingDuration ?? (isCompleted ? Duration.zero : duration),
    this.perDayRemainingDuration = perDayRemainingDuration ?? {
      for (var day in days) day: isCompleted ? Duration.zero : duration
    };
}

class WeightEntry {
  DateTime date;
  double weight;
  WeightEntry({required this.date, required this.weight});
}

class Plan {
  int? id;
  String name;
  String? goal;
  DateTime? deadline;
  int? durationWeeks;
  double? currentWeight;
  double? goalWeight;
  List<PlanExercise> exercises;
  List<WeightEntry> weightLog;
  int completedToday;
  int totalExercises;
  
  Plan({
    this.id,
    required this.name,
    this.goal,
    this.deadline,
    this.durationWeeks,
    this.currentWeight,
    this.goalWeight,
    required this.exercises,
    required this.weightLog,
    this.completedToday = 0,
    this.totalExercises = 0,
 
  });
}

// --- CONTROLLER ---

class PlanController {
  PlanController._internal();
  static final PlanController instance = PlanController._internal();

  final List<Plan> plans = [];
  final ValueNotifier<Plan?> currentPlan = ValueNotifier<Plan?>(null);

  // Helper to get platform-specific base URL
  String get _baseUrl {
    if (kIsWeb) return 'http://localhost:3000';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000';
    return 'http://26.35.223.225:3000';
  }

  String generateNextPlanName() {
    int i = 1;
    while (true) {
      final candidate = 'Plan $i';
      final exists = plans.any((p) => p.name.toLowerCase() == candidate.toLowerCase());
      if (!exists) return candidate;
      i++;
    }
  }

  Future<void> fetchAllPlans() async {
    final String url = '$_baseUrl/auth/get-plan';

    try {
      var client = http.Client();
      if (kIsWeb) client = BrowserClient()..withCredentials = true;

      final response = await client.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        plans.clear();

        for (var planMap in data) {
          plans.add(_mapJsonToPlan(planMap));
        }

        if (plans.isNotEmpty) {
          if (currentPlan.value == null) {
            currentPlan.value = plans.first;
          } else {
            // Keep the same plan selected by ID after refresh
            currentPlan.value = plans.firstWhere(
              (p) => p.id == currentPlan.value!.id,
              orElse: () => plans.first,
            );
          }
        }
        currentPlan.notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching plans: $e");
    }
  }

  Plan _mapJsonToPlan(Map<String, dynamic> data) {
    final List<dynamic> exList = data['exercises'] ?? [];
    
    final exercises = exList.map((e) {
      bool done = e['is_done'] ?? false; 
      Duration dur = _parseDurationString(e['duration']);
      List<String> days = List<String>.from(e['days'] ?? []);

      return PlanExercise(
        name: e['exercise_name'] ?? 'Exercise',
        duration: dur,
        days: days,
        isCompleted: done,
        remainingDuration: done ? Duration.zero : dur,
        perDayRemainingDuration: {
          for (var day in days) day: done ? Duration.zero : dur
        },
      );
    }).toList();

    return Plan(
      id: _safeInt(data['plan_id']),
      name: data['plan_name'] ?? 'My Workout Plan',
      goal: data['goal'],
      deadline: data['deadline'] != null ? DateTime.parse(data['deadline']) : null,
      durationWeeks: _safeInt(data['duration_weeks']),
      currentWeight: _safeDouble(data['current_weight']),
      goalWeight: _safeDouble(data['goal_weight']),
      exercises: exercises,
      weightLog: [],
      completedToday: _safeInt(data['completed_today']),
      totalExercises: _safeInt(data['total_exercises'], defaultValue: exercises.length),
    );
  }

  // Helper for safe data conversion
  double? _safeDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  int _safeInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  Duration _parseDurationString(String? s) {
    if (s == null || !s.contains('m')) return Duration.zero;
    try {
      final parts = s.split(' ');
      int mins = int.parse(parts[0].replaceAll('m', ''));
      int secs = 0;
      if (parts.length > 1) {
        secs = int.parse(parts[1].replaceAll('s', ''));
      }
      return Duration(minutes: mins, seconds: secs);
    } catch (e) {
      return Duration.zero;
    }
  }

  void setCurrentPlan(Plan plan) {
    currentPlan.value = plan;
    currentPlan.notifyListeners();
  }

  void notifyCurrentPlanChanged() {
    currentPlan.notifyListeners();
  }
}