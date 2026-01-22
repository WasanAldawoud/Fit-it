
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
  
  /// Per-day remaining duration tracking (maps day name to remaining duration).
  /// This allows each day to have its own countdown that resets weekly.
  Map<String, Duration> perDayRemainingDuration;
  
  /// Last reset date to track weekly resets per day.
  DateTime? lastResetDate;

  PlanExercise({
    required this.name,
    required this.duration,
    Duration? remainingDuration,
    required this.days,
    Map<String, Duration>? perDayRemainingDuration,
    this.lastResetDate,
  }) : remainingDuration = remainingDuration ?? duration,
       perDayRemainingDuration = perDayRemainingDuration ?? {} {
    // Initialize per-day durations for each day
    for (final day in this.days) {
      if (!this.perDayRemainingDuration.containsKey(day)) {
        this.perDayRemainingDuration[day] = duration;
      }
    }
  }
}

class WeightEntry {
  DateTime date;
  double weight;
  WeightEntry({required this.date, required this.weight});
}

class Plan {
  /// Unique identifier for the plan (nullable int for flexibility).
  int? id;
  
  String name;
  String? goal;
  DateTime? deadline;
  int? durationWeeks;
  double? currentWeight;
  double? goalWeight;
  List<PlanExercise> exercises;
  List<WeightEntry> weightLog;
  
  /// Number of exercises completed today (from team's completion tracking).
  int completedToday = 0;
  
  /// Total number of exercises in the plan.
  int totalExercises = 0;
  
  /// Creation date of the plan (used to determine next weight prompt).
  DateTime createdAt;
  
  /// Last Sunday when weight was prompted (to prevent multiple prompts same week).
  DateTime? lastWeightPromptSunday;
  
  /// The start of the week (Sunday) when weight was last prompted.
  /// This provides strict weekly cycle tracking: prompt exactly once per week.
  DateTime? lastWeightPromptWeekStart;
  
  /// Whether current weight was enabled at creation (determines if weight tracking is active).
  bool currentWeightEnabledAtCreation = false;
  
  /// Goal weight reached flag (for one-time congratulations alert).
  bool goalWeightReachedAlertShown = false;
  
  /// Deadline passed flag (for one-time deadline alert).
  bool deadlinePassedAlertShown = false;

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
    DateTime? createdAt,
    this.lastWeightPromptSunday,
    this.currentWeightEnabledAtCreation = false,
  }) : createdAt = createdAt ?? DateTime.now();
}

/// A custom ValueNotifier that allows forcing a notification even if the reference hasn't changed.
class PlanNotifier extends ValueNotifier<Plan?> {
  PlanNotifier(Plan? value) : super(value);
  void forceNotify() => notifyListeners();
}

class PlanController {
  PlanController._internal();
  static final PlanController instance = PlanController._internal();

  final List<Plan> plans = [];
  final PlanNotifier currentPlan = PlanNotifier(null);

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
      baseUrl = 'http://localhost:3000';
    } else {
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
        if (plans.isNotEmpty && currentPlan.value == null) {
          currentPlan.value = plans.first;
        }
        notifyCurrentPlanChanged();
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

    return Plan(
      id: safeInt(data['plan_id']),
      name: data['plan_name'] ?? 'My Workout Plan',
      goal: data['goal'],
      deadline: data['deadline'] != null ? DateTime.parse(data['deadline']) : null,
      durationWeeks: safeInt(data['duration_weeks']),
      currentWeight: safeDouble(data['current_weight']),
      goalWeight: safeDouble(data['goal_weight']),
      exercises: exercises,
      weightLog: [],
      completedToday: safeInt(data['completed_today']),
      totalExercises: safeInt(data['total_exercises'], defaultValue: exercises.length),
    );
  }

  void syncFromBackend(Map<String, dynamic> data) {
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

    final List<dynamic> exList = data['exercises'] ?? [];
    final exercises = exList.map((e) => PlanExercise(
      name: e['exercise_name'] ?? e['name'] ?? 'Exercise',
      duration: _parseDurationString(e['duration']), 
      days: List<String>.from(e['days'] ?? []),
    )).toList();

    final List<dynamic> weightList = data['weight_history'] ?? [];
    final weightEntries = weightList.map((w) => WeightEntry(
      date: DateTime.parse(w['date'] ?? w['logged_at']),
      weight: safeDouble(w['weight']) ?? 0.0,
    )).toList();

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

    currentPlan.value = parsedPlan;
    
    int planId = safeInt(data['plan_id']);
    if (!plans.any((p) => p.id == planId)) {
      plans.add(parsedPlan);
    } else {
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
    bool currentWeightEnabledAtCreation = false,
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
      currentWeightEnabledAtCreation: currentWeightEnabledAtCreation,
      createdAt: DateTime.now(),
    );
    plans.add(plan);
    
    if (setAsCurrent) {
      Future.microtask(() {
        currentPlan.value = plan;
      });
    }
    return plan;
  }
  
  void updatePlan(
    Plan plan, {
    String? name,
    String? goal,
    DateTime? deadline,
    int? durationWeeks,
    double? currentWeight,
    double? goalWeight,
    List<PlanExercise>? exercises,
    bool? currentWeightEnabledAtCreation,
  }) {
    if (name != null) plan.name = name;
    if (goal != null) plan.goal = goal;
    if (deadline != null) plan.deadline = deadline;
    if (durationWeeks != null) plan.durationWeeks = durationWeeks;
    if (currentWeight != null) plan.currentWeight = currentWeight;
    if (goalWeight != null) plan.goalWeight = goalWeight;
    if (exercises != null) plan.exercises = List<PlanExercise>.from(exercises);
    if (currentWeightEnabledAtCreation != null) {
      plan.currentWeightEnabledAtCreation = currentWeightEnabledAtCreation;
    }
    notifyCurrentPlanChanged();
  }

  void setCurrentPlan(Plan plan) {
    currentPlan.value = plan;
  }

  void notifyCurrentPlanChanged() {
    currentPlan.forceNotify();
  }

  DateTime _getWeekStart(DateTime date) {
    final dayOfWeek = date.weekday;
    final daysSinceSunday = dayOfWeek % 7;
    final sundayDate = date.subtract(Duration(days: daysSinceSunday));
    return DateTime(sundayDate.year, sundayDate.month, sundayDate.day, 0, 0, 0);
  }

  bool shouldShowWeightPrompt(Plan plan) {
    if (!plan.currentWeightEnabledAtCreation) return false;
    final now = DateTime.now();
    if (now.weekday != DateTime.sunday) return false;
    final currentWeekStart = _getWeekStart(now);
    if (plan.lastWeightPromptWeekStart == null) {
      return plan.createdAt.isBefore(currentWeekStart.add(const Duration(days: 1)));
    }
    return !plan.lastWeightPromptWeekStart!.isAtSameMomentAs(currentWeekStart);
  }

  void markWeightPrompted(Plan plan) {
    final now = DateTime.now();
    plan.lastWeightPromptWeekStart = _getWeekStart(now);
    plan.lastWeightPromptSunday = _getWeekStart(now);
    notifyCurrentPlanChanged();
  }
}
