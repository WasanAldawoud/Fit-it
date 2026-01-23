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
    // Use custom utility to get current day name matching DB strings
    _todayDayName = DateUtilsCustom.getDayName(DateTime.now());
  }

  // --- CORE TIMER LOGIC ---

  void _startOrPauseExercise(PlanExercise exercise) {
    if (!exercise.days.contains(_todayDayName)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('This exercise is only available on ${exercise.days.join(", ")}')),
      );
      return;
    }

    if (_activeExercise == exercise && _isRunning) {
      _countdownTimer?.cancel();
      setState(() => _isRunning = false);
      return;
    }

    _countdownTimer?.cancel();
    setState(() {
      _activeExercise = exercise;
      _isRunning = true;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final plan = PlanController.instance.currentPlan.value;
      if (plan == null || _activeExercise == null) return;

      final remaining = _activeExercise!.perDayRemainingDuration[_todayDayName] ?? _activeExercise!.duration;

      if (remaining.inSeconds <= 0) {
        _countdownTimer?.cancel();
        setState(() => _isRunning = false);

        // SYNC COMPLETION TO POSTGRESQL
        if (plan.id != null) {
          await _recordCompletionInBackend(plan.id!, _activeExercise!.name);
        }

        _moveToNextExercise(plan);
        return;
      }

      setState(() {
        _activeExercise!.perDayRemainingDuration[_todayDayName] = Duration(seconds: remaining.inSeconds - 1);
      });
      PlanController.instance.notifyCurrentPlanChanged();
    });
  }

  void _moveToNextExercise(Plan plan) {
    final todaysExercises = plan.exercises.where((ex) => ex.days.contains(_todayDayName)).toList();
    final currentIndexInToday = todaysExercises.indexOf(_activeExercise!);

    if (currentIndexInToday != -1 && currentIndexInToday < todaysExercises.length - 1) {
      setState(() {
        _activeExercise = todaysExercises[currentIndexInToday + 1];
        _isRunning = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Up Next: ${_activeExercise!.name}"),
          backgroundColor: ColorConstants.accentColor,
        ),
      );
    }
  }

  // --- BACKEND SYNC ---

  Future<void> _recordCompletionInBackend(int planId, String exerciseName) async {
    String baseUrl = kIsWeb 
        ? 'http://localhost:3000' 
        : (Platform.isAndroid ? 'http://10.0.2.2:3000' : 'http://26.35.223.225:3000');
    
    final String url = '$baseUrl/auth/mark-exercise-complete';

    try {
      http.Client client = http.Client();
      if (kIsWeb) client = BrowserClient()..withCredentials = true;

      final response = await client.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "plan_id": planId,
          "exercise_name": exerciseName,
        }),
      );

      if (response.statusCode == 200) {
        final plan = PlanController.instance.currentPlan.value;
        if (plan != null) {
          // Trigger local update of the progress ring
          await PlanController.instance.fetchAllPlans();
        }
      }
      client.close();
    } catch (e) {
      debugPrint("❌ Sync failed: $e");
    }
  }

  void _resetActiveExercise() {
    if (_activeExercise == null) return;
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
            // Calculate Progress Ring Percentage
            double progressValue = (plan == null || plan.totalExercises == 0)
                ? 0
                : plan.completedToday / plan.totalExercises;

            return SingleChildScrollView(
              child: Column(
                children: [
                  // 1. HERO PROGRESS SECTION (Orange Ring)
                  HeroProgress(progress: progressValue, plan: plan),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 2. ACTIVE TRACKER CARD (Timer Controls)
                        TrackerCard(
                          activeExercise: _activeExercise,
                          isRunning: _isRunning,
                          onStartPause: _activeExercise == null 
                              ? null 
                              : () => _startOrPauseExercise(_activeExercise!),
                          onReset: _resetActiveExercise,
                          todayDayName: _todayDayName,
                        ),
                        
                        const SizedBox(height: 35),

                        // 3. TODAY'S EXERCISES HEADER
                        Row(
                          children: const [
                            Icon(Icons.fitness_center, color: Colors.white, size: 24),
                            SizedBox(width: 8),
                            Text(
                              "Today's Exercises",
                              style: TextStyle(
                                fontSize: 20, 
                                fontWeight: FontWeight.bold, 
                                color: Colors.white
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // 4. SCROLLABLE EXERCISE CARDS
                        if (plan != null) 
                          ...plan.exercises
                            .where((ex) => ex.days.contains(_todayDayName))
                            .map((ex) => ExerciseCard(
                                  exercise: ex,
                                  activeExercise: _activeExercise,
                                  onTap: () => _startOrPauseExercise(ex),
                                )),

                        const SizedBox(height: 10),

                        // 5. UNAVAILABLE SECTION (Exercises for other days)
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