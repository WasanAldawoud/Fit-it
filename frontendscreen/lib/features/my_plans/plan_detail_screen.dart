import 'dart:async';
import 'package:flutter/material.dart';

import '../../app_styles/color_constants.dart';
import '../common/plan_controller.dart';
import '../common/app_nav_bar.dart';
import '../common/main_shell.dart';
import '../plan_creation/presentation/screens/create_plan_screen.dart';
import '../plan_creation/presentation/widgets/duration_picker.dart';
import '../plan_creation/presentation/widgets/day_selection_dialog.dart';

class PlanDetailScreen extends StatefulWidget {
  final Plan plan;

  const PlanDetailScreen({super.key, required this.plan});

  @override
  State<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends State<PlanDetailScreen> {
  String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  String _formatDays(List<String> days) {
    return days.join(', ');
  }

  Future<void> _editExercise(PlanExercise exercise, int index) async {
    // First, select duration
    final newDuration = await showHMSDurationPicker(context, initialDuration: exercise.duration);
    if (newDuration == null) return;

    // Then, select days
    final newDays = await showDialog<Set<String>>(
      context: context,
      builder: (context) => DaySelectionDialog(initialSelectedDays: exercise.days.toSet()),
    );
    if (newDays == null || newDays.isEmpty) return;

    // Update the exercise
    setState(() {
      exercise.duration = newDuration;
      exercise.days = newDays.toList();
      // Reset per-day tracking
      exercise.perDayRemainingDuration.clear();
      for (final day in exercise.days) {
        exercise.perDayRemainingDuration[day] = exercise.duration;
      }
    });
    PlanController.instance.notifyCurrentPlanChanged();
  }

  void _deleteExercise(int index) async {
    final exercise = widget.plan.exercises[index];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Exercise'),
          content: Text('Are you sure you want to delete "${exercise.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() {
        widget.plan.exercises.removeAt(index);
      });
      PlanController.instance.notifyCurrentPlanChanged();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${exercise.name}" deleted')),
      );
    }
  }

  Future<void> _modifyPlan() async {
    // Navigate to CreatePlanScreen with existing plan for editing
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePlanScreen(
          existingPlan: widget.plan,
          source: 'plan_details',
        ),
      ),
    );

    // After returning from edit, refresh the UI
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.primaryColor,
      appBar: AppBar(
        backgroundColor: ColorConstants.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Icon(Icons.fitness_center, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.plan.name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.white),
            onPressed: _modifyPlan,
            tooltip: 'Edit plan',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Plan Info Header
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [ColorConstants.primaryColor, ColorConstants.primaryColor.withOpacity(0.8)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: ColorConstants.accentColor,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Text(
                            widget.plan.goal ?? 'No Goal',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (widget.plan.deadline != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              'Deadline: ${_formatDate(widget.plan.deadline!)}',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.list_alt, color: Colors.white70, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Exercises: ${widget.plan.exercises.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Divider
              Container(
                height: 2,
                color: Colors.white.withOpacity(0.3),
              ),

              // Exercises List
              Container(
                color: Colors.grey[50],
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.sports_gymnastics, color: ColorConstants.primaryColor, size: 24),
                          const SizedBox(width: 8),
                          const Text(
                            'Exercises',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (widget.plan.exercises.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 60),
                          alignment: Alignment.center,
                          child: Column(
                            children: [
                              Icon(Icons.fitness_center, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No exercises yet',
                                style: TextStyle(color: Colors.grey[500], fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: widget.plan.exercises.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final exercise = widget.plan.exercises[index];
                            return Card(
                              elevation: 4,
                              shadowColor: ColorConstants.primaryColor.withOpacity(0.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                leading: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: ColorConstants.accentColor.withOpacity(0.2),
                                  child: Icon(
                                    Icons.fitness_center,
                                    color: ColorConstants.accentColor,
                                    size: 24,
                                  ),
                                ),
                                title: Text(
                                  exercise.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.schedule, size: 16, color: ColorConstants.primaryColor),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${exercise.duration.inMinutes} min',
                                          style: const TextStyle(color: Colors.black54, fontSize: 14),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today, size: 16, color: ColorConstants.primaryColor),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            _formatDays(exercise.days),
                                            style: const TextStyle(color: Colors.black54, fontSize: 14),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit, color: ColorConstants.primaryColor, size: 22),
                                      onPressed: () => _editExercise(exercise, index),
                                      tooltip: 'Edit exercise',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red, size: 22),
                                      onPressed: () => _deleteExercise(index),
                                      tooltip: 'Delete exercise',
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppNavBar(
        currentIndex: 1,
        onTap: (i) => Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainShell()),
          (route) => false,
        ),
      ),
    );
  }
}