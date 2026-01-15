
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart';
/// Global plan data models + in-memory state.
class PlanExercise {
  String name;
  Duration duration;
  Duration remainingDuration;
  List<String> days;

  PlanExercise({
    required this.name,
    required this.duration,
    Duration? remainingDuration,
    required this.days,
  }) : remainingDuration = remainingDuration ?? duration;
}

class WeightEntry {
  DateTime date;
  double weight;
  WeightEntry({required this.date, required this.weight});
}

class Plan {
  // Database ID field (Nullable for local-only plans)
  int? id;
  String name;
  String? goal;
  DateTime? deadline;
  int? durationWeeks;
  double? currentWeight;
  double? goalWeight;
  List<PlanExercise> exercises;
  List<WeightEntry> weightLog;
  int completedToday; // 🔹 ADD THIS
  int totalExercises; // 🔹 ADD THIS

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
    this.completedToday = 0, // Default to 0
    this.totalExercises = 0,
  });
}

class PlanController {
  PlanController._internal();
  static final PlanController instance = PlanController._internal();

  final List<Plan> plans = [];
  final ValueNotifier<Plan?> currentPlan = ValueNotifier<Plan?>(null);

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

    String baseUrl;

if (kIsWeb) {
  // Option 1: Web Browser
  baseUrl = 'http://localhost:3000';
} else {
  // Option 2 & 3: Mobile (Check manually for now or use a constant)
  // Use 10.0.2.2 for Emulator or your IP 26.35.223.225 for Physical Device
  baseUrl = 'http://26.35.223.225:3000'; 
}
 final String url = '$baseUrl/auth/get-plan';

    try {
      var client = http.Client();
      if (kIsWeb) client = BrowserClient()..withCredentials = true;
      
      final response = await client.get(Uri.parse(url.trim()));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        plans.clear();
        for (var planMap in data) {
          final plan = _mapJsonToPlan(planMap);
          plans.add(plan);
        }
        // Set the first plan as current if none exists
        if (plans.isNotEmpty && currentPlan.value == null) {
          currentPlan.value = plans.first;
        }
        // ignore: invalid_use_of_protected_member
        currentPlan.notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching plans: $e");
    }
  }

  Plan _mapJsonToPlan(Map<String, dynamic> data) {
  final List<dynamic> exList = data['exercises'] ?? [];
  
  final exercises = exList.map((e) => PlanExercise(
    name: e['exercise_name'] ?? 'Exercise',
    duration: _parseDurationString(e['duration']), 
    days: List<String>.from(e['days'] ?? []),
  )).toList();

  // --- HELPER: Safe Double Parsing ---
  double? safeDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  // --- HELPER: Safe Int Parsing ---
  int safeInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  return Plan(
    id: safeInt(data['plan_id']),
    name: data['plan_name'] ?? 'My Workout Plan',
    goal: data['goal'],
    deadline: data['deadline'] != null ? DateTime.parse(data['deadline']) : null,
    durationWeeks: safeInt(data['duration_weeks']),
    // FIX: Parse the weight strings from DB into doubles
    currentWeight: safeDouble(data['current_weight']),
    goalWeight: safeDouble(data['goal_weight']),
    exercises: exercises,
    weightLog: [],
    completedToday: safeInt(data['completed_today']),
    totalExercises: safeInt(data['total_exercises'], defaultValue: exercises.length),
  );
}
  /// Converts complex JSON from the backend into clean Flutter objects
  void syncFromBackend(Map<String, dynamic> data) {
  // --- HELPER FUNCTIONS (Internal to this method) ---
  double? safeDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  int safeInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  // 1. Map Exercises
  final List<dynamic> exList = data['exercises'] ?? [];
  final exercises = exList.map((e) => PlanExercise(
    name: e['exercise_name'] ?? e['name'] ?? 'Exercise',
    duration: _parseDurationString(e['duration']), 
    days: List<String>.from(e['days'] ?? []),
  )).toList();

  // 2. Map Weights (if history exists)
  final List<dynamic> weightList = data['weight_history'] ?? [];
  final weightEntries = weightList.map((w) => WeightEntry(
    date: DateTime.parse(w['date'] ?? w['logged_at']),
    weight: safeDouble(w['weight']) ?? 0.0,
  )).toList();

  // 3. Create the Plan Object with safe types
  final parsedPlan = Plan(
    id: safeInt(data['plan_id']),
    name: data['plan_name'] ?? 'My Workout Plan',
    goal: data['goal'],
    deadline: data['deadline'] != null ? DateTime.parse(data['deadline']) : null,
    durationWeeks: safeInt(data['duration_weeks']),
    currentWeight: safeDouble(data['current_weight']),
    goalWeight: safeDouble(data['goal_weight']),
    exercises: exercises,
    weightLog: weightEntries,
    completedToday: safeInt(data['completed_today']),
    totalExercises: safeInt(data['total_exercises'], defaultValue: exercises.length),
  );

  // 4. Update Global State
  currentPlan.value = parsedPlan;
  
  // 5. Update Local History List (Prevent duplicates)
  int planId = safeInt(data['plan_id']);
  if (!plans.any((p) => p.id == planId)) {
    plans.add(parsedPlan);
  } else {
    // Optional: Update the existing plan in the list if it already exists
    int index = plans.indexWhere((p) => p.id == planId);
    plans[index] = parsedPlan;
  }
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

  Plan addNewPlan({
    int? id,
    String? name,
    String? goal,
    DateTime? deadline,
    int? durationWeeks,
    double? currentWeight,
    double? goalWeight,
    List<PlanExercise> exercises = const [],
    bool setAsCurrent = true,
  }) {
    final plan = Plan(
      id: id, 
      name: name ?? generateNextPlanName(),
      goal: goal,
      deadline: deadline,
      durationWeeks: durationWeeks,
      currentWeight: currentWeight,
      goalWeight: goalWeight,
      exercises: List<PlanExercise>.from(exercises),
      weightLog: <WeightEntry>[],
    );
    plans.add(plan);
    
    if (setAsCurrent) {
      // FIXED: Using a microtask prevents the "rebuild during build" assertion error
      // if this method is called from an initState or build method.
      Future.microtask(() {
        currentPlan.value = plan;
      
      });
    }
    return plan;
  }

  void setCurrentPlan(Plan plan) {
    currentPlan.value = plan;
      
      currentPlan.notifyListeners();
  }

  void notifyCurrentPlanChanged() {
    currentPlan.notifyListeners();
  }
}
 