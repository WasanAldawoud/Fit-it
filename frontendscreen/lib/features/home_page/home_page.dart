import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart';

import '../../app_styles/color_constants.dart';
import '../common/plan_controller.dart';
import 'widgets/hero_progress.dart';
import 'widgets/tracker_card.dart';
import 'widgets/exercise_card.dart';
import 'widgets/unavailable_exercises_section.dart';
import 'utils/date_utils.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer? _countdownTimer;
  bool _isRunning = false;
  PlanExercise? _activeExercise;
  late String _todayDayName;

  @override
  void initState() {
    super.initState();
    _todayDayName = DateUtilsCustom.getDayName(DateTime.now());
  }

  void _startOrPauseExercise(PlanExercise exercise) {
    if (!exercise.days.contains(_todayDayName)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('This exercise is only available on ${exercise.days.join(", ")}')),
      );
      return;
    }
    
    if (_activeExercise == exercise && _isRunning) {
      _countdownTimer?.cancel();
      if (mounted) setState(() => _isRunning = false);
      return;
    }

    _countdownTimer?.cancel();
    if (mounted) {
      setState(() {
        _activeExercise = exercise;
        _isRunning = true;
      });
    }

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      // 1. Safety check: if the user navigated away, kill the timer
      if (!mounted) {
        _countdownTimer?.cancel();
        return;
      }

      final plan = PlanController.instance.currentPlan.value;
      if (plan == null || _activeExercise == null) return;

      if (_activeExercise!.lastResetDate == null || 
          !DateUtilsCustom.isSameWeek(_activeExercise!.lastResetDate!, DateTime.now())) {
        _activeExercise!.perDayRemainingDuration.clear();
        _activeExercise!.lastResetDate = DateTime.now();
      }
      
      if (!_activeExercise!.perDayRemainingDuration.containsKey(_todayDayName)) {
        _activeExercise!.perDayRemainingDuration[_todayDayName] = _activeExercise!.duration;
      }

      final remaining = _activeExercise!.perDayRemainingDuration[_todayDayName]!;
      
      if (remaining.inSeconds <= 0) {
        _countdownTimer?.cancel();
        if (mounted) setState(() => _isRunning = false);

        if (plan.id != null) {
          await _recordCompletionInBackend(plan.id!, _activeExercise!.name);
        }

        if (mounted) _moveToNextExercise(plan);
        return;
      }

      // 2. Safety check before updating the clock UI
      if (mounted) {
        setState(() {
          _activeExercise!.perDayRemainingDuration[_todayDayName] =
              Duration(seconds: remaining.inSeconds - 1);
        });
        PlanController.instance.notifyCurrentPlanChanged();
      }
    });
  }

  void _moveToNextExercise(Plan plan) {
    final currentIndex = plan.exercises.indexOf(_activeExercise!);
    if (currentIndex != -1 && currentIndex < plan.exercises.length - 1) {
      setState(() {
        _activeExercise = plan.exercises[currentIndex + 1];
        _isRunning = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Next: ${_activeExercise!.name}"),
          backgroundColor: ColorConstants.accentColor,
        ),
      );
    }
  }

  Future<void> _recordCompletionInBackend(int planId, String exerciseName) async {
    String baseUrl;
    if (kIsWeb) {
      baseUrl = 'http://localhost:3000'; 
    } else if (Platform.isAndroid) {
      baseUrl = 'http://26.35.223.225:3000'; 
    } else {
      baseUrl = 'http://10.0.2.2:3000'; 
    }
    
    final String url = '$baseUrl/auth/mark-exercise-complete';

    try {
      http.Client client = http.Client();
      if (kIsWeb) client = BrowserClient()..withCredentials = true;

      final response = await client.post(
        Uri.parse(url.trim()),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "plan_id": planId,
          "exercise_name": exerciseName,
        }),
      ).timeout(const Duration(seconds: 5)); // Added a local timeout safety

      if (response.statusCode == 200) {
        final plan = PlanController.instance.currentPlan.value;
        // 3. Safety check: ensure the user hasn't left the page during the network call
        if (plan != null && mounted) {
          setState(() {
            plan.completedToday += 1;
          });
          PlanController.instance.notifyCurrentPlanChanged();
        }
      }
      client.close();
    } catch (e) {
      debugPrint("❌ Sync failed: $e");
    }
  }

  void _resetActiveExercise() {
    if (_activeExercise == null) return;
    
    if (_activeExercise!.lastResetDate == null || 
        !DateUtilsCustom.isSameWeek(_activeExercise!.lastResetDate!, DateTime.now())) {
      _activeExercise!.perDayRemainingDuration.clear();
      _activeExercise!.lastResetDate = DateTime.now();
    }
    
    setState(() {
      _activeExercise!.perDayRemainingDuration[_todayDayName] = _activeExercise!.duration;
      _isRunning = false;
    });
    _countdownTimer?.cancel();
    PlanController.instance.notifyCurrentPlanChanged();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: ColorConstants.primaryColor,
    body: SafeArea(
      child: ValueListenableBuilder<Plan?>(
        valueListenable: PlanController.instance.currentPlan,
        builder: (context, plan, _) {
          double progressValue =
              (plan == null || plan.totalExercises == 0)
                  ? 0
                  : plan.completedToday / plan.totalExercises;

          return SingleChildScrollView(
            child: Column(
              children: [
                HeroProgress(
                  progress: progressValue,
                  plan: plan,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TrackerCard(
                        activeExercise: _activeExercise,
                        isRunning: _isRunning,
                        onStartPause: _activeExercise == null
                            ? null
                            : () => _startOrPauseExercise(_activeExercise!),
                        onReset: _resetActiveExercise,
                        todayDayName: _todayDayName,
                      ),
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          Icon(
                            Icons.fitness_center,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "Today's Exercises",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (plan != null)
                        ...plan.exercises
                            .where(
                              (ex) => ex.days.contains(_todayDayName),
                            )
                            .map(
                              (ex) => ExerciseCard(
                                exercise: ex,
                                activeExercise: _activeExercise,
                                onTap: () => _startOrPauseExercise(ex),
                              ),
                            ),
                      if (plan != null)
                        UnavailableExercisesSection(
                          plan: plan,
                          todayDayName: _todayDayName,
                        ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}
}