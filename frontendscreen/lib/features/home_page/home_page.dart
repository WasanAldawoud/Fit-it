import 'dart:async';
import 'package:flutter/material.dart';
import '../../app_styles/color_constants.dart';
import '../common/plan_controller.dart';
import 'package:fl_chart/fl_chart.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer? _countdownTimer;
  bool _isRunning = false;
  PlanExercise? _activeExercise;
  String _todayDayName="";
  bool _showUnavailableExercises = false;

  @override
  void initState() {
    super.initState();
    _todayDayName = _getDayName(DateTime.now());
  }

  /// Get day name from DateTime (e.g., "Monday", "Sunday")
  String _getDayName(DateTime date) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[date.weekday - 1];
  }

  /// Get the next Sunday from a given date
  DateTime _getNextSunday(DateTime date) {
    final dayOfWeek = date.weekday;
    final daysUntilSunday = (7 - dayOfWeek) % 7;
    if (daysUntilSunday == 0 && date.hour == 0 && date.minute == 0 && date.second == 0) {
      // If today is Sunday at midnight, next Sunday is next week
      return date.add(const Duration(days: 7));
    }
    return date.add(Duration(days: daysUntilSunday == 0 ? 7 : daysUntilSunday));
  }



/// Get the last Sunday from a given date (stripping time for accurate comparison)
  DateTime _getLastSunday(DateTime date) {
    final dayOfWeek = date.weekday;
    final daysSinceSunday = (dayOfWeek) % 7;
    
    // Calculate the raw date
    final sundayDate = date.subtract(Duration(days: daysSinceSunday));
    
    // RETURN NEW DATE WITH NO TIME (00:00:00)
    return DateTime(sundayDate.year, sundayDate.month, sundayDate.day);
  }


  /// Check if we should show weight prompt for this plan
  bool _shouldShowWeightPrompt(Plan plan) {
    // 1. Only show if enabled at creation
    if (!plan.currentWeightEnabledAtCreation) return false;

    // 2. Get the 'Sunday' for the current week (at 00:00:00)
    final currentSunday = _getLastSunday(DateTime.now());
    
    // 3. Get the date we last handled a prompt (at 00:00:00)
    final lastHandledSunday = plan.lastWeightPromptSunday;

    // 4. Logic:
    // If we have NEVER handled a Sunday, check if we've passed the creation date
    if (lastHandledSunday == null) {
      final firstAllowedSunday = _getNextSunday(plan.createdAt);
      // If today is (or is after) the first allowed Sunday, show prompt
      return currentSunday.isAtSameMomentAs(firstAllowedSunday) || currentSunday.isAfter(firstAllowedSunday);
    }

    // 5. If we HAVE handled a Sunday before:
    // Only show if the current Sunday is AFTER the last handled one.
    return currentSunday.isAfter(lastHandledSunday);
  }


  void _startOrPauseExercise(PlanExercise exercise) {
    // Check if exercise is available today
    final todayDay = _todayDayName;
    if (!exercise.days.contains(todayDay)) {
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

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final plan = PlanController.instance.currentPlan.value;
      if (plan == null) return;
      if (_activeExercise == null) return;

      final String todayDay = _todayDayName;
      final currentWeekKey = _getCurrentWeekKey();
      
      // Check if we need to reset for a new week
      if (_activeExercise!.lastResetDate == null || 
          !_isSameWeek(_activeExercise!.lastResetDate!, DateTime.now())) {
        // New week - reset all per-day durations
        _activeExercise!.perDayRemainingDuration.clear();
        _activeExercise!.lastResetDate = DateTime.now();
      }
      
      if (!_activeExercise!.perDayRemainingDuration.containsKey(todayDay)) {
        _activeExercise!.perDayRemainingDuration[todayDay] = _activeExercise!.duration;
      }

      final remaining = _activeExercise!.perDayRemainingDuration[todayDay]!;
      if (remaining.inSeconds <= 0) {
        _countdownTimer?.cancel();
        setState(() => _isRunning = false);
        return;
      }

      _activeExercise!.perDayRemainingDuration[todayDay] =
          Duration(seconds: remaining.inSeconds - 1);
      PlanController.instance.notifyCurrentPlanChanged();
    });
  }

  void _resetActiveExercise() {
    if (_activeExercise == null) return;
    final todayDay = _todayDayName;
    
    // Check if we need to reset for a new week
    if (_activeExercise!.lastResetDate == null || 
        !_isSameWeek(_activeExercise!.lastResetDate!, DateTime.now())) {
      // New week - reset all per-day durations
      _activeExercise!.perDayRemainingDuration.clear();
      _activeExercise!.lastResetDate = DateTime.now();
    }
    
    setState(() {
      _activeExercise!.perDayRemainingDuration[todayDay] = _activeExercise!.duration;
      _isRunning = false;
    });
    _countdownTimer?.cancel();
    PlanController.instance.notifyCurrentPlanChanged();
  }

  /// Check if two dates are in the same week (Sunday to Saturday)
  bool _isSameWeek(DateTime date1, DateTime date2) {
    final sunday1 = _getLastSunday(date1);
    final sunday2 = _getLastSunday(date2);
    return sunday1.isAtSameMomentAs(sunday2);
  }

  /// Get a unique key for the current week
  String _getCurrentWeekKey() {
    final sunday = _getLastSunday(DateTime.now());
    return '${sunday.year}-${sunday.month.toString().padLeft(2, '0')}-${sunday.day.toString().padLeft(2, '0')}';
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
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: ValueListenableBuilder<Plan?>(
              valueListenable: PlanController.instance.currentPlan,
              builder: (context, plan, _) {
                // Handle alerts
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (plan != null) {
                    // Weight prompt check - only show if we should AND haven't already prompted today's Sunday
                    if (_shouldShowWeightPrompt(plan)) {
                      final currentSunday = _getLastSunday(DateTime.now());
                      final lastPromptSunday = plan.lastWeightPromptSunday;
                      // Only show if this is a new Sunday (not already prompted this Sunday)
                      if (lastPromptSunday == null || !currentSunday.isAtSameMomentAs(lastPromptSunday)) {
                        if (mounted) _promptWeight(plan);
                      }
                    }

                    // Goal weight reached check
                    if (!plan.goalWeightReachedAlertShown &&
                        plan.currentWeight != null &&
                        plan.goalWeight != null) {
                      final goalReached = plan.goal == 'Gain weight'
                          ? plan.currentWeight! >= plan.goalWeight!
                          : plan.goal == 'Lose weight'
                              ? plan.currentWeight! <= plan.goalWeight!
                              : false;
                      if (goalReached) {
                        plan.goalWeightReachedAlertShown = true;
                        if (mounted) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('🎉 Congratulations!'),
                              content: const Text(
                                'You have reached your goal weight!',
                              ),
                              actions: [
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ColorConstants.primaryColor,
                                  ),
                                  child: const Text('Great!'),
                                )
                              ],
                            ),
                          );
                        }
                      }
                    }

                    // Deadline passed check
                    if (!plan.deadlinePassedAlertShown &&
                        plan.deadline != null &&
                        DateTime.now().isAfter(plan.deadline!)) {
                      final goalReached = plan.currentWeight != null &&
                          plan.goalWeight != null &&
                          (plan.goal == 'Gain weight'
                              ? plan.currentWeight! >= plan.goalWeight!
                              : plan.goal == 'Lose weight'
                                  ? plan.currentWeight! <= plan.goalWeight!
                                  : false);

                      if (!goalReached) {
                        plan.deadlinePassedAlertShown = true;
                        if (mounted) _showDeadlineAlert(plan);
                      }
                    }
                  }
                });

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 16),
                      _buildPlanSummaryCard(plan!),
                      const SizedBox(height: 16),
                      if (plan.weightLog.isNotEmpty) ...[
                        _buildWeightProgressSection(plan),
                        const SizedBox(height: 24),
                      ],
                      _buildGoalProgressSection(plan),
                      const SizedBox(height: 24),
                      _buildExerciseStatisticsSection(plan),
                      const SizedBox(height: 16),
                      _buildTrackerCard(),
                      const SizedBox(height: 16),
                      if (plan != null && plan.currentWeight != null) _buildWeeklyCheckInCard(plan),
                      const SizedBox(height: 16),
                      if (plan != null)
                        if (plan.exercises.isEmpty)
                          _buildNoExercisesCard()
                        else
                          ..._buildExercisesSections(plan),
                      const SizedBox(height: 16),
                      if (plan != null && plan.exercises.isNotEmpty)
                        _buildScheduleReminderRow(plan),
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
            color: Colors.black.withValues(alpha: 0.06),
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
              color: ColorConstants.primaryColor.withValues(alpha: 0.08),
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
            color: Colors.black.withValues(alpha: 0.06),
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
            color: Colors.black.withValues(alpha: 0.06),
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


  Widget _buildWeightProgressSection(Plan plan) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weight Progress',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: _buildWeightChart(plan),
          ),
          const SizedBox(height: 16),
          _buildWeightStats(plan),
        ],
      ),
    );
  }

  Widget _buildWeightChart(Plan plan) {
    if (plan.weightLog.isEmpty) {
      return const Center(child: Text('No weight data yet'));
    }

    // Sort by date
    final sortedLog = List<WeightEntry>.from(plan.weightLog)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Create chart data
    final spots = <FlSpot>[];
    for (int i = 0; i < sortedLog.length; i++) {
      spots.add(FlSpot(i.toDouble(), sortedLog[i].weight));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 5,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withOpacity(0.3),
            strokeWidth: 1,
          ),
          getDrawingVerticalLine: (value) => FlLine(
            color: Colors.grey.withOpacity(0.3),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: (sortedLog.length / 5).ceilToDouble(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= sortedLog.length) return const SizedBox();
                final date = sortedLog[index].date;
                return Text(
                  '${date.month}/${date.day}',
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 5,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}',
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: true),
        minX: 0,
        maxX: (sortedLog.length - 1).toDouble(),
        minY: (sortedLog.map((e) => e.weight).reduce((a, b) => a < b ? a : b) - 5),
        maxY: (sortedLog.map((e) => e.weight).reduce((a, b) => a > b ? a : b) + 5),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: ColorConstants.primaryColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: ColorConstants.primaryColor,
                  strokeColor: Colors.white,
                  strokeWidth: 2,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: ColorConstants.primaryColor.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightStats(Plan plan) {
    final sortedLog = List<WeightEntry>.from(plan.weightLog)
      ..sort((a, b) => a.date.compareTo(b.date));

    final firstWeight = sortedLog.first.weight;
    final lastWeight = sortedLog.last.weight;
    final difference = lastWeight - firstWeight;
    final isProgress = plan.goal == 'Lose weight' ? difference < 0 : difference > 0;

    return Column(
      children: [
        Divider(height: 20, color: Colors.grey.withOpacity(0.3)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatCard('Starting Weight', '${firstWeight} kg'),
            _buildStatCard('Current Weight', '${lastWeight} kg'),
            _buildStatCard(
              'Progress',
              '${difference.abs().toStringAsFixed(1)} kg',
              color: isProgress ? Colors.green : Colors.red,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, {Color color = Colors.black87}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalProgressSection(Plan plan) {
    double progress = 0;
    String progressText = '';

    if (plan.currentWeight != null && plan.goalWeight != null) {
      if (plan.goal == 'Lose weight') {
        final total = plan.currentWeight! - plan.goalWeight!;
        final current =
            plan.currentWeight! - (plan.weightLog.isEmpty ? plan.currentWeight! : plan.weightLog.last.weight);
        progress = current / total;
        progressText =
        '${current.toStringAsFixed(1)} kg of ${total.toStringAsFixed(1)} kg';
      } else if (plan.goal == 'Gain weight') {
        final total = plan.goalWeight! - plan.currentWeight!;
        final current =
            (plan.weightLog.isEmpty ? plan.currentWeight! : plan.weightLog.last.weight) - plan.currentWeight!;
        progress = current / total;
        progressText =
        '${current.toStringAsFixed(1)} kg of ${total.toStringAsFixed(1)} kg';
      }
    }

    progress = progress.clamp(0.0, 1.0);

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Goal Progress',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          if (plan.currentWeight != null && plan.goalWeight != null) ...[
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${plan.goal}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      progressText,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ColorConstants.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: Colors.grey.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress >= 1.0 ? Colors.green : ColorConstants.primaryColor,
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildExerciseStatisticsSection(Plan plan) {
    if (plan.exercises.isEmpty) {
      return const SizedBox();
    }

    // Calculate exercise durations
    final exerciseDurations = <String, int>{};
    for (final exercise in plan.exercises) {
      exerciseDurations[exercise.name] = exercise.duration.inMinutes;
    }

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Exercise Breakdown',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: _buildExercisePieChart(exerciseDurations),
          ),
          const SizedBox(height: 16),
          _buildExerciseList(plan),
        ],
      ),
    );
  }

  Widget _buildExercisePieChart(Map<String, int> durations) {
    final List<PieChartSectionData> sections = [];
    final colors = [
      ColorConstants.primaryColor,
      Colors.orange,
      Colors.green,
      Colors.red,
      Colors.purple,
    ];

    int colorIndex = 0;
    durations.forEach((name, duration) {
      sections.add(
        PieChartSectionData(
          color: colors[colorIndex % colors.length],
          value: duration.toDouble(),
          title: '${(duration / durations.values.reduce((a, b) => a + b) * 100).toStringAsFixed(0)}%',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      colorIndex++;
    });

    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 40,
      ),
    );
  }

  Widget _buildExerciseList(Plan plan) {
    return Column(
      children: [
        Divider(height: 20, color: Colors.grey.withOpacity(0.3)),
        ...plan.exercises.map((exercise) {
          final totalMinutes = exercise.duration.inMinutes;
          final days = exercise.days.join(', ');
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: ColorConstants.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$totalMinutes min • $days',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$totalMinutes min',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: ColorConstants.primaryColor,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
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
    final todayDay = _todayDayName;
    final remaining = _activeExercise != null
        ? _activeExercise!.perDayRemainingDuration[todayDay] ?? Duration.zero
        : Duration.zero;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
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
              color: ColorConstants.primaryColor.withValues(alpha: 0.08),
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
            color: Colors.black.withValues(alpha: 0.06),
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
            child: const Text('Update', style: TextStyle(fontWeight: FontWeight.w600)),
          )
        ],
      ),
    );
  }

  Future<void> _promptWeight(Plan plan) async {
    final controller = TextEditingController();
    
    // Pre-fill with current weight if available
    if (plan.currentWeight != null) {
      controller.text = plan.currentWeight.toString();
    }

    final value = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Weekly Check-in'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: 'Enter your weight (kg)',
              suffixText: 'kg',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text('Cancel', style: TextStyle(color: ColorConstants.primaryColor))
            ),
            ElevatedButton(
              onPressed: () {
                final text = controller.text.trim();
                final parsed = double.tryParse(text);
                Navigator.pop(context, parsed);
              },
              style: ElevatedButton.styleFrom(backgroundColor: ColorConstants.primaryColor),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (value == null) return;

    // Update the plan
    plan.weightLog.add(WeightEntry(date: DateTime.now(), weight: value));
    plan.currentWeight = value;

    // CRITICAL: Mark this week's Sunday as "Handled" so the popup stops appearing
    plan.lastWeightPromptSunday = _getLastSunday(DateTime.now());

    PlanController.instance.notifyCurrentPlanChanged();
  }

  void _showDeadlineAlert(Plan plan) {
    showDialog(
      context: context,
      builder: (context) {

        DateTime? newDeadline;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('GO ON!! Don\'t give up'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Your deadline has passed, but you haven\'t reached your goal yet!'),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {

                      final now = DateTime.now();         
                      final today = DateTime(now.year, now.month, now.day);

                      final picked = await showDatePicker(
                        context: context,
                        initialDate: today.add(const Duration(days: 7)),
                        firstDate: today,
                        lastDate: today.add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() {
                          newDeadline = picked;
                        });
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.black54),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              newDeadline == null
                                  ? 'Select new deadline'
                                  : '${newDeadline!.year}-${newDeadline!.month.toString().padLeft(2, '0')}-${newDeadline!.day.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Later'),
                ),
                ElevatedButton(
                  onPressed: newDeadline != null
                      ? () {
                          plan.deadline = newDeadline;
                          PlanController.instance.notifyCurrentPlanChanged();
                          Navigator.pop(context);
                        }
                      : null,

                  child: const Text('Update', style: TextStyle(color: ColorConstants.white)),
                ),
              ],
            );
          },
        );
      },
    );
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

    final todayDay = _todayDayName;
    final isAvailableToday = a.days.contains(todayDay);
    final todayRemaining = a.perDayRemainingDuration[todayDay] ?? a.duration;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
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
              color: isAvailableToday
                  ? ColorConstants.primaryColor.withValues(alpha: 0.08)
                  : Colors.grey.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.fitness_center,
              color: isAvailableToday ? ColorConstants.primaryColor : Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  '${fmt(todayRemaining)} / ${fmt(a.duration)}${a.days.isEmpty ? '' : '  •  ${a.days.join(', ')}'}',
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 4),
                if (!isAvailableToday)
                  Text(
                    'On: ${a.days.join(", ")}',
                    style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton(
                    onPressed: isAvailableToday ? () => _startOrPauseExercise(a) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAvailableToday ? ColorConstants.primaryColor : Colors.grey,
                      foregroundColor: ColorConstants.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      _activeExercise == a && _isRunning
                          ? 'Pause Workout'
                          : isAvailableToday
                              ? 'Start Workout'
                              : 'Not Available',
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoExercisesTodayCard() {
    return
      Container(

        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Column(
          children: [
            InkWell(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const SizedBox(width: 12),

                    Text(
                        'No exercises scheduled for today.', style: TextStyle(color: Colors.black54)
                    ),

                  ],
                ),
              ),
            ),
          ],
        ),

      );
  }


  /// Build both today's exercises and a collapsible section for unavailable exercises
  List<Widget> _buildExercisesSections(Plan plan) {
    final todayDay = _todayDayName;
    final todayExercises = plan.exercises.where((e) => e.days.contains(todayDay)).toList();
    final unavailableExercises = plan.exercises.where((e) => !e.days.contains(todayDay)).toList();

    final widgets = <Widget>[
      // Today's exercises
      if (todayExercises.isNotEmpty)
        ...todayExercises.map(_buildExerciseCard),
      if (todayExercises.isEmpty)
        _buildNoExercisesTodayCard(),

      // Unavailable exercises section
      if (unavailableExercises.isNotEmpty) ...[
        const SizedBox(height: 8),
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () => setState(() => _showUnavailableExercises = !_showUnavailableExercises),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        _showUnavailableExercises ? Icons.expand_less : Icons.expand_more,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Other Exercises (${unavailableExercises.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_showUnavailableExercises)
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  child: Column(
                    children: [
                      ...unavailableExercises.map((exercise) {
                        String fmt(Duration d) {
                          final m = d.inMinutes;
                          final s = d.inSeconds.remainder(60);
                          return '${m}m ${s}s';
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exercise.name,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${fmt(exercise.duration)} • ${exercise.days.join(", ")}',
                                style: const TextStyle(color: Colors.black54, fontSize: 12),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    ];
    return widgets;
  }

  Widget _buildScheduleReminderRow(Plan plan) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
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
              color: ColorConstants.primaryColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.schedule, color: ColorConstants.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Full Schedule', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 2),
                Text(
                  'View all exercises & plan details',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showFullSchedulePopup(plan),
            icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  void _showFullSchedulePopup(Plan plan) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Weekly Schedule',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${plan.name} - Plan Details',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        if (plan.goal != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Icon(Icons.tab_rounded, size: 18, color: Colors.black54),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text('Goal: ${plan.goal}',
                                      style: const TextStyle(fontSize: 14)),
                                ),
                              ],
                            ),
                          ),
                        if (plan.deadline != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 18, color: Colors.black54),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Deadline: ${_formatDate(plan.deadline!)}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (plan.currentWeight != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.scale, size: 18, color: Colors.black54),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Current Weight: ${plan.currentWeight} kg',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (plan.goalWeight != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              children: [
                                const Icon(Icons.flag, size: 18, color: Colors.black54),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Goal Weight: ${plan.goalWeight} kg',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const Divider(),
                        const SizedBox(height: 12),
                        const Text(
                          'All Exercises',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        ...plan.exercises.map((exercise) {
                          String fmt(Duration d) {
                            final m = d.inMinutes;
                            final s = d.inSeconds.remainder(60);
                            return '${m}m ${s}s';
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    exercise.name,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.timer, size: 14, color: Colors.black54),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          fmt(exercise.duration),
                                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today, size: 14, color: Colors.black54),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          exercise.days.join(', '),
                                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
