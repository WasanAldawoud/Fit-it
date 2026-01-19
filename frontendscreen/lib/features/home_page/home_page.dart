import 'dart:async';
import 'dart:convert';
import 'dart:io';


import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart';

import '../../app_styles/color_constants.dart';
import '../common/plan_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer? _countdownTimer;
  bool _isRunning = false;
  PlanExercise? _activeExercise;

  void _startOrPauseExercise(PlanExercise exercise) {
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

      final remaining = _activeExercise!.remainingDuration;
      if (remaining.inSeconds <= 0) {
        _countdownTimer?.cancel();
        setState(() => _isRunning = false);

        // SYNC COMPLETION TO BACKEND
        if (plan.id != null) {
          await _recordCompletionInBackend(plan.id!, _activeExercise!.name);
        }

        // AUTO-PROGRESS: Automatically move to next exercise
        _moveToNextExercise(plan);
        return;
      }

      setState(() {
        _activeExercise!.remainingDuration = Duration(seconds: remaining.inSeconds - 1);
      });
      PlanController.instance.notifyCurrentPlanChanged();
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

  Future<void> _recordCompletionInBackend(
  int planId,
  String exerciseName,
) async {
  // MUST match the router.post("/mark-exercise-complete", ...) in authRoutes.js
 String baseUrl;
    // We must use different IPs depending on the device running the app
    if (kIsWeb) {
      baseUrl = 'http://localhost:3000'; 
    } else if (Platform.isAndroid) {
      // 26.35.223.225 is your computer's specific IP on the local network
      baseUrl = 'http://26.35.223.225:3000'; 
    } else {
      // 10.0.2.2 is the special gateway for the Android Emulator to see 'localhost'
      baseUrl = 'http://10.0.2.2:3000'; 
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
    );

    if (response.statusCode == 200) {
      final plan = PlanController.instance.currentPlan.value;
      if (plan != null) {
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
}

  void _resetActiveExercise() {
    if (_activeExercise == null) return;
    setState(() {
      _activeExercise!.remainingDuration = _activeExercise!.duration;
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
      backgroundColor: ColorConstants.primaryColor, // 0xFF146E82
      body: SafeArea(
        child: ValueListenableBuilder<Plan?>(
          valueListenable: PlanController.instance.currentPlan,
          builder: (context, plan, _) {
            double progressValue = (plan == null || plan.totalExercises == 0)
                ? 0
                : plan.completedToday / plan.totalExercises;

            return Column(
              children: [
                // --- TOP SECTION: DOMINANT PROGRESS HERO (BIGGEST ELEMENT) ---
                _buildHeroProgress(progressValue, plan),

                // --- BOTTOM SECTION: SCROLLABLE TRACKER & LIST ---
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // SLIM TRACKER CARD (NOW SMALLER)
                        _buildTrackerCard(),

                        const SizedBox(height: 25),
                        const Text(
                          "Today's Exercises",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (plan != null) ...plan.exercises.map((ex) => _buildExerciseCard(ex)),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeroProgress(double progress, Plan? plan) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 20, bottom: 30),
      child: Column(
        children: [
          const Text(
            'Workout Progress',
            style: TextStyle(fontSize: 18, color: Colors.white70, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 25),
          Stack(
            alignment: Alignment.center,
            children: [
              // Extra large progress ring
              SizedBox(
                width: 250,
                height: 250,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 18,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  color: ColorConstants.accentColor, // Orange
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "${(progress * 100).toInt()}%",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "${plan?.completedToday ?? 0}/${plan?.totalExercises ?? 0} Exercises",
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrackerCard() {
    String fmt(Duration d) => "${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _activeExercise?.name ?? 'Select Exercise',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ColorConstants.primaryColor,
                  ),
                ),
                Text(
                  fmt(_activeExercise?.remainingDuration ?? Duration.zero),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // COMPACT START/PAUSE
          _buildSmallControlButton(
            icon: _isRunning ? Icons.pause : Icons.play_arrow,
            color: ColorConstants.primaryColor,
            onTap: _activeExercise == null ? null : () => _startOrPauseExercise(_activeExercise!),
          ),
          const SizedBox(width: 12),
          // COMPACT RESET
          _buildSmallControlButton(
            icon: Icons.refresh,
            color: Colors.grey.shade400,
            onTap: _activeExercise == null ? null : _resetActiveExercise,
          ),
        ],
      ),
    );
  }

  Widget _buildSmallControlButton({required IconData icon, required Color color, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: onTap == null ? Colors.grey.shade200 : color.withOpacity(0.15),
        ),
        child: Icon(icon, color: onTap == null ? Colors.grey : color, size: 24),
      ),
    );
  }

  Widget _buildExerciseCard(PlanExercise a) {
    bool isActive = _activeExercise == a;
    bool isCompleted = a.remainingDuration.inSeconds <= 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: isActive ? const BorderSide(color: ColorConstants.accentColor, width: 2) : BorderSide.none,
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: Icon(
          isCompleted ? Icons.check_circle : Icons.radio_button_off,
          color: isCompleted ? Colors.green : ColorConstants.primaryColor,
          size: 24,
        ),
        title: Text(a.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text("${a.duration.inMinutes} min", style: const TextStyle(fontSize: 12)),
        onTap: () => _startOrPauseExercise(a),
      ),
    );
  }
}
