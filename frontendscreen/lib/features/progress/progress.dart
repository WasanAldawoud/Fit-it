/*import 'dart:async';
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
   @override
  void initState() {
    super.initState();
    // Listen for plan changes to reset the timer UI
    PlanController.instance.currentPlan.addListener(_handlePlanChange);
  }

  void _handlePlanChange() {
    if (mounted) {
      setState(() {
        _activeExercise = null; // Clear old exercise from previous plan
        _isRunning = false;
        _countdownTimer?.cancel();
      });
    }
  }

  @override
  void dispose() {
    // ALWAYS remove listeners to prevent memory leaks
    PlanController.instance.currentPlan.removeListener(_handlePlanChange);
    _countdownTimer?.cancel();
    super.dispose();
  }
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

        if (plan.id != null) {
          await _recordCompletionInBackend(plan.id!, _activeExercise!.name);
        }
        
        // AUTO-PROGRESS to next exercise
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

  // Inside progress.dart
Future<void> _recordCompletionInBackend(
  int planId,
  String exerciseName,
) async {
  String baseUrl;

  if (kIsWeb) {
    baseUrl = 'http://localhost:3000';
  } else if (Platform.isAndroid) {
    baseUrl = 'http://10.0.2.2:3000';
  } else {
    baseUrl = 'http://26.35.223.225:3000';
  }

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
      // 🔥 REFRESH FROM BACKEND (THIS ACTIVATES THE PROGRESS BAR)
      await PlanController.instance.fetchAllPlans();
    }

    client.close();
  } catch (e) {
    debugPrint("❌ Sync failed: $e");
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.primaryColor, // Solid 0xFF146E82
      body: SafeArea(
        child: ValueListenableBuilder<Plan?>(
          valueListenable: PlanController.instance.currentPlan,
          builder: (context, plan, _) {
                debugPrint("Current Progress: ${plan?.completedToday} / ${plan?.totalExercises}");
                double progressValue = (plan == null || plan.totalExercises == 0) 
                                        ? 0 
                                            : plan.completedToday / plan.totalExercises;

            return Column(
              children: [
                // --- TOP SECTION: HERO PROGRESS CIRCLE ---
                _buildHeroProgress(progressValue, plan),

                // --- BOTTOM SECTION: SCROLLABLE TRACKER & LIST ---
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          _buildTrackerCard(),
                          const SizedBox(height: 25),
                          const Text("Today's Exercises", 
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 12),
                          if (plan != null)
                            ...plan.exercises.map((ex) => _buildExerciseCard(ex)),
                          const SizedBox(height: 20),
                        ],
                      ),
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
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(
        children: [
          const Text('Workout Session', 
              style: TextStyle(fontSize: 20, color: Colors.white70, letterSpacing: 1.2)),
          const SizedBox(height: 25),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 180, height: 180,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 12,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  color: ColorConstants.accentColor, // Orange Progress
                ),
              ),
              Column(
                children: [
                  Text("${(progress * 100).toInt()}%", 
                      style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
                  Text("${plan?.completedToday ?? 0}/${plan?.totalExercises ?? 0} Done", 
                      style: const TextStyle(color: Colors.white70, fontSize: 14)),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)]
      ),
      child: Column(
        children: [
          Text(_activeExercise?.name ?? 'Select Exercise', 
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: ColorConstants.primaryColor)),
          const SizedBox(height: 5),
          const Text("Time Remaining", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 15),
          Text(fmt(_activeExercise?.remainingDuration ?? Duration.zero), 
              style: const TextStyle(fontSize: 50, fontWeight: FontWeight.w900, color: Colors.black87)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // START/PAUSE
              _buildRoundButton(
                icon: _isRunning ? Icons.pause : Icons.play_arrow,
                label: _isRunning ? "PAUSE" : "START",
                color: ColorConstants.primaryColor,
                onTap: _activeExercise == null ? null : () => _startOrPauseExercise(_activeExercise!),
              ),
              // RESET
              _buildRoundButton(
                icon: Icons.refresh,
                label: "RESET",
                color: Colors.grey.shade400,
                onTap: _activeExercise == null ? null : _resetActiveExercise,
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildRoundButton({required IconData icon, required String label, required Color color, VoidCallback? onTap}) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: CircleAvatar(
            radius: 28,
            backgroundColor: onTap == null ? Colors.grey.shade200 : color,
            child: Icon(icon, color: Colors.white, size: 30),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildExerciseCard(PlanExercise a) {
    bool isActive = _activeExercise == a;
    bool isCompleted = a.remainingDuration.inSeconds <= 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      elevation: isActive ? 4 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: isActive ? const BorderSide(color: ColorConstants.accentColor, width: 2) : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Icon(isCompleted ? Icons.check_circle : Icons.radio_button_off, 
            color: isCompleted ? Colors.green : ColorConstants.primaryColor, size: 30),
        title: Text(a.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text("${a.duration.inMinutes} mins total"),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: () => _startOrPauseExercise(a),
      ),
    );
  }
}*/