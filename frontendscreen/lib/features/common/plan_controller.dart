import 'package:flutter/foundation.dart';

/// Global plan data models + in-memory state.
///
/// BACKEND GUIDANCE:
/// - The backend-facing fields are: Plan.name, Plan.goal, Plan.deadline, Plan.durationWeeks,
///   Plan.currentWeight, Plan.goalWeight, and Plan.exercises (name/duration/days).
/// - The following are currently FRONTEND-ONLY (not sent to backend unless you add endpoints):
///   PlanExercise.remainingDuration (countdown resume) and Plan.weightLog (weekly check-ins).
class PlanExercise {
  /// Exercise name shown in Home + sent to backend under exercises[].name.
  String name;

  /// Total target duration for the exercise.
  /// BACKEND: currently sent as a formatted string under exercises[].duration
  /// (e.g. "90m 30s"). If you want numeric persistence, store seconds separately.
  Duration duration;

  /// Countdown state used by the Home tracker.
  /// FRONTEND-ONLY: persists only in memory right now.
  /// If you want cross-session resume, backend should store remaining seconds.
  Duration remainingDuration;

  /// Selected days for this exercise.
  /// BACKEND: sent to backend under exercises[].days as List<String>.
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
  })  : remainingDuration = remainingDuration ?? duration,
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
  /// Date of check-in.
  DateTime date;

  /// Weight in KG.
  double weight;
  WeightEntry({required this.date, required this.weight});
}

class Plan {
  /// Unique identifier for the plan (used for updates).
  /// BACKEND: sent as `id` when updating.
  String? id;

  /// Plan name.
  /// BACKEND: sent as `plan_name`.
  String name;

  /// Optional goal (nullable because Goal can be disabled in Step 2).
  /// BACKEND: sent as `goal`.
  String? goal;

  /// Optional plan deadline (nullable because Deadline can be disabled in Step 2).
  /// BACKEND: sent as `deadline` (ISO string).
  DateTime? deadline;

  /// Optional computed duration in weeks.
  /// BACKEND: sent as `duration_weeks`.
  int? durationWeeks;

  /// Optional current weight.
  /// BACKEND: sent as `current_weight`.
  double? currentWeight;

  /// Optional goal weight.
  /// BACKEND: sent as `goal_weight`.
  double? goalWeight;

  /// Exercises included in this plan.
  /// BACKEND: sent as `exercises` list.
  List<PlanExercise> exercises;

  /// Weekly check-in history.
  /// FRONTEND-ONLY: currently not posted to backend.
  List<WeightEntry> weightLog;

  /// Creation date of the plan (used to determine next weight prompt).
  DateTime createdAt;

  /// Last Sunday when weight was prompted (to prevent multiple prompts same week).
  DateTime? lastWeightPromptSunday;

  /// Whether current weight was enabled at creation (determines if weight tracking is active).
  bool currentWeightEnabledAtCreation;

  /// Goal weight reached flag (for one-time congratulations alert).
  bool goalWeightReachedAlertShown = false;

  /// Deadline passed flag (for one-time deadline alert).
  bool deadlinePassedAlertShown = false;

  Plan({
    this.id,
    required this.name,
    required this.goal,
    required this.deadline,
    required this.durationWeeks,
    required this.currentWeight,
    required this.goalWeight,
    required this.exercises,
    required this.weightLog,
    required this.currentWeightEnabledAtCreation,
    DateTime? createdAt,
    this.lastWeightPromptSunday,
  }) : createdAt = createdAt ?? DateTime.now();
}

class PlanController {
  PlanController._internal();
  static final PlanController instance = PlanController._internal();

  /// All saved plans (in-memory list).
  final List<Plan> plans = [];

  /// Currently selected/default plan.
  /// Home listens to this via ValueListenableBuilder.
  final ValueNotifier<Plan?> currentPlan = ValueNotifier<Plan?>(null);

  String generateNextPlanName() {
    int i = 1;
    while (true) {
      final candidate = 'My Plan - $i';
      final exists = plans.any((p) => p.name.toLowerCase() == candidate.toLowerCase());
      if (!exists) return candidate;
      i++;
    }
  }

  Plan addNewPlan({
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
      currentPlan.value = plan;
    }
    return plan;
  }

  /// Updates an existing plan with new data.
  void updatePlan(
    Plan plan, {
    String? name,
    String? goal,
    DateTime? deadline,
    int? durationWeeks,
    double? currentWeight,
    double? goalWeight,
    List<PlanExercise>? exercises,
    bool currentWeightEnabledAtCreation = false,
  }) {
    if (name != null) plan.name = name;
    if (goal != null) plan.goal = goal;
    if (deadline != null) plan.deadline = deadline;
    if (durationWeeks != null) plan.durationWeeks = durationWeeks;
    if (currentWeight != null) plan.currentWeight = currentWeight;
    if (goalWeight != null) plan.goalWeight = goalWeight;
    if (exercises != null) plan.exercises = List<PlanExercise>.from(exercises);
    plan.currentWeightEnabledAtCreation = currentWeightEnabledAtCreation;
    currentPlan.notifyListeners();
  }

  void setCurrentPlan(Plan plan) {
    currentPlan.value = plan;
  }

  void notifyCurrentPlanChanged() {
    currentPlan.notifyListeners();
  }
}
