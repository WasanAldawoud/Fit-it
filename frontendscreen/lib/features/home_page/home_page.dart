import 'dart:async';
import 'package:flutter/material.dart';
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
  bool _weightPromptShown = false;

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

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final plan = PlanController.instance.currentPlan.value;
      if (plan == null) return;
      if (_activeExercise == null) return;

      final remaining = _activeExercise!.remainingDuration;
      if (remaining.inSeconds <= 0) {
        _countdownTimer?.cancel();
        setState(() => _isRunning = false);
        return;
      }

      _activeExercise!.remainingDuration = Duration(seconds: remaining.inSeconds - 1);
      PlanController.instance.notifyCurrentPlanChanged();
    });
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
      body: Stack(
        children: [


          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/pic/background.jpg"),
                fit: BoxFit.cover, // Ensures the image fills the space
              ),
            ),
          ),


          // Positioned.fill(
          //   child: Image.asset('assets/pic/background.jpg', fit: BoxFit.fill),
          // ),


          SafeArea(
            child: ValueListenableBuilder<Plan?>(
              valueListenable: PlanController.instance.currentPlan,
              builder: (context, plan, _) {
                if (plan != null) {
                  final last = plan.weightLog.isEmpty ? null : plan.weightLog.last;
                  final due = last == null || DateTime.now().difference(last.date).inDays >= 7;
                  if (due && !_weightPromptShown) {
                    _weightPromptShown = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _promptWeight(plan);
                    });
                  }
                }
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 16),
                      if (plan == null)
                        _buildNoPlanCard()
                      else
                        _buildPlanSummaryCard(plan),
                      const SizedBox(height: 16),
                      _buildTrackerCard(),
                      const SizedBox(height: 16),
                      if (plan != null) _buildWeeklyCheckInCard(plan),
                      const SizedBox(height: 16),
                      if (plan != null)
                        if (plan.exercises.isEmpty)
                          _buildNoExercisesCard()
                        else
                          ...plan.exercises.map(_buildExerciseCard),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        Text(
          'Home',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        Icon(Icons.calendar_today_outlined, color: Colors.black87),
      ],
    );
  }

  Widget _buildPlanSummaryCard(Plan plan) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ColorConstants.primaryColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.favorite, color: ColorConstants.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plan.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  'Goal: ${plan.goal ?? '—'}  •  Deadline: ${plan.deadline == null ? '—' : _formatDate(plan.deadline!)}',
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 4),
                Text(
                  'Time left: ${plan.durationWeeks == null ? '—' : '${plan.durationWeeks} weeks'}',
                    style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoPlanCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: const [
          Icon(Icons.info_outline, color: Colors.black87),
          SizedBox(width: 12),
          Expanded(
            child: Text('No plan selected. Go to Plans tab to choose or create a plan.',
                style: TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _buildNoExercisesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: const [
          Icon(Icons.fitness_center, color: Colors.black87),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'This plan has no workouts yet. Create a plan to see workouts here.',
              style: TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackerCard() {
    String fmt(Duration d) {
      final h = d.inHours;
      final m = d.inMinutes.remainder(60);
      final s = d.inSeconds.remainder(60);
      final parts = <String>[];
      if (h > 0) parts.add('$h hour${h == 1 ? '' : 's'}');
      if (m > 0 || h > 0) parts.add('$m minute${m == 1 ? '' : 's'}');
      parts.add('$s second${s == 1 ? '' : 's'}');
      return parts.join(' ');
    }

    final title = _activeExercise?.name ?? 'Select an exercise';
    final remaining = _activeExercise?.remainingDuration ?? Duration.zero;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ColorConstants.primaryColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.timer_outlined, color: ColorConstants.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Workout Tracker', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  fmt(remaining),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _activeExercise == null ? null : () => _startOrPauseExercise(_activeExercise!),
            child: Text(_isRunning ? 'Pause' : 'Start', style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _activeExercise == null ? null : _resetActiveExercise,
            child: const Text('Reset', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyCheckInCard(Plan plan) {
    final last = plan.weightLog.isEmpty ? null : plan.weightLog.last;
    final due = last == null || DateTime.now().difference(last.date).inDays >= 7;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(due ? Icons.notifications_active_outlined : Icons.notifications_none_outlined,
              color: Colors.black87),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Weekly Check-in', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  last == null ? 'No weight logged yet.' : 'Last: ${last.weight} kg • ${_formatDate(last.date)}',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _promptWeight(plan),
            child: const Text('Add', style: TextStyle(fontWeight: FontWeight.w600)),
          )
        ],
      ),
    );
  }

  Future<void> _promptWeight(Plan plan) async {
    final controller = TextEditingController();
    final value = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Weekly Check-in'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(hintText: 'Enter your weight (kg)'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final text = controller.text.trim();
                final parsed = double.tryParse(text);
                Navigator.pop(context, parsed);
              },
              style: ElevatedButton.styleFrom(backgroundColor: ColorConstants.primaryColor),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (value == null) return;
    plan.weightLog.add(WeightEntry(date: DateTime.now(), weight: value));
    plan.currentWeight = value;
    PlanController.instance.notifyCurrentPlanChanged();
  }

  String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Widget _buildExerciseCard(PlanExercise a) {
    String fmt(Duration d) {
      final m = d.inMinutes;
      final s = d.inSeconds.remainder(60);
      return '${m}m ${s}s';
    }



    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ColorConstants.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.fitness_center, color: ColorConstants.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  '${fmt(a.remainingDuration)} / ${fmt(a.duration)}${a.days.isEmpty ? '' : '  •  ${a.days.join(', ')}'}',
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton(
                    onPressed: () => _startOrPauseExercise(a),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorConstants.primaryColor,
                      foregroundColor: ColorConstants.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(_activeExercise == a && _isRunning ? 'Pause Workout' : 'Start Workout'),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
